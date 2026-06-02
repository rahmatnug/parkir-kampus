package repository

import (
	"errors"
	"fmt"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"gorm.io/gorm"
)

type userRepository struct {
	db *gorm.DB
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *gorm.DB) domain.UserRepository {
	return &userRepository{
		db: db,
	}
}

func (r *userRepository) Create(user *domain.User) error {
	return r.db.Create(user).Error
}

func (r *userRepository) FindByEmail(email string) (*domain.User, error) {
	var user domain.User
	err := r.db.Preload("Kendaraans", func(db *gorm.DB) *gorm.DB {
		return db.Order("created_at DESC")
	}).Where("email = ? OR nim = ?", email, email).First(&user).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil // Or custom error
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByID(id uint) (*domain.User, error) {
	var user domain.User
	err := r.db.Preload("Role").Preload("Kendaraans", func(db *gorm.DB) *gorm.DB {
		return db.Order("created_at DESC")
	}).First(&user, id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil // Or custom error
		}
		return nil, err
	}

	// Fetch Total Points
	var totalPoin int
	r.db.Model(&domain.Penalti{}).Where("id_user = ?", id).Select("COALESCE(SUM(poin_penalti), 0)").Row().Scan(&totalPoin)
	user.TotalPoin = totalPoin

	// Fetch Blacklist Status
	var bl domain.Blacklist
	if err := r.db.Where("id_user = ? AND status = ?", id, "active").Order("tanggal_mulai DESC").First(&bl).Error; err == nil {
		user.IsBlacklisted = true
		user.BlacklistReason = bl.Alasan
		user.BlacklistDate = bl.TanggalMulai.Format("02 Jan 2006")
	}

	// Fetch recent 2 penalties
	var penalties []domain.Penalti
	r.db.Where("id_user = ?", id).Order("tanggal DESC").Limit(2).Find(&penalties)
	if penalties == nil {
		penalties = []domain.Penalti{}
	}
	user.RiwayatPelanggaran = penalties

	return &user, nil
}

func (r *userRepository) UpdatePassword(userID uint, newPasswordHash string) error {
	return r.db.Model(&domain.User{}).
		Where("id_user = ?", userID).
		Update("password_hash", newPasswordHash).Error
}

func (r *userRepository) UpdateProfileImageURL(userID uint, imageURL string) error {
	return r.db.Model(&domain.User{}).
		Where("id_user = ?", userID).
		Update("profile_image_url", imageURL).Error
}

func (r *userRepository) UpdateKendaraan(userID uint, kendaraanID uint, nomorPolisi, jenisKendaraan, warna string) error {
	var count int64
	r.db.Model(&domain.Kendaraan{}).Where("nomor_polisi = ? AND id_user != ?", nomorPolisi, userID).Count(&count)
	if count > 0 {
		return fmt.Errorf("Plat nomor sudah digunakan akun lain")
	}

	// Soft delete kendaraan lama
	r.db.Where("id_user = ?", userID).Delete(&domain.Kendaraan{})

	newKendaraan := domain.Kendaraan{
		UserID:         userID,
		NomorPolisi:    nomorPolisi,
		JenisKendaraan: jenisKendaraan,
		Warna:          warna,
	}
	return r.db.Create(&newKendaraan).Error
}
