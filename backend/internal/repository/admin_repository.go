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
		Select("transaksis.id_transaksi, transaksis.id_user, users.nama as user_name, roles.nama_role as role, kendaraans.nomor_polisi, kendaraans.jenis_kendaraan as jenis, zona_parkirs.nama_zona as zona, transaksis.waktu_masuk, transaksis.waktu_keluar, transaksis.status").
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

// DeleteUser removes a user by ID (also cascades to related data via DB constraints)
func (r *adminRepository) DeleteUser(userID uint) error {
	return r.db.Delete(&domain.User{}, "id_user = ?", userID).Error
}

// UpdateUserRole changes the role of a user by looking up the role name
func (r *adminRepository) UpdateUserRole(userID uint, newRole string) error {
	// Find the role ID from name
	var role domain.Role
	if err := r.db.Where("nama_role = ?", newRole).First(&role).Error; err != nil {
		return err
	}
	return r.db.Model(&domain.User{}).
		Where("id_user = ?", userID).
		Update("id_role", role.ID).Error
}

// GetBlacklistedUsers returns users with cumulative penalty >= 30 points
func (r *adminRepository) GetBlacklistedUsers() ([]domain.BlacklistItem, error) {
	var items []domain.BlacklistItem

	err := r.db.Table("penaltis").
		Select("penaltis.id_user as user_id, users.nama as name, users.email, roles.nama_role as role, SUM(penaltis.poin_penalti) as total_poin, COUNT(penaltis.id_penalti) as jumlah_kasus, MAX(penaltis.jenis_pelanggaran) as alasan_terakhir, MAX(kendaraans.nomor_polisi) as nomor_polisi, CASE WHEN SUM(penaltis.poin_penalti) >= 50 THEN 'Blocked' ELSE 'Suspended' END as status_hukuman").
		Joins("left join users on users.id_user = penaltis.id_user").
		Joins("left join roles on roles.id_role = users.id_role").
		Joins("left join kendaraans on kendaraans.id_user = users.id_user").
		Group("penaltis.id_user, users.nama, users.email, roles.nama_role").
		Having("SUM(penaltis.poin_penalti) >= ?", 30).
		Order("total_poin DESC").
		Scan(&items).Error

	if err != nil {
		return nil, err
	}

	return items, nil
}

// ForceExitActivity manually ends a parking transaction and frees the slot
func (r *adminRepository) ForceExitActivity(activityID uint) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		var transaksi domain.Transaksi
		if err := tx.Where("id_transaksi = ?", activityID).First(&transaksi).Error; err != nil {
			return err
		}

		// Skip if already exited
		if transaksi.Status == "selesai" || transaksi.Status == "exited" {
			return nil
		}

		now := gorm.Expr("NOW()")
		if err := tx.Model(&domain.Transaksi{}).Where("id_transaksi = ?", activityID).
			Updates(map[string]interface{}{
				"waktu_keluar": now,
				"status":       "selesai",
			}).Error; err != nil {
			return err
		}

		// Free up the parking slot
		if err := tx.Model(&domain.SlotParkir{}).Where("id_slot = ?", transaksi.SlotID).
			Update("status", "available").Error; err != nil {
			return err
		}

		return nil
	})
}

// AddPenalty inserts a new penalty record for the user
func (r *adminRepository) AddPenalty(userID uint, poin int, keterangan string) error {
	penalti := domain.Penalti{
		UserID:           userID,
		PoinPenalti:      poin,
		JenisPelanggaran: keterangan,
	}
	return r.db.Create(&penalti).Error
}

// RemovePenalty deletes all penalty points for the user
func (r *adminRepository) RemovePenalty(userID uint) error {
	return r.db.Where("id_user = ?", userID).Delete(&domain.Penalti{}).Error
}

