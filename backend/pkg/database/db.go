package database

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// ConnectDB establishes a connection to the PostgreSQL database
func ConnectDB() *gorm.DB {
	host := os.Getenv("DB_HOST")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")
	port := os.Getenv("DB_PORT")

	if host == "" {
		host = "localhost"
	}
	if user == "" {
		user = "admin"
	}
	if password == "" {
		password = "password123"
	}
	if dbname == "" {
		dbname = "parkirkampus"
	}
	if port == "" {
		port = "5432"
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		host, user, password, dbname, port)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	log.Println("Database connection successful")

	// AutoMigrate
	err = db.AutoMigrate(
		&domain.Role{},
		&domain.User{},
		&domain.Kendaraan{},
		&domain.ZonaParkir{},
		&domain.SlotParkir{},
		&domain.Transaksi{},
	)
	if err != nil {
		log.Fatalf("Failed to automigrate: %v", err)
	}

	log.Println("Database migration successful")

	SeedData(db)

	return db
}

// SeedData inserts default roles and the initial admin user
func SeedData(db *gorm.DB) {
	roles := []domain.Role{
		{ID: 1, NamaRole: "admin", Prioritas: 1},
		{ID: 2, NamaRole: "dosen", Prioritas: 2},
		{ID: 3, NamaRole: "mahasiswa", Prioritas: 3},
	}

	for _, role := range roles {
		// Use FirstOrCreate to ensure we don't duplicate
		db.Where(domain.Role{NamaRole: role.NamaRole}).FirstOrCreate(&role)
	}

	// Default Admin User
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	adminUser := domain.User{
		RoleID:       1, // admin
		Nama:         "Admin Sistem",
		Email:        "admin@parkir.com",
		PasswordHash: string(hashedPassword),
		Status:       "active",
	}

	db.Where(domain.User{Email: adminUser.Email}).FirstOrCreate(&adminUser)

	// Seed Dummy Users
	mahasiswaUser := domain.User{
		RoleID:       3,
		Nama:         "Budi Santoso",
		Email:        "budi@univ.ac.id",
		PasswordHash: string(hashedPassword),
		Status:       "active",
	}
	db.Where(domain.User{Email: mahasiswaUser.Email}).FirstOrCreate(&mahasiswaUser)

	dosenUser := domain.User{
		RoleID:       2,
		Nama:         "Dr. Hendra",
		Email:        "hendra@univ.ac.id",
		PasswordHash: string(hashedPassword),
		Status:       "active",
	}
	db.Where(domain.User{Email: dosenUser.Email}).FirstOrCreate(&dosenUser)

	// Seed Zoning
	zones := []domain.ZonaParkir{
		{IDZona: 1, NamaZona: "Zone A", Deskripsi: "Parkir Utama Depan", Kapasitas: 50, Status: "active"},
		{IDZona: 2, NamaZona: "Zone B", Deskripsi: "Parkir Gedung B", Kapasitas: 40, Status: "active"},
		{IDZona: 3, NamaZona: "Zone C", Deskripsi: "Parkir Belakang", Kapasitas: 30, Status: "active"},
	}
	for i, z := range zones {
		db.Where(domain.ZonaParkir{NamaZona: z.NamaZona}).FirstOrCreate(&zones[i])
	}

	// Seed Kendaraan
	k1 := domain.Kendaraan{
		UserID:         mahasiswaUser.ID,
		NomorPolisi:    "B 1234 ABC",
		JenisKendaraan: "motor",
		Warna:          "Hitam",
	}
	db.Where(domain.Kendaraan{NomorPolisi: k1.NomorPolisi}).FirstOrCreate(&k1)

	k2 := domain.Kendaraan{
		UserID:         dosenUser.ID,
		NomorPolisi:    "D 8888 XYZ",
		JenisKendaraan: "mobil",
		Warna:          "Putih",
	}
	db.Where(domain.Kendaraan{NomorPolisi: k2.NomorPolisi}).FirstOrCreate(&k2)

	// Seed Transaksi
	// Budi is parked
	var txCount int64
	db.Model(&domain.Transaksi{}).Count(&txCount)
	if txCount == 0 {
		importTime1 := time.Now().Add(-2 * time.Hour)
		importTime2 := time.Now().Add(-5 * time.Hour)
		checkoutTime2 := time.Now().Add(-1 * time.Hour)

		db.Create(&domain.Transaksi{
			UserID:      mahasiswaUser.ID,
			KendaraanID: k1.IDKendaraan,
			SlotID:      1, // Dummy slot
			WaktuMasuk:  importTime1,
			Status:      "parkir",
		})

		// Dr. Hendra already completed parking
		db.Create(&domain.Transaksi{
			UserID:      dosenUser.ID,
			KendaraanID: k2.IDKendaraan,
			SlotID:      1,
			WaktuMasuk:  importTime2,
			WaktuKeluar: &checkoutTime2,
			Status:      "selesai",
		})
	}

	log.Println("Database seeding successful")
}

