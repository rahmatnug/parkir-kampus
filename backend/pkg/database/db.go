package database

import (
	"fmt"
	"log"
	"os"

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
	log.Println("Database seeding successful")
}

