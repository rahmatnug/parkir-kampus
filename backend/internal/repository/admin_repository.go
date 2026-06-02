package repository

import (
	"errors"
	"fmt"
	"log"
	"strings"
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

	// Total Capacity = jumlah slot fisik yang ada di DB (bukan SUM(kapasitas) zona)
	var totalSlots int64
	r.db.Model(&domain.SlotParkir{}).Count(&totalSlots)
	stats.TotalCapacity = int(totalSlots)

	// Active Vehicles = slot ber-status 'occupied' (konsisten dengan GetParkingStatus)
	var occupiedCount int64
	r.db.Model(&domain.SlotParkir{}).Where("status = ?", "occupied").Count(&occupiedCount)
	stats.ActiveVehicles = int(occupiedCount)

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

func (r *adminRepository) UpdateUserStatus(userID uint, status string) error {
	return r.db.Model(&domain.User{}).
		Where("id_user = ?", userID).
		Update("status", status).Error
}

// RejectLaporan updates the report status to rejected.
func (r *adminRepository) RejectLaporan(laporanID uint) error {
	return r.db.Model(&domain.LaporanPetugas{}).
		Where("id_laporan = ?", laporanID).
		Update("status", "rejected").Error
}

// GetBlacklistedUsers returns users with cumulative penalty >= 30 points
func (r *adminRepository) GetBlacklistedUsers() ([]domain.BlacklistItem, error) {
	var items []domain.BlacklistItem

	query := `
		SELECT 
			u.nama AS nama_user, 
			u.nim AS nim, 
			COALESCE(u.profile_image_url, '') AS avatar_url, 
			COALESCE(r.nama_role, 'Unassigned') AS nama_role, 
			COALESCE((
				SELECT nomor_polisi 
				FROM kendaraans k2 
				WHERE k2.id_user = u.id_user 
				ORDER BY created_at DESC 
				LIMIT 1
			), '-') AS nomor_polisi, 
			COALESCE(SUM(p.poin_penalti), 0) AS total_poin, 
			COUNT(p.id_penalti) AS jumlah_kasus,
			COALESCE((
				SELECT CONCAT(p2.jenis_pelanggaran, ' (', DATE(p2.tanggal), ')') 
				FROM penaltis p2 
				WHERE p2.id_user = u.id_user 
				ORDER BY p2.tanggal DESC 
				LIMIT 1
			), '-') AS pelanggaran_terakhir,
			CASE 
				WHEN SUM(p.poin_penalti) > 100 THEN 'CRITICAL' 
				WHEN SUM(p.poin_penalti) >= 50 THEN 'WARNING' 
				ELSE 'SAFE' 
			END AS status_peringatan
		FROM users u
		LEFT JOIN roles r ON u.id_role = r.id_role
		LEFT JOIN penaltis p ON u.id_user = p.id_user
		LEFT JOIN blacklists b ON u.id_user = b.id_user
		GROUP BY u.id_user, u.nama, u.nim, u.profile_image_url, r.nama_role, u.status
		HAVING SUM(p.poin_penalti) >= 1 OR u.status = 'blocked' OR MAX(CASE WHEN b.status = 'active' THEN 1 ELSE 0 END) = 1
		ORDER BY total_poin DESC
	`

	rows, err := r.db.Raw(query).Rows()
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var item domain.BlacklistItem
		if err := r.db.ScanRows(rows, &item); err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (r *adminRepository) GetBlacklistStats() (*domain.BlacklistStats, error) {
	var stats domain.BlacklistStats
	var active int64
	var total int64
	r.db.Model(&domain.Blacklist{}).Where("status = ?", "active").Count(&active)
	r.db.Model(&domain.User{}).Where("status = ?", "blacklist").Count(&total)
	stats.ActiveRestrictions = int(active)
	stats.TotalBlacklisted = int(total)
	return &stats, nil
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
			"kapasitas_motor": zone.KapasitasMotor,
			"kapasitas_mobil": zone.KapasitasMobil,
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

// GetPendingLaporan retrieves all pending field reports
func (r *adminRepository) GetPendingLaporan() ([]domain.PendingLaporanItem, error) {
	var results []domain.PendingLaporanItem
	var laporans []domain.LaporanPetugas

	err := r.db.Preload("Petugas").
		Where("status IN ?", []string{"pending", "menunggu review"}).
		Order("created_at DESC").
		Find(&laporans).Error
	if err != nil {
		return nil, err
	}

	for _, l := range laporans {
		results = append(results, domain.PendingLaporanItem{
			IDLaporan:       l.IDLaporan,
			TipePelanggaran: l.DeskripsiPelanggaran,
			NomorPolisi:     l.TargetIdentifier,
			NamaPetugas:     l.Petugas.Nama,
			CreatedAt:       l.CreatedAt,
		})
	}
	return results, nil
}

// GetLaporanDetail fetches a report with its creator and resolves the target user/kendaraan.
func (r *adminRepository) GetLaporanDetail(id uint) (*domain.LaporanDetail, error) {
	var laporan domain.LaporanPetugas
	if err := r.db.Preload("Petugas").First(&laporan, id).Error; err != nil {
		return nil, err
	}

	detail := &domain.LaporanDetail{Laporan: laporan}

	// Try to resolve target_identifier
	var targetUser domain.User

	if laporan.TargetUserID != nil {
		err := r.db.Preload("Kendaraans", func(db *gorm.DB) *gorm.DB {
			return db.Order("created_at DESC")
		}).Preload("Role").First(&targetUser, *laporan.TargetUserID).Error
		if err == nil {
			detail.Target = &targetUser
		}
	} else {
		// Fallback for old reports without TargetUserID
		ident := strings.ToLower(strings.ReplaceAll(laporan.TargetIdentifier, " ", ""))
		err := r.db.Unscoped().Preload("Kendaraans", func(db *gorm.DB) *gorm.DB {
			return db.Order("created_at DESC")
		}).Preload("Role").
			Joins("LEFT JOIN kendaraans ON kendaraans.id_user = users.id_user").
			Where("LOWER(REPLACE(users.nim, ' ', '')) = ? OR LOWER(REPLACE(kendaraans.nomor_polisi, ' ', '')) = ?", ident, ident).
			First(&targetUser).Error
		if err == nil {
			detail.Target = &targetUser
		}
	}

	if detail.Target != nil {
		var penalties []domain.Penalti
		r.db.Where("id_user = ?", detail.Target.ID).Order("tanggal DESC").Find(&penalties)
		detail.Target.RiwayatPelanggaran = penalties
		
		var totalPoin int
		r.db.Model(&domain.Penalti{}).Where("id_user = ?", detail.Target.ID).Select("COALESCE(SUM(poin_penalti), 0)").Row().Scan(&totalPoin)
		detail.Target.TotalPoin = totalPoin
	}

	return detail, nil
}

// GetUserByID fetches a single user with their kendaraans preloaded.
func (r *adminRepository) GetUserByID(userID uint) (*domain.User, error) {
	var user domain.User
	err := r.db.Preload("Kendaraans", func(db *gorm.DB) *gorm.DB {
		return db.Order("created_at DESC")
	}).Preload("Role").
		Where("id_user = ?", userID).
		First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// CreateLaporan saves a new LaporanPetugas.
func (r *adminRepository) CreateLaporan(laporan *domain.LaporanPetugas, jenisKendaraan string) error {
	var targetUser domain.User
	ident := strings.ToLower(strings.ReplaceAll(laporan.TargetIdentifier, " ", ""))
	
	query := r.db.Unscoped().Joins("LEFT JOIN kendaraans ON kendaraans.id_user = users.id_user").
		Where("LOWER(REPLACE(kendaraans.nomor_polisi, ' ', '')) = ?", ident)

	if jenisKendaraan != "" {
		query = query.Where("LOWER(kendaraans.jenis_kendaraan) = ?", strings.ToLower(jenisKendaraan))
	}

	err := query.First(&targetUser).Error
	if err == nil {
		laporan.TargetUserID = &targetUser.ID
	}
	return r.db.Create(laporan).Error
}

// UpdateUserAdmin updates user, vehicle and status in one transaction.
// If status == "blocked", also inserts a blacklist record.
// If status == "active", also removes any existing blacklist records.
func (r *adminRepository) UpdateUserAdmin(userID uint, nama, nim string, roleID uint, status, nomorPolisi, jenisKendaraan string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		// 1. Update user table
		if err := tx.Model(&domain.User{}).Where("id_user = ?", userID).Updates(map[string]interface{}{
			"nama":    nama,
			"nim":     nim,
			"id_role": roleID,
			"status":  status,
		}).Error; err != nil {
			return err
		}

		// 2. Sync blacklists table
		if status == "blocked" {
			// Hapus riwayat penalti lama
			if err := tx.Where("id_user = ?", userID).Delete(&domain.Penalti{}).Error; err != nil {
				return err
			}
			// Insert 100 poin override
  			if err := tx.Create(&domain.Penalti{
  				UserID:           userID,
  				JenisPelanggaran: "Manual Blacklist by Admin",
  				PoinPenalti:      100,
  				Tanggal:          time.Now(),
  			}).Error; err != nil {
				return err
			}

			// Check if blacklist record already exists
			var count int64
			tx.Model(&domain.Blacklist{}).Where("id_user = ? AND status = ?", userID, "active").Count(&count)
			if count == 0 {
				bl := domain.Blacklist{
					UserID:       userID,
					Alasan:       "Manual Override by Admin",
					TanggalMulai: time.Now(),
					Status:       "active",
				}
				if err := tx.Create(&bl).Error; err != nil {
					return fmt.Errorf("gagal membuat blacklist: %w", err)
				}
			}
		} else if status == "active" {
			// Hapus riwayat penalti agar poin jadi 0
			if err := tx.Where("id_user = ?", userID).Delete(&domain.Penalti{}).Error; err != nil {
				return err
			}
			// Hapus record blacklist
			if err := tx.Where("id_user = ?", userID).Delete(&domain.Blacklist{}).Error; err != nil {
				return fmt.Errorf("gagal hapus blacklist: %w", err)
			}
		}

		// 3. Create vehicle history if new
		if nomorPolisi != "" {
			var count int64
			tx.Model(&domain.Kendaraan{}).Where("nomor_polisi = ?", nomorPolisi).Count(&count)
			if count == 0 {
				// Soft delete kendaraan lama
				tx.Where("id_user = ?", userID).Delete(&domain.Kendaraan{})

				newKendaraan := domain.Kendaraan{
					UserID:         userID,
					NomorPolisi:    nomorPolisi,
					JenisKendaraan: jenisKendaraan,
				}
				if err := tx.Create(&newKendaraan).Error; err != nil {
					return err
				}
			}
		}

		return nil
	})
}
// ApproveLaporan updates the report status and adds a penalty to the target user.
func (r *adminRepository) ApproveLaporan(laporanID uint, poin int, pelanggaran string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		var laporan domain.LaporanPetugas
		if err := tx.First(&laporan, laporanID).Error; err != nil {
			return err
		}

		if laporan.Status != "pending" {
			return errors.New("laporan sudah diproses")
		}

		// Find target user
		var targetUser domain.User
		if laporan.TargetUserID != nil {
			if err := tx.First(&targetUser, *laporan.TargetUserID).Error; err != nil {
				return errors.New("target pengguna tidak ditemukan berdasarkan ID")
			}
		} else {
			ident := strings.ToLower(strings.ReplaceAll(laporan.TargetIdentifier, " ", ""))
			err := tx.Unscoped().Joins("LEFT JOIN kendaraans ON kendaraans.id_user = users.id_user").
				Where("LOWER(REPLACE(users.nim, ' ', '')) = ? OR LOWER(REPLACE(kendaraans.nomor_polisi, ' ', '')) = ?", ident, ident).
				First(&targetUser).Error

			if err != nil {
				return errors.New("target pengguna tidak ditemukan berdasarkan identifier")
			}
		}

		// Add penalty
		penalti := domain.Penalti{
			UserID:           targetUser.ID,
			PoinPenalti:      poin,
			JenisPelanggaran: pelanggaran,
			Tanggal:          time.Now(),
		}
		if err := tx.Create(&penalti).Error; err != nil {
			return err
		}

		// Update report status
		if err := tx.Model(&laporan).Update("status", "approved").Error; err != nil {
			return err
		}

		return nil
	})
}
