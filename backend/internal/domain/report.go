package domain

import "time"

// ──────────────────────────────────────────────────────────────────────────────
// Reporting DTOs (read-only, never touch transaction tables for writes)
// All core DB models (WaitingList, Penalti, Blacklist) are in parking.go.
// ──────────────────────────────────────────────────────────────────────────────

// --- Daily Report ---

// ZoneOccupancy is the per-zone occupancy snapshot
type ZoneOccupancy struct {
	IDZona     uint    `json:"id_zona"`
	NamaZona   string  `json:"nama_zona"`
	Kapasitas  int     `json:"kapasitas"`
	Terisi     int     `json:"terisi"`
	Tersedia   int     `json:"tersedia"`
	OkupasiPct float64 `json:"okupansi_persen"`
}

// QueueSnapshot shows the current waiting-list depth per zone
type QueueSnapshot struct {
	IDZona      uint   `json:"id_zona"`
	NamaZona    string `json:"nama_zona"`
	JumlahAntri int    `json:"jumlah_antri"`
}

// DailyReport is the response for GET /api/v1/reports/daily
type DailyReport struct {
	Tanggal             string          `json:"tanggal"`
	OkupasiPerZona      []ZoneOccupancy `json:"okupansi_per_zona"`
	AntrianSaatIni      []QueueSnapshot `json:"antrian_saat_ini"`
	TotalKendaraanMasuk int             `json:"total_kendaraan_masuk"`
}

// --- Analytical Report ---

// AWTPerRole is the Average Wait Time per role
type AWTPerRole struct {
	Role           string  `json:"role"`
	AvgWaitMinutes float64 `json:"avg_wait_minutes"`
}

// HourlyTraffic for the busy-hour chart
type HourlyTraffic struct {
	Jam   int `json:"jam"`
	Total int `json:"total"`
}

// AnalyticalReport is the response for GET /api/v1/reports/analytical
type AnalyticalReport struct {
	StartDate      string          `json:"start_date"`
	EndDate        string          `json:"end_date"`
	AWTPerRole     []AWTPerRole    `json:"awt_per_role"`
	GrafikJamSibuk []HourlyTraffic `json:"grafik_jam_sibuk"`
	TotalKendaraan int             `json:"total_kendaraan"`
}

// --- Audit Report ---

// PenaltyTopUser shows users with the highest penalty points
type PenaltyTopUser struct {
	IDUser      uint   `json:"id_user"`
	Nama        string `json:"nama"`
	Email       string `json:"email"`
	TotalPoin   int    `json:"total_poin"`
	JumlahKasus int    `json:"jumlah_kasus"`
}

// BlacklistRecord is a single blacklist history entry (DTO, not the ORM model)
type BlacklistRecord struct {
	IDBlacklist    uint       `json:"id_blacklist"`
	IDUser         uint       `json:"id_user"`
	Nama           string     `json:"nama"`
	Alasan         string     `json:"alasan"`
	TanggalMulai   time.Time  `json:"tanggal_mulai"`
	TanggalSelesai *time.Time `json:"tanggal_selesai"`
	Status         string     `json:"status"`
}

// IllegalAccessRecord represents an unauthorized access attempt
type IllegalAccessRecord struct {
	IDTransaksi uint      `json:"id_transaksi"`
	IDUser      uint      `json:"id_user"`
	Nama        string    `json:"nama"`
	NomorPolisi string    `json:"nomor_polisi"`
	WaktuMasuk  time.Time `json:"waktu_masuk"`
	Status      string    `json:"status"`
}

// AuditReport is the response for GET /api/v1/reports/audit
type AuditReport struct {
	TopPenaltyUsers  []PenaltyTopUser     `json:"top_penalty_users"`
	RiwayatBlacklist []BlacklistRecord    `json:"riwayat_blacklist"`
	AksesIlegal      []IllegalAccessRecord `json:"akses_ilegal"`
}

// ──────────────────────────────────────────────────────────────────────────────
// Repository & Usecase interfaces for Reporting
// ──────────────────────────────────────────────────────────────────────────────

// ReportRepository defines read-only data access for reports
type ReportRepository interface {
	GetDailyReport() (*DailyReport, error)
	GetAnalyticalReport(startDate, endDate string) (*AnalyticalReport, error)
	GetAuditReport() (*AuditReport, error)
}

// ReportUsecase defines business logic for reporting
type ReportUsecase interface {
	GetDailyReport() (*DailyReport, error)
	GetAnalyticalReport(startDate, endDate string) (*AnalyticalReport, error)
	GetAuditReport() (*AuditReport, error)
}
