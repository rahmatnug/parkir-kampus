//go:build ignore
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type User struct {
	ID   uint   `gorm:"primaryKey;column:id_user"`
	Nama string `gorm:"column:nama"`
}
func (User) TableName() string { return "users" }

type LaporanPetugas struct {
	IDLaporan            uint      `gorm:"primaryKey;column:id_laporan"`
	IDPetugas            uint      `gorm:"column:id_petugas"`
	Petugas              User      `gorm:"foreignKey:IDPetugas;references:ID"`
	TargetIdentifier     string    `gorm:"column:target_identifier"`
	DeskripsiPelanggaran string    `gorm:"column:deskripsi_pelanggaran"`
	Status               string    `gorm:"column:status"`
	CreatedAt            time.Time `gorm:"column:created_at"`
}
func (LaporanPetugas) TableName() string { return "laporan_petugases" }

type PendingLaporanItem struct {
	IDLaporan       uint      `json:"id_laporan"`
	TipePelanggaran string    `json:"tipe_pelanggaran"`
	NomorPolisi     string    `json:"nomor_polisi"`
	NamaPetugas     string    `json:"nama_petugas"`
	CreatedAt       time.Time `json:"created_at"`
}

func main() {
	dsn := "host=aws-1-ap-southeast-1.pooler.supabase.com user=postgres.zickrkvvpptchymushfb password=Adminkitaa123 dbname=postgres port=5432 sslmode=require"
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}

	var results []PendingLaporanItem
	var laporans []LaporanPetugas

	err = db.Preload("Petugas").
		Where("status IN ?", []string{"pending", "menunggu review"}).
		Order("created_at DESC").
		Find(&laporans).Error
	if err != nil {
		log.Fatal(err)
	}

	for _, l := range laporans {
		results = append(results, PendingLaporanItem{
			IDLaporan:       l.IDLaporan,
			TipePelanggaran: l.DeskripsiPelanggaran,
			NomorPolisi:     l.TargetIdentifier,
			NamaPetugas:     l.Petugas.Nama,
			CreatedAt:       l.CreatedAt,
		})
	}

	b, _ := json.MarshalIndent(results, "", "  ")
	fmt.Println(string(b))
}
