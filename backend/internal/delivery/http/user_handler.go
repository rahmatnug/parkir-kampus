package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

// UserHandler represent the httphandler for user
type UserHandler struct {
	UserUsecase domain.UserUsecase
}

// NewUserHandler will initialize the users/ resources endpoint
func NewUserHandler(r *gin.Engine, us domain.UserUsecase) {
	handler := &UserHandler{
		UserUsecase: us,
	}
	r.POST("/api/register", handler.Register)
	r.POST("/api/login", handler.Login)

	// Protected routes
	protected := r.Group("/api/user")
	protected.Use(AuthMiddleware())
	{
		protected.PUT("/change-password", handler.ChangePassword)
	}
}

// Register handler
func (a *UserHandler) Register(c *gin.Context) {
	var input struct {
		Nama           string `json:"nama" binding:"required"`
		Nim            string `json:"nim"`
		Email          string `json:"email" binding:"required"`
		Password       string `json:"password" binding:"required"`
		PlatNomor      string `json:"plat_nomor"`
		JenisKendaraan string `json:"jenis_kendaraan"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := a.UserUsecase.Register(input.Nama, input.Nim, input.Email, input.Password, input.PlatNomor, input.JenisKendaraan)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "User registered successfully",
		"user":    user,
	})
}

func (a *UserHandler) Login(c *gin.Context) {
	var input struct {
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	token, user, err := a.UserUsecase.Login(input.Email, input.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   token,
		"user":    user,
	})
}

func (a *UserHandler) ChangePassword(c *gin.Context) {
	userID := c.MustGet("id_user").(uint)

	var input struct {
		CurrentPassword string `json:"current_password" binding:"required"`
		NewPassword     string `json:"new_password" binding:"required,min=8"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := a.UserUsecase.ChangePassword(userID, input.CurrentPassword, input.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Password berhasil diperbarui"})
}
