package domain

import "time"

// DashboardStats represents KPI metrics for the admin dashboard
type DashboardStats struct {
	TotalCapacity   int `json:"total_capacity"`
	AvailableSlots  int `json:"available_slots"`
	ActiveVehicles  int `json:"active_vehicles"`
	RegisteredUsers int `json:"registered_users"`
}

// BlacklistStats represents KPI for Blacklist page
type BlacklistStats struct {
	TotalBlacklisted   int `json:"total_blacklisted"`
	ActiveRestrictions int `json:"active_restrictions"`
}

// AdminUserItem represents a user in the admin table
type AdminUserItem struct {
	ID        uint      `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Nim       string    `json:"nim"`
	Role      string    `json:"role"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

// AdminActivityItem represents a parking transaction log
type AdminActivityItem struct {
	IDTransaksi uint       `json:"id_transaksi"`
	UserID      uint       `json:"id_user"`
	UserName    string     `json:"user_name"`
	Role        string     `json:"role"`
	NomorPolisi string     `json:"nomor_polisi"`
	Jenis       string     `json:"jenis_kendaraan"`
	Zona        string     `json:"zona"`
	WaktuMasuk  time.Time  `json:"waktu_masuk"`
	WaktuKeluar *time.Time `json:"waktu_keluar"`
	Status      string     `json:"status"`
}

type BlacklistItem struct {
	NamaUser            string `json:"nama_user"`
	Nim                 string `json:"nim"`
	AvatarUrl           string `json:"avatar_url"`
	NamaRole            string `json:"nama_role"`
	NomorPolisi         string `json:"nomor_polisi"`
	TotalPoin           int    `json:"total_poin"`
	JumlahKasus         int    `json:"jumlah_kasus"`
	PelanggaranTerakhir string `json:"pelanggaran_terakhir"`
	StatusPeringatan    string `json:"status_peringatan"`
}

type PendingLaporanItem struct {
	IDLaporan       uint      `json:"id_laporan"`
	TipePelanggaran string    `json:"tipe_pelanggaran"`
	NomorPolisi     string    `json:"nomor_polisi"`
	NamaPetugas     string    `json:"nama_petugas"`
	CreatedAt       time.Time `json:"created_at"`
}

// ZoneWithSlots is a read-model returned when listing zones with their slot counts
type ZoneWithSlots struct {
	IDZona         uint   `json:"id_zona"`
	NamaZona       string `json:"nama_zona"`
	Deskripsi      string `json:"deskripsi"`
	KapasitasMotor int    `json:"kapasitas_motor"`
	KapasitasMobil int    `json:"kapasitas_mobil"`
	Status         string `json:"status"`
	TotalSlots     int    `json:"total_slots"`
	AvailableSlots int    `json:"available_slots"`
}

// AdminRepository interface defines methods for admin data access
type AdminRepository interface {
	GetDashboardStats() (*DashboardStats, error)
	GetAllUsers() ([]AdminUserItem, error)
	GetAllActivities() ([]AdminActivityItem, error)
	DeleteUser(userID uint) error
	UpdateUserRole(userID uint, newRole string) error
	UpdateUserStatus(userID uint, newStatus string) error
	GetBlacklistedUsers() ([]BlacklistItem, error)
	GetBlacklistStats() (*BlacklistStats, error)
	ForceExitActivity(activityID uint) error
	AddPenalty(userID uint, poin int, keterangan string) error
	RemovePenalty(userID uint) error
	GetLaporanDetail(id uint) (*LaporanDetail, error)
	ApproveLaporan(laporanID uint, poin int, pelanggaran string) error
	RejectLaporan(laporanID uint) error
	GetPendingLaporan() ([]PendingLaporanItem, error)
	HasActiveTransaction(userID uint) (bool, error)
	GetTotalPenaltyPoints(userID uint) (int, error)
	CreateBlacklist(userID uint, alasan string) error
	CreateLaporan(laporan *LaporanPetugas, jenisKendaraan string) error
	UpdateUserAdmin(userID uint, nama, nim string, roleID uint, status, nomorPolisi, jenisKendaraan string) error
	GetUserByID(userID uint) (*User, error)

	// Zone CRUD
	CreateZone(zone *ZonaParkir) error
	GetAllZones() ([]ZoneWithSlots, error)
	UpdateZone(zone *ZonaParkir) error
	DeleteZone(zonaID uint) error
	FindZoneByName(name string) (*ZonaParkir, error)

	// Slot CRUD
	CreateSlot(slot *SlotParkir) error
	GetSlotsByZone(zonaID uint) ([]SlotParkir, error)
	DeleteSlot(slotID uint) error
}

// AdminUsecase interface defines standard business logic methods
type AdminUsecase interface {
	GetDashboardData() (*DashboardStats, error)
	GetUsersList() ([]AdminUserItem, error)
	GetActivityLogs() ([]AdminActivityItem, error)
	DeleteUser(userID uint) error
	UpdateUserRole(userID uint, newRole string) error
	UpdateUserStatus(userID uint, newStatus string) error
	GetBlacklist() ([]BlacklistItem, error)
	GetBlacklistStats() (*BlacklistStats, error)
	ForceExitActivity(activityID uint) error
	AddPenalty(userID uint, poin int, keterangan string) error
	RemovePenalty(userID uint) error
	GetLaporanDetail(id uint) (*LaporanDetail, error)
	ApproveLaporan(laporanID uint, poin int, pelanggaran string) error
	RejectLaporan(laporanID uint) error
	GetPendingLaporan() ([]PendingLaporanItem, error)
	CreateLaporan(petugasID uint, targetIdentifier, jenisKendaraan, deskripsi, buktiFoto string) error
	UpdateUserAdmin(userID uint, nama, nim string, roleID uint, status, nomorPolisi, jenisKendaraan string) error
	GetUserByID(userID uint) (*User, error)

	// Zone CRUD
	CreateZone(namaZona string, deskripsi string, kapasitasMotor int, kapasitasMobil int) (uint, error)
	GetAllZones() ([]ZoneWithSlots, error)
	UpdateZone(zonaID uint, namaZona string, deskripsi string, kapasitasMotor int, kapasitasMobil int) error
	DeleteZone(zonaID uint) error

	// Slot CRUD
	CreateSlot(zonaID uint, nomorSlot string) error
	GetSlotsByZone(zonaID uint) ([]SlotParkir, error)
	DeleteSlot(slotID uint) error
}
