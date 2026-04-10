package domain

import "time"

// DashboardStats represents KPI metrics for the admin dashboard
type DashboardStats struct {
	TotalCapacity    int `json:"total_capacity"`
	AvailableSlots   int `json:"available_slots"`
	ActiveVehicles   int `json:"active_vehicles"`
	RegisteredUsers  int `json:"registered_users"`
}

// AdminUserItem represents a user in the admin table
type AdminUserItem struct {
	ID        uint      `json:"id"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Role      string    `json:"role"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

// AdminActivityItem represents a parking transaction log
type AdminActivityItem struct {
	IDTransaksi uint       `json:"id_transaksi"`
	UserName    string     `json:"user_name"`
	Role        string     `json:"role"`
	NomorPolisi string     `json:"nomor_polisi"`
	Jenis       string     `json:"jenis_kendaraan"`
	Zona        string     `json:"zona"`
	WaktuMasuk  time.Time  `json:"waktu_masuk"`
	WaktuKeluar *time.Time `json:"waktu_keluar"`
	Status      string     `json:"status"`
}

// AdminRepository interface defines methods for admin data access
type AdminRepository interface {
	GetDashboardStats() (*DashboardStats, error)
	GetAllUsers() ([]AdminUserItem, error)
	GetAllActivities() ([]AdminActivityItem, error)
}

// AdminUsecase interface defines standard business logic methods
type AdminUsecase interface {
	GetDashboardData() (*DashboardStats, error)
	GetUsersList() ([]AdminUserItem, error)
	GetActivityLogs() ([]AdminActivityItem, error)
}
