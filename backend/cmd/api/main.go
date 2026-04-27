package main

import (
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	deliveryHTTP "github.com/rahmatnug/parkir-kampus-backend/internal/delivery/http"
	deliveryWS "github.com/rahmatnug/parkir-kampus-backend/internal/delivery/websocket"
	"github.com/rahmatnug/parkir-kampus-backend/internal/repository"
	"github.com/rahmatnug/parkir-kampus-backend/internal/usecase"
	"github.com/rahmatnug/parkir-kampus-backend/internal/cron"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/database"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/redis"
)

func main() {
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

	// ─── Usecase layer ──────────────────────────────────────────────────
	userUsecase := usecase.NewUserUsecase(userRepo)
	adminUsecase := usecase.NewAdminUsecase(adminRepo)
	reportUsecase := usecase.NewReportUsecase(reportRepo)
	parkingUsecase := usecase.NewParkingUsecase(parkingRepo, userRepo)

	// ─── WebSocket Hub ──────────────────────────────────────────────────
	wsHub := deliveryWS.NewHub()
	go wsHub.Run()
	log.Println("WebSocket hub started")

	// ─── Cron Jobs ──────────────────────────────────────────────────────
	cronJob := cron.NewCronJob(parkingRepo)
	cronJob.Init()

	// ─── Gin router ─────────────────────────────────────────────────────
	r := gin.Default()

	// ─── CORS Middleware ──────────────────────────────────────────────────────
	// Allow all origins so Flutter Web / Mobile can reach the API.
	// Tighten this to specific origins in production.
	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: false,
	}))
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
