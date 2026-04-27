package usecase

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/redis"
	redisv9 "github.com/redis/go-redis/v9"
)

type parkingUsecase struct {
	repo     domain.ParkingRepository
	userRepo domain.UserRepository
}

func NewParkingUsecase(repo domain.ParkingRepository, userRepo domain.UserRepository) domain.ParkingUsecase {
	return &parkingUsecase{repo, userRepo}
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
