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
	case "tamu":
		return 1
	case "dosen", "staff":
		return 2
	case "mahasiswa":
		return 3
	default:
		return 4
	}
}

func (u *parkingUsecase) TapIn(userID uint, kendaraanID uint, zonaID uint) (*domain.Transaksi, string, error) {
	// 0. Validate Vehicle Type Match
	kendaraan, err := u.repo.GetUserKendaraan(userID)
	if err != nil {
		return nil, "", errors.New("NO_VEHICLE: Anda belum memiliki kendaraan terdaftar. Silakan daftarkan kendaraan terlebih dahulu")
	}

	zone, err := u.repo.GetZoneByID(zonaID)
	if err != nil {
		return nil, "", errors.New("INVALID_ZONE: Zona tidak ditemukan")
	}

	// 1. Check if capacities are full
	motor, mobil, err := u.repo.GetOccupancyByVehicleType(zonaID)
	if err != nil {
		return nil, "", err
	}

	user, err := u.userRepo.FindByID(userID)
	if err != nil {
		return nil, "", err
	}

	jenisStr := strings.ToLower(strings.TrimSpace(kendaraan.JenisKendaraan))
	sisaSlot := 0

	if jenisStr == "motor" {
		sisaSlot = zone.KapasitasMotor - motor
	} else if jenisStr == "mobil" {
		sisaSlot = zone.KapasitasMobil - mobil
	}

	isFull := sisaSlot <= 0
	if sisaSlot < 2 && user.Role.Prioritas >= 3 {
		isFull = true
	}

	if isFull {
		// Full, enter waitlist

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
		Status:      "parkir",
	}
	tx.WaktuMasuk = time.Now()

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
	
	if now.Sub(tx.WaktuMasuk).Hours() > 24 {
		p := &domain.Penalti{
			UserID:           userID,
			JenisPelanggaran: "Menginap / Overtime",
			PoinPenalti:      50,
			Tanggal:          now,
		}
		u.repo.CreatePenalti(p)
	}

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
		Status:      "parkir",
	}
	tx.WaktuMasuk = time.Now()

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

	user, err := u.userRepo.FindByID(userID)
	if err == nil && user.Status == "blocked" {
		return nil, errors.New("BLACKLISTED: Akses Parkir Diblokir")
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

	// 4b. Anti-Mismatch Validation and Capacity Check
	motor, mobil, err := u.repo.GetOccupancyByVehicleType(zone.IDZona)
	if err != nil {
		return nil, err
	}

	jenisStr := strings.ToLower(strings.TrimSpace(kendaraan.JenisKendaraan))
	sisaSlot := 0
	if jenisStr == "motor" {
		sisaSlot = zone.KapasitasMotor - motor
	} else if jenisStr == "mobil" {
		sisaSlot = zone.KapasitasMobil - mobil
	}

	if sisaSlot <= 0 {
		return nil, fmt.Errorf("ZONE_FULL: Kapasitas %s Penuh", strings.Title(jenisStr))
	}

	if sisaSlot < 2 && user.Role.Prioritas >= 3 {
		return nil, fmt.Errorf("ZONE_FULL: Sisa slot terbatas (prioritas rendah ditolak). Silakan cari zona lain")
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
		XCoord:      slot.XCoord,
		YCoord:      slot.YCoord,
	}, nil
}

// normalizeZoneCode converts various QR code formats to a zone name
// that can be matched against the database.
func normalizeZoneCode(code string) string {
	code = strings.TrimSpace(code)

	// Direct match for absolute standard "PK-ZONE-{nama_zona}"
	if strings.HasPrefix(strings.ToUpper(code), "PK-ZONE-") {
		return strings.TrimSpace(code[8:])
	}

	// Handle trailing "-QR" payload from scanner
	if strings.HasSuffix(strings.ToUpper(code), "-QR") {
		code = code[:len(code)-3]
	}

	// Legacy handling "ZONE-A" or "ZONA-A" -> "Zona A"
	upperCode := strings.ToUpper(code)
	if strings.HasPrefix(upperCode, "ZONE-") || strings.HasPrefix(upperCode, "ZONA-") {
		letter := code[5:]
		return "Zona " + strings.ToUpper(letter)
	}

	// Handle single letter "A", "B", "C" -> "Zona A"
	if len(code) == 1 {
		return "Zona " + strings.ToUpper(code)
	}

	// Otherwise return as-is
	return code
}

func (u *parkingUsecase) ProcessParkingExit(userID uint) (*domain.Transaksi, error) {
	// Check overtime before closing transaction
	activeTx, err := u.repo.GetActiveTransaksi(userID)
	if err == nil && activeTx != nil {
		if time.Since(activeTx.WaktuMasuk).Hours() > 24 {
			p := &domain.Penalti{
				UserID:           userID,
				JenisPelanggaran: "Menginap / Overtime",
				PoinPenalti:      50,
				Tanggal:          time.Now(),
			}
			u.repo.CreatePenalti(p)
		}
	}

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
	
	zone, err := u.repo.GetZoneByID(zonaID)
	if err != nil {
		return
	}
	
	motor, mobil, err := u.repo.GetOccupancyByVehicleType(zonaID)
	if err != nil {
		return
	}

	u.wsHub.NotifySlotUpdate(domain.SlotUpdateData{
		IDZona:         zone.IDZona,
		NamaZona:       zone.NamaZona,
		KapasitasMotor: zone.KapasitasMotor,
		KapasitasMobil: zone.KapasitasMobil,
		TerpakaiMotor:  motor,
		TerpakaiMobil:  mobil,
	})
}

func (u *parkingUsecase) GetCurrentParking(userID uint) (*domain.ParkingEntryResult, error) {
	tx, err := u.repo.GetActiveTransaksi(userID)
	if err != nil {
		if err.Error() == "record not found" {
			return nil, nil // No active parking
		}
		return nil, err
	}

	slot, err := u.repo.GetSlotByID(tx.SlotID)
	if err != nil {
		return nil, err
	}

	zone, err := u.repo.GetZoneByID(slot.ZonaID)
	if err != nil {
		return nil, err
	}

	return &domain.ParkingEntryResult{
		TransaksiID: tx.IDTransaksi,
		NomorSlot:   slot.NomorSlot,
		NamaZona:    zone.NamaZona,
		Status:      "parkir",
		XCoord:      slot.XCoord,
		YCoord:      slot.YCoord,
	}, nil
}

// GetParkingStatus returns public zone occupancy data with coordinates.
func (u *parkingUsecase) GetParkingStatus() ([]domain.ZoneStatus, error) {
	zones, err := u.repo.GetAllZonesPublic()
	if err != nil {
		return nil, err
	}

	var result []domain.ZoneStatus
	for _, z := range zones {
		// Ambil semua slot zona ini untuk menghitung koordinat
		slots, slotErr := u.repo.GetSlotsByZone(z.IDZona)
		
		var xCoord, yCoord float64

		if slotErr == nil && len(slots) > 0 {
			var sumX, sumY float64
			for _, s := range slots {
				sumX += s.XCoord
				sumY += s.YCoord
			}
			n := float64(len(slots))
			xCoord = sumX / n
			yCoord = sumY / n
		}

		motor, mobil, _ := u.repo.GetOccupancyByVehicleType(z.IDZona)

		result = append(result, domain.ZoneStatus{
			ID:             z.IDZona,
			Nama:           z.NamaZona,
			KapasitasMotor: z.KapasitasMotor,
			KapasitasMobil: z.KapasitasMobil,
			TerpakaiMotor:  motor,
			TerpakaiMobil:  mobil,
			XCoord:         xCoord,
			YCoord:         yCoord,
		})
	}

	return result, nil
}

func (u *parkingUsecase) GetUserHistory(userID uint) ([]domain.Transaksi, error) {
	return u.repo.GetUserHistory(userID)
}

func (u *parkingUsecase) GetUserAlerts(userID uint) ([]domain.Penalti, error) {
	return u.repo.GetUserAlerts(userID)
}


