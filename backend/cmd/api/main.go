package main

import (
	"log"
	"os"
	"strings"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	deliveryHTTP "github.com/rahmatnug/parkir-kampus-backend/internal/delivery/http"
	deliveryWS "github.com/rahmatnug/parkir-kampus-backend/internal/delivery/websocket"
	"github.com/rahmatnug/parkir-kampus-backend/internal/repository"
	"github.com/rahmatnug/parkir-kampus-backend/internal/usecase"
	"github.com/rahmatnug/parkir-kampus-backend/internal/cron"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/database"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/redis"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found or error loading it, relying on system environment variables")
	}

	// Initialize database
	db := database.ConnectDB()
	log.Println("Database initialized")

	// Initialize Redis
	redis.InitRedis()
	log.Println("Redis initialized")

	// ─── Repository layer ────────────────────────────────────────────────
	userRepo := repository.NewUserRepository(db)
	adminRepo := repository.NewAdminRepository(db)
	reportRepo := repository.NewReportRepository(db)
	parkingRepo := repository.NewParkingRepository(db)

	// ─── WebSocket Hub ──────────────────────────────────────────────────
	wsHub := deliveryWS.NewHub()
	go wsHub.Run()
	log.Println("WebSocket hub started")

	// ─── Usecase layer ──────────────────────────────────────────────────
	userUsecase := usecase.NewUserUsecase(userRepo)
	adminUsecase := usecase.NewAdminUsecase(adminRepo, wsHub)
	reportUsecase := usecase.NewReportUsecase(reportRepo)
	parkingUsecase := usecase.NewParkingUsecase(parkingRepo, userRepo, wsHub)

	// ─── Cron Jobs ──────────────────────────────────────────────────────
	cronJob := cron.NewCronJob(parkingRepo)
	cronJob.Init()

	// ─── Gin router ─────────────────────────────────────────────────────
	r := gin.Default()

	// ─── CORS Middleware ──────────────────────────────────────────────────────
	// In production, set CORS_ORIGINS env var to restrict allowed origins.
	// Example: CORS_ORIGINS=https://parkir.kampus.ac.id,https://admin.parkir.kampus.ac.id
	// If CORS_ORIGINS is not set, falls back to allow all (development mode).
	corsOrigins := os.Getenv("CORS_ORIGINS")
	corsConfig := cors.Config{
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: false,
	}
	if corsOrigins != "" {
		// Production: only allow specified origins
		origins := strings.Split(corsOrigins, ",")
		for i := range origins {
			origins[i] = strings.TrimSpace(origins[i])
		}
		corsConfig.AllowOrigins = origins
		log.Printf("CORS restricted to: %v", origins)
	} else {
		// Development: allow all
		corsConfig.AllowAllOrigins = true
		log.Println("CORS: AllowAllOrigins=true (development mode)")
	}
	r.Use(cors.New(corsConfig))
	// ─────────────────────────────────────────────────────────────────────────

	// ─── HTTP handlers ──────────────────────────────────────────────────
	deliveryHTTP.NewUserHandler(r, userUsecase)
	deliveryHTTP.NewAdminHandler(r, adminUsecase)
	deliveryHTTP.NewReportHandler(r, reportUsecase)
	deliveryHTTP.NewParkingHandler(r, parkingUsecase)

	// ─── WebSocket handler ──────────────────────────────────────────────
	deliveryWS.NewWSHandler(r, wsHub)

	// ─── Health check ───────────────────────────────────────────────────
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	log.Println("Server mapping to port :8080")
	log.Println("WebSocket endpoint: GET /api/v1/ws/connect?token=X")
	log.Println("Report endpoints:   GET /api/v1/reports/{daily,analytical,audit}")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
