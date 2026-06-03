package http

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

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
		protected.GET("/profile", handler.GetProfile)
		protected.PUT("/profile", handler.UpdateKendaraan) // Alias
		protected.PUT("/change-password", handler.ChangePassword)
		protected.POST("/avatar", handler.UploadAvatar)
		protected.PUT("/kendaraan", handler.UpdateKendaraan)
	}
}

// GetProfile handler
func (a *UserHandler) GetProfile(c *gin.Context) {
	userID := c.MustGet("id_user").(uint)

	user, err := a.UserUsecase.GetProfile(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"user":   user,
		"role_id": user.RoleID,
	})
}

func (a *UserHandler) UpdateKendaraan(c *gin.Context) {
	userID := c.MustGet("id_user").(uint)

	var input struct {
		IDKendaraan    uint   `json:"id_kendaraan" binding:"required"`
		NomorPolisi    string `json:"nomor_polisi" binding:"required"`
		JenisKendaraan string `json:"jenis_kendaraan" binding:"required"`
		Warna          string `json:"warna"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := a.UserUsecase.UpdateKendaraan(userID, input.IDKendaraan, input.NomorPolisi, input.JenisKendaraan, input.Warna); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Kendaraan berhasil diperbarui",
	})
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
		Role           string `json:"role"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := a.UserUsecase.Register(input.Nama, input.Nim, input.Email, input.Password, input.PlatNomor, input.JenisKendaraan, input.Role)
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
		"role_id": user.RoleID,
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

// UploadAvatar handles multipart file upload to Supabase Storage
func (a *UserHandler) UploadAvatar(c *gin.Context) {
	userID := c.MustGet("id_user").(uint)

	// 1. Get the uploaded file
	file, header, err := c.Request.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "File avatar tidak ditemukan: " + err.Error()})
		return
	}
	defer file.Close()

	// 2. Validate file type
	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format file tidak didukung. Gunakan JPG, PNG, atau WebP."})
		return
	}

	// 3. Validate file size (max 5MB)
	if header.Size > 5*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Ukuran file maksimal 5MB."})
		return
	}

	// 4. Read file bytes
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal membaca file"})
		return
	}

	// 5. Generate unique filename
	filename := fmt.Sprintf("avatars/%d_%d%s", userID, time.Now().UnixMilli(), ext)

	// 6. Upload to Supabase Storage via REST API
	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_SERVICE_KEY")

	if supabaseURL == "" || supabaseKey == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Supabase Storage belum dikonfigurasi"})
		return
	}

	uploadURL := fmt.Sprintf("%s/storage/v1/object/avatars/%s", supabaseURL, filename)

	req, err := http.NewRequest("POST", uploadURL, bytes.NewReader(fileBytes))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal membuat request upload"})
		return
	}

	// Determine content type
	contentType := "image/jpeg"
	switch ext {
	case ".png":
		contentType = "image/png"
	case ".webp":
		contentType = "image/webp"
	}

	req.Header.Set("Authorization", "Bearer "+supabaseKey)
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("x-upsert", "true") // Overwrite if exists

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengunggah ke storage: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Storage upload gagal: " + string(body)})
		return
	}

	// 7. Construct public URL
	publicURL := fmt.Sprintf("%s/storage/v1/object/public/avatars/%s", supabaseURL, filename)

	// 8. Update database
	if err := a.UserUsecase.UpdateProfileImageURL(userID, publicURL); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menyimpan URL: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":            "success",
		"message":           "Foto profil berhasil diunggah",
		"profile_image_url": publicURL,
	})
}

