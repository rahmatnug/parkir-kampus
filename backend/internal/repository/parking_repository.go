package repository

import (
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
