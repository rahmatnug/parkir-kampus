package usecase

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/redis"
	redisv9 "github.com/redis/go-redis/v9"
)

type parkingUsecase struct {
	repo     domain.ParkingRepository
	userRepo domain.UserRepository
	wsHub    domain.WSHub
}

func NewParkingUsecase(repo domain.ParkingRepository, userRepo domain.UserRepository, wsHub domain.WSHub) domain.ParkingUsecase {
	return &parkingUsecase{repo, userRepo, wsHub}
}

func (u *parkingUsecase) getWaitlistPriority(roleName string) int64 {
	switch roleName {
	case "dosen":
		return 1
	case "staff":
		return 2
	case "mahasiswa":
		return 3
	case "tamu":
		return 4
	default:
		return 5
	}
}

func (u *parkingUsecase) TapIn(userID uint, kendaraanID uint, zonaID uint) (*domain.Transaksi, string, error) {
	// 1. Check if slots are full
	count, err := u.repo.CountAvailableSlots(zonaID)
	if err != nil {
		return nil, "", err
	}

	if count == 0 {
		// Full, enter waitlist
		user, err := u.userRepo.FindByID(userID)
		if err != nil {
			return nil, "", err
		}

		priority := u.getWaitlistPriority(user.Role.NamaRole)
		timestamp := time.Now().UnixMilli()
		score := float64(priority*1000000000000 + timestamp)

		key := fmt.Sprintf("waitlist:zona:%d", zonaID)
		member := fmt.Sprintf("%d:%d", userID, kendaraanID)

		err = redis.RedisClient.ZAdd(context.Background(), key, redisv9.Z{
			Score:  score,
			Member: member,
		}).Err()

		if err != nil {
			return nil, "", err
		}

		return nil, "waiting", nil
	}

	// 2. Try to lock a slot
	slot, err := u.repo.GetAvailableSlotWithLock(zonaID)
	if err != nil {
		if err.Error() == "record not found" {
			// All available slots are locked by other requests
			return nil, "conflict", nil
		}
		return nil, "", err
	}

	// 3. Create transaction
	tx := &domain.Transaksi{
		UserID:      userID,
		KendaraanID: kendaraanID,
		SlotID:      slot.IDSlot,
		WaktuMasuk:  time.Now(),
		Status:      "parkir",
	}

	if err := u.repo.CreateTransaksi(tx); err != nil {
		return nil, "", err
	}

	// 4. Update slot status to occupied
	if err := u.repo.UpdateSlotStatus(slot.IDSlot, "occupied"); err != nil {
		return nil, "", err
	}

	return tx, "success", nil
}

func (u *parkingUsecase) TapOut(userID uint) (*domain.Transaksi, error) {
	tx, err := u.repo.GetActiveTransaksi(userID)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	tx.WaktuKeluar = &now
	tx.Status = "selesai"

	if err := u.repo.UpdateTransaksi(tx); err != nil {
		return nil, err
	}

	// Release slot
	if err := u.repo.UpdateSlotStatus(tx.SlotID, "available"); err != nil {
		return nil, err
	}

	// Get slot info to know the zone for waitlist assignment
	slot, err := u.repo.GetSlotByID(tx.SlotID)
	if err == nil {
		// Trigger auto-assign in background
		go u.AssignSlotFromWaitlist(slot.ZonaID)
	}

	return tx, nil
}

func (u *parkingUsecase) AssignSlotFromWaitlist(zonaID uint) error {
	ctx := context.Background()
	key := fmt.Sprintf("waitlist:zona:%d", zonaID)

	// Pop highest priority (lowest score) user
	res, err := redis.RedisClient.ZPopMin(ctx, key, 1).Result()
	if err != nil || len(res) == 0 {
		return nil // No one in waitlist
	}

	member := res[0].Member.(string)
	var userID, kendaraanID uint
	_, err = fmt.Sscanf(member, "%d:%d", &userID, &kendaraanID)
	if err != nil {
		return err
	}

	// Try to get a slot
	slot, err := u.repo.GetAvailableSlotWithLock(zonaID)
	if err != nil {
		// If fails, put them back? Or just ignore (next tap-out will try again)
		// Better to put back if error is not "not found"
		if err.Error() != "record not found" {
			redis.RedisClient.ZAdd(ctx, key, res[0]).Err()
		}
		return err
	}

	// Create transaction for waitlist user
	tx := &domain.Transaksi{
		UserID:      userID,
		KendaraanID: kendaraanID,
		SlotID:      slot.IDSlot,
		WaktuMasuk:  time.Now(),
		Status:      "parkir",
	}

	if err := u.repo.CreateTransaksi(tx); err != nil {
		return err
	}

	if err := u.repo.UpdateSlotStatus(slot.IDSlot, "occupied"); err != nil {
		return err
	}

	log.Printf("Successfully assigned waitlist user %d to slot %d in zone %d", userID, slot.IDSlot, zonaID)
	return nil
}

// ProcessParkingEntry is the unified QR-scan entry point.
// Flow: identity → blacklist → active-session → zone → vehicle → atomic booking.
func (u *parkingUsecase) ProcessParkingEntry(userID uint, qrCode string) (*domain.ParkingEntryResult, error) {
	// 1. Blacklist check
	totalPoin, err := u.repo.GetTotalPenaltyPoints(userID)
	if err != nil {
		return nil, fmt.Errorf("gagal cek status penalti: %w", err)
	}
	if totalPoin >= 100 {
		return nil, errors.New("BLACKLISTED: akses parkir ditolak karena akumulasi poin penalti telah mencapai batas")
	}

	// 2. Check for existing active parking session
	activeTx, _ := u.repo.GetActiveTransaksi(userID)
	if activeTx != nil {
		return nil, errors.New("ALREADY_PARKED: Anda masih memiliki sesi parkir aktif. Scan QR untuk keluar terlebih dahulu")
	}

	// 3. Normalize QR code to zone name
	// QR formats supported: "ZONE-A", "Zone A", "zone a", "A"
	zoneName := normalizeZoneCode(qrCode)

	zone, err := u.repo.GetZoneByCode(zoneName)
	if err != nil {
		return nil, fmt.Errorf("INVALID_ZONE: zona '%s' tidak ditemukan dalam sistem", qrCode)
	}

	if zone.Status != "active" {
		return nil, fmt.Errorf("ZONE_INACTIVE: zona '%s' sedang tidak aktif", zone.NamaZona)
	}

	// 4. Get user's registered vehicle
	kendaraan, err := u.repo.GetUserKendaraan(userID)
	if err != nil {
		return nil, errors.New("NO_VEHICLE: Anda belum memiliki kendaraan terdaftar. Silakan daftarkan kendaraan terlebih dahulu")
	}

	// 5. Atomic slot booking
	transaksi, slot, err := u.repo.BookSlotAndCreateTransaction(userID, kendaraan.IDKendaraan, zone.IDZona)
	if err != nil {
		// If record not found, zone is full
		if err.Error() == "record not found" {
			return nil, fmt.Errorf("ZONE_FULL: zona '%s' sudah penuh, silakan coba zona lain", zone.NamaZona)
		}
		return nil, fmt.Errorf("gagal booking slot: %w", err)
	}

	go u.broadcastSlotUpdate(zone.IDZona)

	return &domain.ParkingEntryResult{
		TransaksiID: transaksi.IDTransaksi,
		NomorSlot:   slot.NomorSlot,
		NamaZona:    zone.NamaZona,
		Status:      "parkir",
	}, nil
}

// normalizeZoneCode converts various QR code formats to a zone name
// that can be matched against the database.
func normalizeZoneCode(code string) string {
	code = strings.TrimSpace(code)

	// Handle "ZONE-A" / "ZONE-B" format
	if strings.HasPrefix(strings.ToUpper(code), "ZONE-") {
		letter := strings.TrimPrefix(strings.ToUpper(code), "ZONE-")
		return "Zone " + letter
	}

	// Handle "PK-ZONE-A" format
	if strings.HasPrefix(strings.ToUpper(code), "PK-ZONE-") {
		letter := strings.TrimPrefix(strings.ToUpper(code), "PK-ZONE-")
		return "Zone " + letter
	}

	// Handle single letter "A", "B", "C"
	if len(code) == 1 {
		return "Zone " + strings.ToUpper(code)
	}

	// Otherwise return as-is (e.g., "Zone A" already)
	return code
}

// ProcessParkingExit handles the logic for a user exiting the parking.
func (u *parkingUsecase) ProcessParkingExit(userID uint) (*domain.Transaksi, error) {
	// Let the repository handle the transaction to ensure atomicity
	tx, err := u.repo.ReleaseSlotAndUpdateTransaction(userID)
	if err != nil {
		if err.Error() == "record not found" {
			return nil, errors.New("NO_ACTIVE_SESSION: Tidak ada sesi parkir yang aktif")
		}
		return nil, fmt.Errorf("gagal memproses exit: %w", err)
	}

	// Trigger auto-assign in background for the freed slot's zone
	// We need to fetch the slot to know its zone ID
	slot, err := u.repo.GetSlotByID(tx.SlotID)
	if err == nil {
		go u.AssignSlotFromWaitlist(slot.ZonaID)
		u.broadcastSlotUpdate(slot.ZonaID)
	}

	return tx, nil
}

func (u *parkingUsecase) broadcastSlotUpdate(zonaID uint) {
	if u.wsHub == nil {
		return
	}
	
	count, err := u.repo.CountAvailableSlots(zonaID)
	if err != nil {
		return
	}

	zone, err := u.repo.GetZoneByID(zonaID)
	if err != nil {
		return
	}

	u.wsHub.NotifySlotUpdate(domain.SlotUpdateData{
		IDZona:    zone.IDZona,
		NamaZona:  zone.NamaZona,
		Tersedia:  int(count),
		Kapasitas: zone.Kapasitas,
	})
}

