package usecase

import (
	"errors"
	"fmt"
	"strings"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

// BlacklistThreshold — once a user accumulates this many penalty points
// they are automatically blacklisted.
const BlacklistThreshold = 100

type adminUsecase struct {
	adminRepo domain.AdminRepository
	wsHub     domain.WSHub
}

func NewAdminUsecase(repo domain.AdminRepository, wsHub domain.WSHub) domain.AdminUsecase {
	return &adminUsecase{
		adminRepo: repo,
		wsHub:     wsHub,
	}
}

func (u *adminUsecase) GetUserByID(userID uint) (*domain.User, error) {
	return u.adminRepo.GetUserByID(userID)
}

func (u *adminUsecase) GetDashboardData() (*domain.DashboardStats, error) {
	return u.adminRepo.GetDashboardStats()
}

func (u *adminUsecase) GetUsersList() ([]domain.AdminUserItem, error) {
	return u.adminRepo.GetAllUsers()
}

func (u *adminUsecase) GetActivityLogs() ([]domain.AdminActivityItem, error) {
	return u.adminRepo.GetAllActivities()
}

// DeleteUser validates that the user has no active parking transaction before
// delegating deletion to the repository.
func (u *adminUsecase) DeleteUser(userID uint) error {
	if userID == 0 {
		return errors.New("user ID tidak valid")
	}

	hasActive, err := u.adminRepo.HasActiveTransaction(userID)
	if err != nil {
		return fmt.Errorf("gagal cek transaksi aktif: %w", err)
	}
	if hasActive {
		return errors.New("user masih memiliki transaksi parkir aktif, selesaikan terlebih dahulu")
	}

	return u.adminRepo.DeleteUser(userID)
}

func (u *adminUsecase) UpdateUserRole(userID uint, newRole string) error {
	if userID == 0 {
		return errors.New("user ID tidak valid")
	}
	newRole = strings.TrimSpace(strings.ToLower(newRole))
	if newRole == "" {
		return errors.New("role tidak boleh kosong")
	}
	return u.adminRepo.UpdateUserRole(userID, newRole)
}

func (u *adminUsecase) UpdateUserStatus(userID uint, newStatus string) error {
	if userID == 0 {
		return errors.New("user ID tidak valid")
	}
	newStatus = strings.TrimSpace(strings.ToLower(newStatus))
	if newStatus == "" {
		return errors.New("status tidak boleh kosong")
	}
	return u.adminRepo.UpdateUserStatus(userID, newStatus)
}

func (u *adminUsecase) GetBlacklist() ([]domain.BlacklistItem, error) {
	return u.adminRepo.GetBlacklistedUsers()
}

func (u *adminUsecase) GetBlacklistStats() (*domain.BlacklistStats, error) {
	return u.adminRepo.GetBlacklistStats()
}

func (u *adminUsecase) ForceExitActivity(activityID uint) error {
	if activityID == 0 {
		return errors.New("activity ID tidak valid")
	}
	return u.adminRepo.ForceExitActivity(activityID)
}

// AddPenalty validates the penalty input and, if the cumulative points reach
// the threshold, automatically blacklists the user.
func (u *adminUsecase) AddPenalty(userID uint, poin int, keterangan string) error {
	if userID == 0 {
		return errors.New("user ID tidak valid")
	}
	if poin <= 0 {
		return errors.New("poin penalti harus lebih besar dari 0")
	}
	if strings.TrimSpace(keterangan) == "" {
		return errors.New("keterangan pelanggaran tidak boleh kosong")
	}

	// Persist the penalty first
	if err := u.adminRepo.AddPenalty(userID, poin, keterangan); err != nil {
		return err
	}

	// Check cumulative total and auto-blacklist when threshold is reached
	totalPoin, err := u.adminRepo.GetTotalPenaltyPoints(userID)
	if err != nil {
		return fmt.Errorf("gagal cek total poin: %w", err)
	}

	if totalPoin >= domain.MaxPenaltyPoints {
		alasan := fmt.Sprintf("Otomatis blacklist: akumulasi poin penalti mencapai %d (batas: %d)", totalPoin, domain.MaxPenaltyPoints)
		if err := u.adminRepo.CreateBlacklist(userID, alasan); err != nil {
			return fmt.Errorf("gagal membuat blacklist otomatis: %w", err)
		}
		
		// Ensure user status is updated to "blacklist"
		if err := u.adminRepo.UpdateUserStatus(userID, "blacklist"); err != nil {
			return fmt.Errorf("gagal update status user ke blacklist: %w", err)
		}
	}

	return nil
}

func (u *adminUsecase) RemovePenalty(userID uint) error {
	if userID == 0 {
		return errors.New("user ID tidak valid")
	}
	return u.adminRepo.RemovePenalty(userID)
}

// ─── Zone CRUD ──────────────────────────────────────────────────────────────

func (u *adminUsecase) CreateZone(namaZona string, deskripsi string, kapasitasMotor int, kapasitasMobil int) (uint, error) {
	namaZona = strings.TrimSpace(namaZona)
	if namaZona == "" {
		return 0, errors.New("nama zona tidak boleh kosong")
	}
	if kapasitasMotor < 0 || kapasitasMobil < 0 {
		return 0, errors.New("kapasitas zona tidak boleh negatif")
	}

	// Duplicate name check
	existing, _ := u.adminRepo.FindZoneByName(namaZona)
	if existing != nil {
		return 0, fmt.Errorf("zona dengan nama '%s' sudah ada", namaZona)
	}

	zone := &domain.ZonaParkir{
		NamaZona:       namaZona,
		Deskripsi:      deskripsi,
		KapasitasMotor: kapasitasMotor,
		KapasitasMobil: kapasitasMobil,
		Status:         "active",
	}
	err := u.adminRepo.CreateZone(zone)
	if err == nil && u.wsHub != nil {
		u.wsHub.NotifyLayoutUpdate()
	}
	return zone.IDZona, err
}

func (u *adminUsecase) GetAllZones() ([]domain.ZoneWithSlots, error) {
	return u.adminRepo.GetAllZones()
}

// UpdateZone validates before delegating to repository.
func (u *adminUsecase) UpdateZone(zonaID uint, namaZona string, deskripsi string, kapasitasMotor int, kapasitasMobil int) error {
	if zonaID == 0 {
		return errors.New("zona ID tidak valid")
	}
	namaZona = strings.TrimSpace(namaZona)
	if namaZona == "" {
		return errors.New("nama zona tidak boleh kosong")
	}
	if kapasitasMotor < 0 || kapasitasMobil < 0 {
		return errors.New("kapasitas zona tidak boleh negatif")
	}

	// Duplicate name check (exclude self)
	existing, _ := u.adminRepo.FindZoneByName(namaZona)
	if existing != nil && existing.IDZona != zonaID {
		return fmt.Errorf("zona dengan nama '%s' sudah ada", namaZona)
	}

	zone := &domain.ZonaParkir{
		IDZona:         zonaID,
		NamaZona:       namaZona,
		Deskripsi:      deskripsi,
		KapasitasMotor: kapasitasMotor,
		KapasitasMobil: kapasitasMobil,
	}
	err := u.adminRepo.UpdateZone(zone)
	if err == nil && u.wsHub != nil {
		u.wsHub.NotifyLayoutUpdate()
	}
	return err
}

func (u *adminUsecase) DeleteZone(zonaID uint) error {
	if zonaID == 0 {
		return errors.New("zona ID tidak valid")
	}
	err := u.adminRepo.DeleteZone(zonaID)
	if err == nil && u.wsHub != nil {
		u.wsHub.NotifyLayoutUpdate()
	}
	return err
}

// ─── Slot CRUD ──────────────────────────────────────────────────────────────

func (u *adminUsecase) CreateSlot(zonaID uint, nomorSlot string) error {
	if zonaID == 0 {
		return errors.New("zona ID tidak valid")
	}
	nomorSlot = strings.TrimSpace(nomorSlot)
	if nomorSlot == "" {
		return errors.New("nomor slot tidak boleh kosong")
	}

	slot := &domain.SlotParkir{
		ZonaID:    zonaID,
		NomorSlot: nomorSlot,
		Status:    "available",
	}
	return u.adminRepo.CreateSlot(slot)
}

func (u *adminUsecase) GetSlotsByZone(zonaID uint) ([]domain.SlotParkir, error) {
	if zonaID == 0 {
		return nil, errors.New("zona ID tidak valid")
	}
	return u.adminRepo.GetSlotsByZone(zonaID)
}

func (u *adminUsecase) DeleteSlot(slotID uint) error {
	if slotID == 0 {
		return errors.New("slot ID tidak valid")
	}
	return u.adminRepo.DeleteSlot(slotID)
}

func (u *adminUsecase) GetPendingLaporan() ([]domain.PendingLaporanItem, error) {
	return u.adminRepo.GetPendingLaporan()
}

func (u *adminUsecase) GetLaporanDetail(id uint) (*domain.LaporanDetail, error) {
	return u.adminRepo.GetLaporanDetail(id)
}

func (u *adminUsecase) ApproveLaporan(laporanID uint, poin int, pelanggaran string) error {
	if poin <= 0 {
		return errors.New("poin harus lebih besar dari 0")
	}
	if pelanggaran == "" {
		return errors.New("jenis pelanggaran wajib diisi")
	}
	return u.adminRepo.ApproveLaporan(laporanID, poin, pelanggaran)
}

func (u *adminUsecase) RejectLaporan(laporanID uint) error {
	return u.adminRepo.RejectLaporan(laporanID)
}

func (u *adminUsecase) CreateLaporan(petugasID uint, targetIdentifier, jenisKendaraan, deskripsi, buktiFoto string) error {
	if targetIdentifier == "" {
		return errors.New("target identifier wajib diisi")
	}
	laporan := &domain.LaporanPetugas{
		IDPetugas:            petugasID,
		TargetIdentifier:     targetIdentifier,
		DeskripsiPelanggaran: deskripsi,
		BuktiFoto:            buktiFoto,
		Status:               "pending",
	}
	return u.adminRepo.CreateLaporan(laporan, jenisKendaraan)
}

func (u *adminUsecase) UpdateUserAdmin(userID uint, nama, nim string, roleID uint, status, nomorPolisi, jenisKendaraan string) error {
	if nama == "" {
		return errors.New("nama wajib diisi")
	}
	if status == "" {
		status = "active"
	}
	return u.adminRepo.UpdateUserAdmin(userID, nama, nim, roleID, status, nomorPolisi, jenisKendaraan)
}
