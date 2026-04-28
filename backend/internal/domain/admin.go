package domain

import "time"

// DashboardStats represents KPI metrics for the admin dashboard
type DashboardStats struct {
	TotalCapacity   int `json:"total_capacity"`
	AvailableSlots  int `json:"available_slots"`
	ActiveVehicles  int `json:"active_vehicles"`
	RegisteredUsers int `json:"registered_users"`
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

// BlacklistItem represents a user with accumulated penalty points > threshold
type BlacklistItem struct {
	UserID         uint   `json:"user_id"`
	Name           string `json:"name"`
	Email          string `json:"email"`
	Role           string `json:"role"`
	TotalPoin      int    `json:"total_poin"`
	JumlahKasus    int    `json:"jumlah_kasus"`
	NomorPolisi    string `json:"nomor_polisi"`
	AlasanTerakhir string `json:"alasan_terakhir"`
	StatusHukuman  string `json:"status_hukuman"`
}

// AdminRepository interface defines methods for admin data access
type AdminRepository interface {
	GetDashboardStats() (*DashboardStats, error)
	GetAllUsers() ([]AdminUserItem, error)
	GetAllActivities() ([]AdminActivityItem, error)
	DeleteUser(userID uint) error
	UpdateUserRole(userID uint, newRole string) error
	GetBlacklistedUsers() ([]BlacklistItem, error)
	ForceExitActivity(activityID uint) error
	AddPenalty(userID uint, poin int, keterangan string) error
	RemovePenalty(userID uint) error
}

// AdminUsecase interface defines standard business logic methods
type AdminUsecase interface {
	GetDashboardData() (*DashboardStats, error)
	GetUsersList() ([]AdminUserItem, error)
	GetActivityLogs() ([]AdminActivityItem, error)
	DeleteUser(userID uint) error
	UpdateUserRole(userID uint, newRole string) error
	GetBlacklist() ([]BlacklistItem, error)
	ForceExitActivity(activityID uint) error
	AddPenalty(userID uint, poin int, keterangan string) error
	RemovePenalty(userID uint) error
}
