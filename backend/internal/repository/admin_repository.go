package repository

import (
	"errors"
	"fmt"
	"log"
	"time"

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
		Select("users.id_user as id, users.nama as name, users.email, users.nim, COALESCE(roles.nama_role, 'Unassigned') as role, users.status, users.created_at").
		Joins("left join roles on roles.id_role = users.id_role").
		Order("users.created_at DESC").
		Scan(&users).Error

	if err != nil {
		log.Printf("[GetAllUsers] ERROR querying users: %v", err)
		return nil, err
	}

	log.Printf("[GetAllUsers] Berhasil mengambil %d user dari database", len(users))
	if len(users) > 0 {
		log.Printf("[GetAllUsers] Contoh user pertama: ID=%d, Name=%s, Email=%s", users[0].ID, users[0].Name, users[0].Email)
	}

	return users, nil
}

func (r *adminRepository) GetAllActivities() ([]domain.AdminActivityItem, error) {
	var activities []domain.AdminActivityItem

	err := r.db.Table("transaksis").
		Select("transaksis.id_transaksi, transaksis.id_user, users.nama as user_name, COALESCE(roles.nama_role, 'Unassigned') as role, kendaraans.nomor_polisi, kendaraans.jenis_kendaraan as jenis, zona_parkirs.nama_zona as zona, transaksis.waktu_masuk, transaksis.waktu_keluar, transaksis.status").
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

// DeleteUser removes a user and ALL related child records inside a single transaction.
// We manually delete child rows first to avoid FK constraint violations on databases
// that do not have ON DELETE CASCADE configured.
func (r *adminRepository) DeleteUser(userID uint) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Verify the user exists before attempting deletion
		var user domain.User
		if err := tx.First(&user, "id_user = ?", userID).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				return fmt.Errorf("user dengan ID %d tidak ditemukan", userID)
			}
			return err
		}

		// 2. Delete waiting_lists referencing this user
		if err := tx.Where("id_user = ?", userID).Delete(&domain.WaitingList{}).Error; err != nil {
			return fmt.Errorf("gagal hapus waiting list: %w", err)
		}

		// 3. Delete penaltis referencing this user
		if err := tx.Where("id_user = ?", userID).Delete(&domain.Penalti{}).Error; err != nil {
			return fmt.Errorf("gagal hapus penalti: %w", err)
		}

		// 4. Delete blacklists referencing this user
		if err := tx.Where("id_user = ?", userID).Delete(&domain.Blacklist{}).Error; err != nil {
			return fmt.Errorf("gagal hapus blacklist: %w", err)
		}

		// 5. Delete transaksis referencing this user
		if err := tx.Where("id_user = ?", userID).Delete(&domain.Transaksi{}).Error; err != nil {
			return fmt.Errorf("gagal hapus transaksi: %w", err)
		}

		// 6. Delete kendaraans referencing this user
		if err := tx.Where("id_user = ?", userID).Delete(&domain.Kendaraan{}).Error; err != nil {
			return fmt.Errorf("gagal hapus kendaraan: %w", err)
		}

		// 7. Finally delete the user itself
		if err := tx.Delete(&domain.User{}, "id_user = ?", userID).Error; err != nil {
			return fmt.Errorf("gagal hapus user: %w", err)
		}

		return nil
	})
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
		Select("penaltis.id_user as user_id, users.nama as name, users.email, COALESCE(roles.nama_role, 'Unassigned') as role, SUM(penaltis.poin_penalti) as total_poin, COUNT(penaltis.id_penalti) as jumlah_kasus, MAX(penaltis.jenis_pelanggaran) as alasan_terakhir, MAX(kendaraans.nomor_polisi) as nomor_polisi, CASE WHEN SUM(penaltis.poin_penalti) >= 50 THEN 'Blocked' ELSE 'Suspended' END as status_hukuman").
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

// HasActiveTransaction checks whether a user currently has a parking session
// with status 'parkir'.
func (r *adminRepository) HasActiveTransaction(userID uint) (bool, error) {
	var count int64
	err := r.db.Model(&domain.Transaksi{}).
		Where("id_user = ? AND status = ?", userID, "parkir").
		Count(&count).Error
	return count > 0, err
}

// GetTotalPenaltyPoints returns the sum of all penalty points for a user.
func (r *adminRepository) GetTotalPenaltyPoints(userID uint) (int, error) {
	var total int
	err := r.db.Model(&domain.Penalti{}).
		Where("id_user = ?", userID).
		Select("COALESCE(SUM(poin_penalti), 0)").
		Row().Scan(&total)
	return total, err
}

// CreateBlacklist inserts a new blacklist record.
func (r *adminRepository) CreateBlacklist(userID uint, alasan string) error {
	bl := domain.Blacklist{
		UserID:       userID,
		Alasan:       alasan,
		TanggalMulai: time.Now(),
		Status:       "active",
	}
	return r.db.Create(&bl).Error
}

// ─── Zone CRUD ──────────────────────────────────────────────────────────────

func (r *adminRepository) CreateZone(zone *domain.ZonaParkir) error {
	return r.db.Create(zone).Error
}

func (r *adminRepository) GetAllZones() ([]domain.ZoneWithSlots, error) {
	var zones []domain.ZoneWithSlots

	err := r.db.Table("zona_parkirs").
		Select(`zona_parkirs.id_zona, zona_parkirs.nama_zona, zona_parkirs.deskripsi,
			zona_parkirs.kapasitas, zona_parkirs.status,
			COUNT(slot_parkirs.id_slot) as total_slots,
			COUNT(CASE WHEN slot_parkirs.status = 'available' THEN 1 END) as available_slots`).
		Joins("LEFT JOIN slot_parkirs ON slot_parkirs.id_zona = zona_parkirs.id_zona").
		Group("zona_parkirs.id_zona, zona_parkirs.nama_zona, zona_parkirs.deskripsi, zona_parkirs.kapasitas, zona_parkirs.status").
		Order("zona_parkirs.id_zona ASC").
		Scan(&zones).Error

	if err != nil {
		return nil, err
	}
	return zones, nil
}

func (r *adminRepository) UpdateZone(zone *domain.ZonaParkir) error {
	return r.db.Model(&domain.ZonaParkir{}).
		Where("id_zona = ?", zone.IDZona).
		Updates(map[string]interface{}{
			"nama_zona": zone.NamaZona,
			"deskripsi": zone.Deskripsi,
			"kapasitas": zone.Kapasitas,
		}).Error
}

// DeleteZone removes a zone and all its slots within a single DB transaction.
func (r *adminRepository) DeleteZone(zonaID uint) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Ensure no active transactions reference slots in this zone
		var activeCount int64
		tx.Table("transaksis").
			Joins("JOIN slot_parkirs ON slot_parkirs.id_slot = transaksis.id_slot").
			Where("slot_parkirs.id_zona = ? AND transaksis.status = ?", zonaID, "parkir").
			Count(&activeCount)

		if activeCount > 0 {
			return fmt.Errorf("tidak bisa menghapus zona: masih ada %d kendaraan yang sedang parkir", activeCount)
		}

		// 2. Delete all slots belonging to this zone
		if err := tx.Where("id_zona = ?", zonaID).Delete(&domain.SlotParkir{}).Error; err != nil {
			return fmt.Errorf("gagal hapus slot di zona: %w", err)
		}

		// 3. Delete the zone
		if err := tx.Delete(&domain.ZonaParkir{}, "id_zona = ?", zonaID).Error; err != nil {
			return fmt.Errorf("gagal hapus zona: %w", err)
		}

		return nil
	})
}

func (r *adminRepository) FindZoneByName(name string) (*domain.ZonaParkir, error) {
	var zone domain.ZonaParkir
	if err := r.db.Where("LOWER(nama_zona) = LOWER(?)", name).First(&zone).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &zone, nil
}

// ─── Slot CRUD ──────────────────────────────────────────────────────────────

func (r *adminRepository) CreateSlot(slot *domain.SlotParkir) error {
	return r.db.Create(slot).Error
}

func (r *adminRepository) GetSlotsByZone(zonaID uint) ([]domain.SlotParkir, error) {
	var slots []domain.SlotParkir
	err := r.db.Where("id_zona = ?", zonaID).Order("nomor_slot ASC").Find(&slots).Error
	return slots, err
}

func (r *adminRepository) DeleteSlot(slotID uint) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// Ensure no active transaction on this slot
		var activeCount int64
		tx.Model(&domain.Transaksi{}).
			Where("id_slot = ? AND status = ?", slotID, "parkir").
			Count(&activeCount)

		if activeCount > 0 {
			return errors.New("tidak bisa menghapus slot: masih ada kendaraan yang parkir di slot ini")
		}

		return tx.Delete(&domain.SlotParkir{}, "id_slot = ?", slotID).Error
	})
}
