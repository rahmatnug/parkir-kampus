package repository

import (
	"fmt"
	"time"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type parkingRepository struct {
	db *gorm.DB
}

func NewParkingRepository(db *gorm.DB) domain.ParkingRepository {
	return &parkingRepository{db}
}

func (r *parkingRepository) GetAvailableSlotWithLock(zonaID uint) (*domain.SlotParkir, error) {
	var slot domain.SlotParkir
	// SELECT ... FOR UPDATE SKIP LOCKED
	err := r.db.Clauses(clause.Locking{
		Strength: "UPDATE",
		Options:  "SKIP LOCKED",
	}).Where("id_zona = ? AND status = ?", zonaID, "available").
		Order("id_slot ASC").
		First(&slot).Error

	if err != nil {
		return nil, err
	}
	return &slot, nil
}

func (r *parkingRepository) CreateTransaksi(tx *domain.Transaksi) error {
	return r.db.Create(tx).Error
}

func (r *parkingRepository) GetActiveTransaksi(userID uint) (*domain.Transaksi, error) {
	var tx domain.Transaksi
	err := r.db.Where("id_user = ? AND status = ?", userID, "parkir").First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *parkingRepository) UpdateTransaksi(tx *domain.Transaksi) error {
	if tx.WaktuKeluar != nil {
		return r.db.Model(&domain.Transaksi{}).Where("id_transaksi = ?", tx.IDTransaksi).Updates(map[string]interface{}{
			"waktu_keluar": *tx.WaktuKeluar,
			"status":       tx.Status,
		}).Error
	}
	return r.db.Save(tx).Error
}

func (r *parkingRepository) UpdateSlotStatus(slotID uint, status string) error {
	return r.db.Model(&domain.SlotParkir{}).Where("id_slot = ?", slotID).Update("status", status).Error
}

func (r *parkingRepository) GetSlotByID(slotID uint) (*domain.SlotParkir, error) {
	var slot domain.SlotParkir
	err := r.db.First(&slot, slotID).Error
	if err != nil {
		return nil, err
	}
	return &slot, nil
}

func (r *parkingRepository) CountAvailableSlots(zonaID uint) (int64, error) {
	var count int64
	err := r.db.Model(&domain.SlotParkir{}).Where("id_zona = ? AND status = ?", zonaID, "available").Count(&count).Error
	return count, err
}

func (r *parkingRepository) CreatePenalti(p *domain.Penalti) error {
	return r.db.Create(p).Error
}

func (r *parkingRepository) FindInParkTransactions() ([]domain.Transaksi, error) {
	var txs []domain.Transaksi
	err := r.db.Where("status = ?", "parkir").Find(&txs).Error
	return txs, err
}

// GetZoneByID finds a zone by its ID
func (r *parkingRepository) GetZoneByID(zonaID uint) (*domain.ZonaParkir, error) {
	var zone domain.ZonaParkir
	err := r.db.Where("id_zona = ?", zonaID).First(&zone).Error
	if err != nil {
		return nil, err
	}
	return &zone, nil
}

// GetZoneByCode finds a zone by its nama_zona or id_zona (the code embedded in the QR).
// Supports formats like "ZONE-A" -> looks for "Zone A", direct name match, or numeric ID.
func (r *parkingRepository) GetZoneByCode(code string) (*domain.ZonaParkir, error) {
	var zone domain.ZonaParkir
	
	// First, check if the code is a numeric ID
	var id int
	_, errScan := fmt.Sscanf(code, "%d", &id)
	if errScan == nil {
		err := r.db.Where("id_zona = ?", id).First(&zone).Error
		if err == nil {
			return &zone, nil
		}
	}

	// Try exact match first, then case-insensitive
	err := r.db.Where("LOWER(nama_zona) = LOWER(?)", code).First(&zone).Error
	if err != nil {
		return nil, err
	}
	return &zone, nil
}

// GetUserKendaraan returns the first registered vehicle for a user.
func (r *parkingRepository) GetUserKendaraan(userID uint) (*domain.Kendaraan, error) {
	var k domain.Kendaraan
	err := r.db.Where("id_user = ?", userID).Order("created_at DESC").First(&k).Error
	if err != nil {
		return nil, err
	}
	return &k, nil
}

// GetTotalPenaltyPoints returns the cumulative penalty points for a user.
func (r *parkingRepository) GetTotalPenaltyPoints(userID uint) (int, error) {
	var total int
	err := r.db.Model(&domain.Penalti{}).
		Where("id_user = ?", userID).
		Select("COALESCE(SUM(poin_penalti), 0)").
		Row().Scan(&total)
	return total, err
}

// BookSlotAndCreateTransaction atomically finds an available slot (with row lock),
// marks it as occupied, and creates the parking transaction — all within a single
// database transaction to prevent two users grabbing the same slot.
func (r *parkingRepository) BookSlotAndCreateTransaction(userID uint, kendaraanID uint, zonaID uint) (*domain.Transaksi, *domain.SlotParkir, error) {
	var resultTx domain.Transaksi
	var resultSlot domain.SlotParkir

	err := r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Lock the first available slot (SELECT ... FOR UPDATE SKIP LOCKED)
		var slot domain.SlotParkir
		if err := tx.Clauses(clause.Locking{
			Strength: "UPDATE",
			Options:  "SKIP LOCKED",
		}).Where("id_zona = ? AND status = ?", zonaID, "available").
			Order("id_slot ASC").
			First(&slot).Error; err != nil {
			return err // gorm.ErrRecordNotFound if zone is full
		}

		// 2. Mark the slot as occupied
		if err := tx.Model(&domain.SlotParkir{}).
			Where("id_slot = ?", slot.IDSlot).
			Update("status", "occupied").Error; err != nil {
			return err
		}

		// 3. Create the transaction record
		transaksi := domain.Transaksi{
			UserID:      userID,
			KendaraanID: kendaraanID,
			SlotID:      slot.IDSlot,
			Status:      "parkir",
		}
		transaksi.WaktuMasuk = time.Now()
		if err := tx.Create(&transaksi).Error; err != nil {
			return err
		}

		resultTx = transaksi
		resultSlot = slot
		return nil
	})

	if err != nil {
		return nil, nil, err
	}
	return &resultTx, &resultSlot, nil
}

// ReleaseSlotAndUpdateTransaction automatically ends the parking transaction and frees the slot.
func (r *parkingRepository) ReleaseSlotAndUpdateTransaction(userID uint) (*domain.Transaksi, error) {
	var resultTx domain.Transaksi

	err := r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Find the active transaction
		if err := tx.Where("id_user = ? AND status = ?", userID, "parkir").First(&resultTx).Error; err != nil {
			return err
		}

		// 2. Mark the slot as available
		if err := tx.Model(&domain.SlotParkir{}).
			Where("id_slot = ?", resultTx.SlotID).
			Update("status", "available").Error; err != nil {
			return err
		}

		// 3. Mark transaction as selesai and set waktu_keluar
		now := time.Now()
		resultTx.WaktuKeluar = &now
		resultTx.Status = "selesai"

		if err := tx.Model(&domain.Transaksi{}).Where("id_transaksi = ?", resultTx.IDTransaksi).Updates(map[string]interface{}{
			"waktu_keluar": now,
			"status":       "selesai",
		}).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return nil, err
	}
	return &resultTx, nil
}

// GetAllZonesPublic returns all active parking zones (no admin auth required).
func (r *parkingRepository) GetAllZonesPublic() ([]domain.ZonaParkir, error) {
	var zones []domain.ZonaParkir
	err := r.db.Where("status = ?", "active").Order("nama_zona ASC").Find(&zones).Error
	return zones, err
}

// GetSlotsByZone returns all slots for a given zone.
func (r *parkingRepository) GetSlotsByZone(zonaID uint) ([]domain.SlotParkir, error) {
	var slots []domain.SlotParkir
	err := r.db.Where("id_zona = ?", zonaID).Order("nomor_slot ASC").Find(&slots).Error
	return slots, err
}

func (r *parkingRepository) GetOccupancyByVehicleType(zonaID uint) (int, int, error) {
	var motor, mobil int64
	err := r.db.Model(&domain.Transaksi{}).
		Joins("JOIN kendaraans ON kendaraans.id_kendaraan = transaksis.id_kendaraan").
		Joins("JOIN slot_parkirs ON slot_parkirs.id_slot = transaksis.id_slot").
		Where("slot_parkirs.id_zona = ? AND transaksis.status = 'parkir'", zonaID).
		Select("SUM(CASE WHEN kendaraans.jenis_kendaraan = 'motor' THEN 1 ELSE 0 END) as motor, SUM(CASE WHEN kendaraans.jenis_kendaraan = 'mobil' THEN 1 ELSE 0 END) as mobil").
		Row().Scan(&motor, &mobil)
	
	if err != nil {
		// if no rows or null, just return 0,0
		return 0, 0, nil
	}
	return int(motor), int(mobil), nil
}

func (r *parkingRepository) GetUserHistory(userID uint) ([]domain.Transaksi, error) {
	var txs []domain.Transaksi
	err := r.db.Preload("Slot.Zona").Preload("Kendaraan").Where("id_user = ?", userID).Order("waktu_masuk DESC").Find(&txs).Error
	return txs, err
}

func (r *parkingRepository) GetUserAlerts(userID uint) ([]domain.Penalti, error) {
	var alerts []domain.Penalti
	err := r.db.Where("id_user = ?", userID).Order("tanggal DESC").Find(&alerts).Error
	return alerts, err
}


