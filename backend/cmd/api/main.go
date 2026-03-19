package main

import (
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"github.com/rahmatnug/parkir-kampus-backend/internal/delivery/http"
	"github.com/rahmatnug/parkir-kampus-backend/internal/repository"
	"github.com/rahmatnug/parkir-kampus-backend/internal/usecase"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/database"
)

func main() {
	// Initialize database
	db := database.ConnectDB()
	log.Println("Database initialized")

	// Initialize repository, usecase, and handler
	userRepo := repository.NewUserRepository(db)
	userUsecase := usecase.NewUserUsecase(userRepo)

	// Initialize Gin router
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

	http.NewUserHandler(r, userUsecase)

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	log.Println("Server mapping to port :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
