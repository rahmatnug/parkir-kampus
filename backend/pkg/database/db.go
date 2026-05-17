package database

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// ConnectDB establishes a connection to the PostgreSQL database
func ConnectDB() *gorm.DB {
	if err := godotenv.Load(); err != nil {
		log.Println("Peringatan: File .env tidak ditemukan, menggunakan variabel sistem")
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=Asia/Jakarta",
		os.Getenv("DB_HOST"), os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"), os.Getenv("DB_PORT"), os.Getenv("DB_SSLMODE"))

	db, err := gorm.Open(postgres.New(postgres.Config{
		DSN:                  dsn,
		PreferSimpleProtocol: true, // Diperlukan untuk Supabase Transaction Pooler (PgBouncer)
	}), &gorm.Config{})
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
		&domain.WaitingList{},
		&domain.Penalti{},
		&domain.Blacklist{},
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
		{ID: 4, NamaRole: "staff", Prioritas: 4},
		{ID: 5, NamaRole: "tamu", Prioritas: 5},
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

	// Seed Slots with spatial coordinates for dynamic map rendering
	type slotSeed struct {
		ZonaID uint
		Nomor  string
		X      float64
		Y      float64
	}
	slotSeeds := []slotSeed{
		// Zone A — Parkir Utama Depan (left side of map)
		{1, "A-01", 30, 40},
		{1, "A-02", 30, 80},
		{1, "A-03", 30, 120},
		{1, "A-04", 30, 160},
		{1, "A-05", 80, 40},
		{1, "A-06", 80, 80},
		{1, "A-07", 80, 120},
		{1, "A-08", 80, 160},
		// Zone B — Parkir Gedung B (center of map)
		{2, "B-01", 160, 40},
		{2, "B-02", 160, 80},
		{2, "B-03", 160, 120},
		{2, "B-04", 160, 160},
		{2, "B-05", 210, 40},
		{2, "B-06", 210, 80},
		// Zone C — Parkir Belakang (right side of map)
		{3, "C-01", 300, 40},
		{3, "C-02", 300, 80},
		{3, "C-03", 300, 120},
		{3, "C-04", 300, 160},
	}

	for _, s := range slotSeeds {
		slot := domain.SlotParkir{
			ZonaID:    s.ZonaID,
			NomorSlot: s.Nomor,
			Status:    "available",
			XCoord:    s.X,
			YCoord:    s.Y,
		}
		db.Where(domain.SlotParkir{NomorSlot: s.Nomor, ZonaID: s.ZonaID}).FirstOrCreate(&slot)
		// Update coordinates if slot already exists but coords are 0
		db.Model(&domain.SlotParkir{}).
			Where("nomor_slot = ? AND id_zona = ? AND x_coord = 0 AND y_coord = 0", s.Nomor, s.ZonaID).
			Updates(map[string]interface{}{"x_coord": s.X, "y_coord": s.Y})
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

	// Seed Transaksi — use valid slot IDs from seeded slots
	var txCount int64
	db.Model(&domain.Transaksi{}).Count(&txCount)
	if txCount == 0 {
		// Find real slot IDs to avoid FK constraint errors
		var slotA1 domain.SlotParkir
		if err := db.Where("nomor_slot = ? AND id_zona = ?", "A-01", zones[0].IDZona).First(&slotA1).Error; err == nil {
			importTime1 := time.Now().Add(-2 * time.Hour)
			db.Create(&domain.Transaksi{
				UserID:      mahasiswaUser.ID,
				KendaraanID: k1.IDKendaraan,
				SlotID:      slotA1.IDSlot,
				WaktuMasuk:  importTime1,
				Status:      "parkir",
			})

			importTime2 := time.Now().Add(-5 * time.Hour)
			checkoutTime2 := time.Now().Add(-1 * time.Hour)
			var slotA2 domain.SlotParkir
			if err := db.Where("nomor_slot = ? AND id_zona = ?", "A-02", zones[0].IDZona).First(&slotA2).Error; err == nil {
				db.Create(&domain.Transaksi{
					UserID:      dosenUser.ID,
					KendaraanID: k2.IDKendaraan,
					SlotID:      slotA2.IDSlot,
					WaktuMasuk:  importTime2,
					WaktuKeluar: &checkoutTime2,
					Status:      "selesai",
				})
			}
		}
	}

	log.Println("Database seeding successful")
}

