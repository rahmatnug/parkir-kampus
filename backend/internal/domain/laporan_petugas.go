package domain

import "time"

// LaporanPetugas represents the field reporting entity submitted by petugas
type LaporanPetugas struct {
	IDLaporan            uint      `json:"id_laporan" gorm:"primaryKey;column:id_laporan;autoIncrement"`
	IDPetugas            uint      `json:"id_petugas" gorm:"column:id_petugas;type:bigint"`
	Petugas              User      `json:"petugas" gorm:"foreignKey:IDPetugas;references:ID"`
	TargetIdentifier     string    `json:"target_identifier" gorm:"column:target_identifier;type:varchar(100);not null"`
	DeskripsiPelanggaran string    `json:"deskripsi_pelanggaran" gorm:"column:deskripsi_pelanggaran;type:text;not null"`
	Status               string    `json:"status" gorm:"column:status;type:varchar(20);default:'pending'"`
	CreatedAt            time.Time `json:"created_at" gorm:"column:created_at;type:timestamp with time zone;autoCreateTime"`
}

// TableName overrides the table name for GORM to laporan_petugases
func (LaporanPetugas) TableName() string { return "laporan_petugases" }
