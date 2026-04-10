package repository

import (
	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"gorm.io/gorm"
)

type adminRepository struct {
	db *gorm.DB
}

func NewAdminRepository(db *gorm.DB) domain.AdminRepository {
	return &adminRepository{db}
}

func (r *adminRepository) GetDashboardStats() (*domain.DashboardStats, error) {
	var stats domain.DashboardStats

	// Calculate Total Capacity
	r.db.Model(&domain.ZonaParkir{}).Select("COALESCE(SUM(kapasitas), 0)").Row().Scan(&stats.TotalCapacity)

	// Calculate Active Vehicles (status = 'parkir' in transaksi)
	var activeCount int64
	r.db.Model(&domain.Transaksi{}).Where("status = ?", "parkir").Count(&activeCount)
	stats.ActiveVehicles = int(activeCount)

	// Available slots = Total - Active
	stats.AvailableSlots = stats.TotalCapacity - stats.ActiveVehicles
	if stats.AvailableSlots < 0 {
		stats.AvailableSlots = 0
	}

	// Registered Users
	var userCount int64
	r.db.Model(&domain.User{}).Count(&userCount)
	stats.RegisteredUsers = int(userCount)

	return &stats, nil
}

func (r *adminRepository) GetAllUsers() ([]domain.AdminUserItem, error) {
	var users []domain.AdminUserItem

	err := r.db.Table("users").
		Select("users.id_user as id, users.nama as name, users.email, roles.nama_role as role, users.status, users.created_at").
		Joins("left join roles on roles.id_role = users.id_role").
		Order("users.created_at DESC").
		Scan(&users).Error

	if err != nil {
		return nil, err
	}

	return users, nil
}

func (r *adminRepository) GetAllActivities() ([]domain.AdminActivityItem, error) {
	var activities []domain.AdminActivityItem

	err := r.db.Table("transaksis").
		Select("transaksis.id_transaksi, users.nama as user_name, roles.nama_role as role, kendaraans.nomor_polisi, kendaraans.jenis_kendaraan as jenis, zona_parkirs.nama_zona as zona, transaksis.waktu_masuk, transaksis.waktu_keluar, transaksis.status").
		Joins("left join users on users.id_user = transaksis.id_user").
		Joins("left join roles on roles.id_role = users.id_role").
		Joins("left join kendaraans on kendaraans.id_kendaraan = transaksis.id_kendaraan").
		Joins("left join slot_parkirs on slot_parkirs.id_slot = transaksis.id_slot").
		Joins("left join zona_parkirs on zona_parkirs.id_zona = slot_parkirs.id_zona").
		Order("transaksis.waktu_masuk DESC").
		Limit(100).
		Scan(&activities).Error

	if err != nil {
		return nil, err
	}

	return activities, nil
}
