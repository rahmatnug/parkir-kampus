package domain

import "time"

// Kendaraan represents the vehicle entity
type Kendaraan struct {
	IDKendaraan    uint      `json:"id_kendaraan" gorm:"primaryKey;column:id_kendaraan;autoIncrement"`
	UserID         uint      `json:"id_user" gorm:"column:id_user;type:bigint"`
	User           User      `json:"user" gorm:"foreignKey:UserID;references:ID"`
	NomorPolisi    string    `json:"nomor_polisi" gorm:"unique;not null;type:varchar(15)"`
	JenisKendaraan string    `json:"jenis_kendaraan" gorm:"type:varchar(20);check:jenis_kendaraan IN ('motor','mobil')"`
	Warna          string    `json:"warna" gorm:"type:varchar(30)"`
	CreatedAt      time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// ZonaParkir represents the parking zone
type ZonaParkir struct {
	IDZona    uint   `json:"id_zona" gorm:"primaryKey;column:id_zona;autoIncrement"`
	NamaZona  string `json:"nama_zona" gorm:"not null;type:varchar(50)"`
	Deskripsi string `json:"deskripsi" gorm:"type:text"`
	Kapasitas int    `json:"kapasitas" gorm:"not null;type:integer"`
	Status    string `json:"status" gorm:"type:varchar(20);default:'active'"`
}

// SlotParkir represents an individual parking slot
type SlotParkir struct {
	IDSlot    uint      `json:"id_slot" gorm:"primaryKey;column:id_slot;autoIncrement"`
	ZonaID    uint      `json:"id_zona" gorm:"column:id_zona;type:bigint"`
	Zona      ZonaParkir `json:"zona" gorm:"foreignKey:ZonaID;references:IDZona"`
	NomorSlot string    `json:"nomor_slot" gorm:"not null;type:varchar(20)"`
	Status    string    `json:"status" gorm:"type:varchar(20);default:'available'"`
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
