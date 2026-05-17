package domain

import "time"

// Kendaraan represents the vehicle entity
type Kendaraan struct {
	IDKendaraan    uint      `json:"id_kendaraan" gorm:"primaryKey;column:id_kendaraan;autoIncrement"`
	UserID         uint      `json:"id_user" gorm:"column:id_user;type:bigint"`
	User           User      `json:"-" gorm:"foreignKey:UserID;references:ID"`
	NomorPolisi    string    `json:"nomor_polisi" gorm:"unique;not null;type:varchar(15)"`
	JenisKendaraan string    `json:"jenis_kendaraan" gorm:"type:varchar(20);check:jenis_kendaraan IN ('motor','mobil')"`
	Warna          string    `json:"warna" gorm:"type:varchar(30)"`
	CreatedAt      time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// ZonaParkir represents the parking zone
type ZonaParkir struct {
	IDZona         uint   `json:"id_zona" gorm:"primaryKey;column:id_zona;autoIncrement"`
	NamaZona       string `json:"nama_zona" gorm:"not null;type:varchar(50)"`
	Deskripsi      string `json:"deskripsi" gorm:"type:text"`
	Kapasitas      int    `json:"kapasitas" gorm:"not null;type:integer"`
	JenisKendaraan string `json:"jenis_kendaraan" gorm:"type:varchar(20);default:'motor';check:jenis_kendaraan IN ('motor','mobil')"`
	Status         string `json:"status" gorm:"type:varchar(20);default:'active'"`
}

// SlotParkir represents an individual parking slot
type SlotParkir struct {
	IDSlot    uint       `json:"id_slot" gorm:"primaryKey;column:id_slot;autoIncrement"`
	ZonaID    uint       `json:"id_zona" gorm:"column:id_zona;type:bigint"`
	Zona      ZonaParkir `json:"zona" gorm:"foreignKey:ZonaID;references:IDZona"`
	NomorSlot string     `json:"nomor_slot" gorm:"not null;type:varchar(20)"`
	Status    string     `json:"status" gorm:"type:varchar(20);default:'available'"`
	XCoord    float64    `json:"x_coord" gorm:"column:x_coord;type:float;default:0"`
	YCoord    float64    `json:"y_coord" gorm:"column:y_coord;type:float;default:0"`
}

// Transaksi represents the parking transaction
type Transaksi struct {
	IDTransaksi uint       `json:"id_transaksi" gorm:"primaryKey;column:id_transaksi;autoIncrement"`
	UserID      uint       `json:"id_user" gorm:"column:id_user;type:bigint"`
	User        User       `json:"user" gorm:"foreignKey:UserID;references:ID"`
	KendaraanID uint       `json:"id_kendaraan" gorm:"column:id_kendaraan;type:bigint"`
	Kendaraan   Kendaraan  `json:"kendaraan" gorm:"foreignKey:KendaraanID;references:IDKendaraan"`
	SlotID      uint       `json:"id_slot" gorm:"column:id_slot;type:bigint"`
	Slot        SlotParkir `json:"slot" gorm:"foreignKey:SlotID;references:IDSlot"`
	WaktuMasuk  time.Time  `json:"waktu_masuk" gorm:"not null;type:timestamp"`
	WaktuKeluar *time.Time `json:"waktu_keluar" gorm:"type:timestamp"`
	Status      string     `json:"status" gorm:"type:varchar(20);default:'parkir'"`
}

// WaitingList represents the waiting list entity
type WaitingList struct {
	IDWaiting       uint      `json:"id_waiting" gorm:"primaryKey;column:id_waiting;autoIncrement"`
	UserID          uint      `json:"id_user" gorm:"column:id_user;type:bigint"`
	User            User      `json:"user" gorm:"foreignKey:UserID;references:ID"`
	ZonaID          uint      `json:"id_zona" gorm:"column:id_zona;type:smallint"`
	Zona            ZonaParkir `json:"zona" gorm:"foreignKey:ZonaID;references:IDZona"`
	WaktuPermohonan time.Time `json:"waktu_permohonan" gorm:"column:waktu_permohonan;autoCreateTime"`
	PosisiAntrian   int       `json:"posisi_antrian" gorm:"column:posisi_antrian;not null;type:integer"`
}

func (WaitingList) TableName() string { return "waiting_lists" }

// Penalti represents the penalty entity
type Penalti struct {
	IDPenalti        uint      `json:"id_penalti" gorm:"primaryKey;column:id_penalti;autoIncrement"`
	UserID           uint      `json:"id_user" gorm:"column:id_user;type:bigint"`
	User             User      `json:"user" gorm:"foreignKey:UserID;references:ID"`
	JenisPelanggaran string    `json:"jenis_pelanggaran" gorm:"column:jenis_pelanggaran;type:varchar(100)"`
	PoinPenalti      int       `json:"poin_penalti" gorm:"column:poin_penalti;type:integer"`
	Tanggal          time.Time `json:"tanggal" gorm:"column:tanggal;autoCreateTime"`
}

func (Penalti) TableName() string { return "penaltis" }

// Blacklist represents the blacklist table
type Blacklist struct {
	IDBlacklist    uint       `json:"id_blacklist" gorm:"primaryKey;column:id_blacklist;autoIncrement"`
	UserID         uint       `json:"id_user" gorm:"column:id_user;type:bigint"`
	User           User       `json:"user" gorm:"foreignKey:UserID;references:ID"`
	Alasan         string     `json:"alasan" gorm:"column:alasan;type:text"`
	TanggalMulai   time.Time  `json:"tanggal_mulai" gorm:"column:tanggal_mulai;type:timestamp"`
	TanggalSelesai *time.Time `json:"tanggal_selesai" gorm:"column:tanggal_selesai;type:timestamp"`
	Status         string     `json:"status" gorm:"column:status;type:varchar(20);default:'active'"`
}

func (Blacklist) TableName() string { return "blacklists" }

// ParkingRepository defines the methods for parking data access
type ParkingRepository interface {
	GetAvailableSlotWithLock(zonaID uint) (*SlotParkir, error)
	CreateTransaksi(tx *Transaksi) error
	GetActiveTransaksi(userID uint) (*Transaksi, error)
	UpdateTransaksi(tx *Transaksi) error
	UpdateSlotStatus(slotID uint, status string) error
	GetSlotByID(slotID uint) (*SlotParkir, error)
	CountAvailableSlots(zonaID uint) (int64, error)
	CreatePenalti(p *Penalti) error
	FindInParkTransactions() ([]Transaksi, error)
	GetZoneByID(zonaID uint) (*ZonaParkir, error)
	GetZoneByCode(code string) (*ZonaParkir, error)
	GetUserKendaraan(userID uint) (*Kendaraan, error)
	GetTotalPenaltyPoints(userID uint) (int, error)
	BookSlotAndCreateTransaction(userID uint, kendaraanID uint, zonaID uint) (*Transaksi, *SlotParkir, error)
	ReleaseSlotAndUpdateTransaction(userID uint) (*Transaksi, error)
	GetAllZonesPublic() ([]ZonaParkir, error)
	GetSlotsByZone(zonaID uint) ([]SlotParkir, error)
	GetUserHistory(userID uint) ([]Transaksi, error)
	GetUserAlerts(userID uint) ([]Penalti, error)
}

// ParkingEntryResult holds the outcome of a successful scan entry
type ParkingEntryResult struct {
	TransaksiID uint    `json:"id_transaksi"`
	NomorSlot   string  `json:"nomor_slot"`
	NamaZona    string  `json:"nama_zona"`
	Status      string  `json:"status"`
	XCoord      float64 `json:"x_coord"`
	YCoord      float64 `json:"y_coord"`
}

// ZoneStatus holds public occupancy info for a parking zone (used on the user dashboard)
type ZoneStatus struct {
	ID             uint    `json:"id"`
	Nama           string  `json:"nama"`
	KapasitasMaks  int     `json:"kapasitas_maksimal"`
	Terisi         int     `json:"terisi_saat_ini"`
	JenisKendaraan string  `json:"jenis_kendaraan"`
	XCoord         float64 `json:"x_coord"`
	YCoord         float64 `json:"y_coord"`
}

// ParkingUsecase defines the business logic for parking
type ParkingUsecase interface {
	TapIn(userID uint, kendaraanID uint, zonaID uint) (*Transaksi, string, error)
	TapOut(userID uint) (*Transaksi, error)
	AssignSlotFromWaitlist(zonaID uint) error
	ProcessParkingEntry(userID uint, qrCode string) (*ParkingEntryResult, error)
	ProcessParkingExit(userID uint) (*Transaksi, error)
	GetUserHistory(userID uint) ([]Transaksi, error)
	GetUserAlerts(userID uint) ([]Penalti, error)
	GetCurrentParking(userID uint) (*ParkingEntryResult, error)
	GetParkingStatus() ([]ZoneStatus, error)
}
