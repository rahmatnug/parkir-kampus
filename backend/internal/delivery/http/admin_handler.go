package http

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

type AdminHandler struct {
	AdminUsecase domain.AdminUsecase
}

func NewAdminHandler(r *gin.Engine, us domain.AdminUsecase) {
	handler := &AdminHandler{
		AdminUsecase: us,
	}

	// All admin endpoints are protected by AuthMiddleware + AuthAdminMiddleware
	adminRoutes := r.Group("/api/admin")
	adminRoutes.Use(AuthMiddleware(), AuthAdminMiddleware())
	{
		adminRoutes.GET("/dashboard", handler.GetDashboard)
		adminRoutes.GET("/users", handler.GetUsers)
		adminRoutes.GET("/users/:id", handler.GetUserByID)
		adminRoutes.GET("/activities", handler.GetActivities)
		adminRoutes.DELETE("/users/:id", handler.DeleteUser)
		adminRoutes.PUT("/users/:id", handler.EditUser)
		adminRoutes.PUT("/users/:id/role", handler.UpdateUserRole)
		adminRoutes.GET("/blacklists", handler.GetBlacklist)
		adminRoutes.GET("/blacklist-stats", handler.GetBlacklistStats)
		adminRoutes.POST("/activities/:id/force-exit", handler.ForceExitActivity)
		adminRoutes.POST("/users/:id/penalty", handler.AddPenalty)
		adminRoutes.DELETE("/users/:id/penalty", handler.RemovePenalty)
		adminRoutes.GET("/laporan/pending", handler.GetPendingLaporan)
		adminRoutes.GET("/laporan/:id", handler.GetLaporanDetail)
		adminRoutes.POST("/penalti/approve", handler.ApproveLaporan)
		adminRoutes.PUT("/laporan/:id/reject", handler.RejectLaporan)

		// Zone CRUD
		adminRoutes.POST("/zones", handler.CreateZone)
		adminRoutes.POST("/qr", handler.CreateZone)
		adminRoutes.GET("/zones", handler.GetAllZones)
		adminRoutes.PUT("/zones/:id", handler.UpdateZone)
		adminRoutes.DELETE("/zones/:id", handler.DeleteZone)

		// Slot CRUD
		adminRoutes.POST("/slots", handler.CreateSlot)
		adminRoutes.GET("/zones/:id/slots", handler.GetSlotsByZone)
		adminRoutes.DELETE("/slots/:id", handler.DeleteSlot)
	}

	// Fix for 404 Admin Blacklist API
	adminV1Routes := r.Group("/api/v1")
	adminV1Routes.Use(AuthMiddleware())
	{
		// ToggleBlacklist still uses /admin/users/:id/blacklist
		adminV1Routes.PATCH("/admin/users/:id/blacklist", AuthAdminMiddleware(), handler.ToggleBlacklist)
		adminV1Routes.POST("/report", handler.SubmitReport)
	}
}

// ─── Existing Handlers ──────────────────────────────────────────────────────

func (h *AdminHandler) GetDashboard(c *gin.Context) {
	data, err := h.AdminUsecase.GetDashboardData()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *AdminHandler) GetUsers(c *gin.Context) {
	data, err := h.AdminUsecase.GetUsersList()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"users": data})
}

// GetUserByID handles GET /api/admin/users/:id
// Returns user with kendaraans (for nomor_polisi, jenis_kendaraan pre-filling)
func (h *AdminHandler) GetUserByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID tidak valid"})
		return
	}

	data, err := h.AdminUsecase.GetUserByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "User tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"user": data})
}

func (h *AdminHandler) GetActivities(c *gin.Context) {
	data, err := h.AdminUsecase.GetActivityLogs()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"activities": data})
}

// DeleteUser handles DELETE /api/admin/users/:id
func (h *AdminHandler) DeleteUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID tidak valid"})
		return
	}

	if err := h.AdminUsecase.DeleteUser(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "User berhasil dihapus"})
}

// UpdateUserRole handles PUT /api/admin/users/:id/role
func (h *AdminHandler) UpdateUserRole(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID tidak valid"})
		return
	}

	var input struct {
		Role string `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.UpdateUserRole(uint(id), input.Role); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Role berhasil diperbarui"})
}

// ToggleBlacklist handles PATCH /api/v1/admin/users/:id/blacklist
func (h *AdminHandler) ToggleBlacklist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID tidak valid"})
		return
	}

	var input struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.UpdateUserStatus(uint(id), input.Status); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Status blacklist berhasil diperbarui"})
}

// GetBlacklist handles GET /api/admin/blacklist
func (h *AdminHandler) GetBlacklist(c *gin.Context) {
	data, err := h.AdminUsecase.GetBlacklist()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"blacklist": data})
}

// GetBlacklistStats handles GET /api/admin/blacklist-stats
func (h *AdminHandler) GetBlacklistStats(c *gin.Context) {
	data, err := h.AdminUsecase.GetBlacklistStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, data)
}

// ForceExitActivity handles POST /api/admin/activities/:id/force-exit
func (h *AdminHandler) ForceExitActivity(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID aktivitas tidak valid"})
		return
	}

	if err := h.AdminUsecase.ForceExitActivity(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Berhasil force exit kendaraan"})
}

// AddPenalty handles POST /api/admin/users/:id/penalty
func (h *AdminHandler) AddPenalty(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID user tidak valid"})
		return
	}

	var input struct {
		Poin       int    `json:"poin" binding:"required"`
		Keterangan string `json:"keterangan" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.AddPenalty(uint(id), input.Poin, input.Keterangan); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Penalti berhasil ditambahkan"})
}

// RemovePenalty handles DELETE /api/admin/users/:id/penalty
func (h *AdminHandler) RemovePenalty(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID user tidak valid"})
		return
	}

	if err := h.AdminUsecase.RemovePenalty(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Penalti berhasil dihapus"})
}

// GetPendingLaporan handles GET /api/admin/laporan/pending
func (h *AdminHandler) GetPendingLaporan(c *gin.Context) {
	pending, err := h.AdminUsecase.GetPendingLaporan()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, pending)
}

// GetLaporanDetail handles GET /api/admin/laporan/:id
func (h *AdminHandler) GetLaporanDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	detail, err := h.AdminUsecase.GetLaporanDetail(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Laporan tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"laporan_detail": detail})
}

// ApproveLaporan handles POST /api/admin/penalti/approve
func (h *AdminHandler) ApproveLaporan(c *gin.Context) {
	var input struct {
		IDLaporan        uint   `json:"id_laporan" binding:"required"`
		PoinPenalti      int    `json:"poin_penalti" binding:"required"`
		JenisPelanggaran string `json:"jenis_pelanggaran" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Input tidak valid: " + err.Error()})
		return
	}

	if err := h.AdminUsecase.ApproveLaporan(input.IDLaporan, input.PoinPenalti, input.JenisPelanggaran); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Laporan disetujui dan penalti ditambahkan"})
}

// RejectLaporan handles PUT /api/admin/laporan/:id/reject
func (h *AdminHandler) RejectLaporan(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID tidak valid"})
		return
	}

	if err := h.AdminUsecase.RejectLaporan(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Laporan berhasil ditolak"})
}

// ─── Zone Handlers ──────────────────────────────────────────────────────────

// CreateZone handles POST /api/admin/zones
func (h *AdminHandler) CreateZone(c *gin.Context) {
	var input struct {
		NamaZona       string `json:"nama_zona" binding:"required"`
		Deskripsi      string `json:"deskripsi"`
		KapasitasMotor int    `json:"kapasitas_motor" binding:"required,min=0"`
		KapasitasMobil int    `json:"kapasitas_mobil" binding:"required,min=0"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	idZona, err := h.AdminUsecase.CreateZone(input.NamaZona, input.Deskripsi, input.KapasitasMotor, input.KapasitasMobil)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": "success", "message": "Zona berhasil dibuat", "id_zona": idZona})
}

// GetAllZones handles GET /api/admin/zones
func (h *AdminHandler) GetAllZones(c *gin.Context) {
	data, err := h.AdminUsecase.GetAllZones()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"zones": data})
}

// UpdateZone handles PUT /api/admin/zones/:id
func (h *AdminHandler) UpdateZone(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID zona tidak valid"})
		return
	}

	var input struct {
		NamaZona       string `json:"nama_zona" binding:"required"`
		Deskripsi      string `json:"deskripsi"`
		KapasitasMotor int    `json:"kapasitas_motor" binding:"required,min=0"`
		KapasitasMobil int    `json:"kapasitas_mobil" binding:"required,min=0"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.UpdateZone(uint(id), input.NamaZona, input.Deskripsi, input.KapasitasMotor, input.KapasitasMobil); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Zona berhasil diperbarui"})
}

// DeleteZone handles DELETE /api/admin/zones/:id
func (h *AdminHandler) DeleteZone(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID zona tidak valid"})
		return
	}

	if err := h.AdminUsecase.DeleteZone(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Zona dan semua slot-nya berhasil dihapus"})
}

// ─── Slot Handlers ──────────────────────────────────────────────────────────

// CreateSlot handles POST /api/admin/slots
func (h *AdminHandler) CreateSlot(c *gin.Context) {
	var input struct {
		ZonaID    uint   `json:"id_zona" binding:"required"`
		NomorSlot string `json:"nomor_slot" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.CreateSlot(input.ZonaID, input.NomorSlot); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": "success", "message": "Slot berhasil dibuat"})
}

// GetSlotsByZone handles GET /api/admin/zones/:id/slots
func (h *AdminHandler) GetSlotsByZone(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID zona tidak valid"})
		return
	}

	data, err := h.AdminUsecase.GetSlotsByZone(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"slots": data})
}

// DeleteSlot handles DELETE /api/admin/slots/:id
func (h *AdminHandler) DeleteSlot(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID slot tidak valid"})
		return
	}

	if err := h.AdminUsecase.DeleteSlot(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Slot berhasil dihapus"})
}

// SubmitReport handles POST /api/v1/report (multipart/form-data)
func (h *AdminHandler) SubmitReport(c *gin.Context) {
	var userID uint
	if userVal, exists := c.Get("id_user"); exists {
		// Use type assertion carefully in case middleware sets float64
		switch v := userVal.(type) {
		case uint:
			userID = v
		case float64:
			userID = uint(v)
		}
	}
	if formUserID := c.PostForm("id_user"); formUserID != "" {
		if parsed, err := strconv.ParseUint(formUserID, 10, 32); err == nil {
			userID = uint(parsed)
		}
	}

	platNomor := c.PostForm("plat_nomor")
	jenisKendaraan := c.PostForm("jenis_kendaraan")
	kategori := c.PostForm("kategori")
	deskripsi := c.PostForm("deskripsi")

	if platNomor == "" || kategori == "" {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Plat nomor dan kategori wajib diisi"})
		return
	}

	// Extract the file
	file, header, err := c.Request.FormFile("bukti_foto")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Bukti foto wajib diunggah"})
		return
	}
	defer file.Close()

	// Upload to Supabase Storage
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal membaca file"})
		return
	}

	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg"
	}

	filename := fmt.Sprintf("reports/%d_%d%s", userID, time.Now().UnixMilli(), ext)
	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_SERVICE_KEY")

	var publicURL string
	if supabaseURL != "" && supabaseKey != "" {
		uploadURL := fmt.Sprintf("%s/storage/v1/object/avatars/%s", supabaseURL, filename)

		req, err := http.NewRequest("POST", uploadURL, bytes.NewReader(fileBytes))
		if err == nil {
			contentType := "image/jpeg"
			switch ext {
			case ".png":
				contentType = "image/png"
			case ".webp":
				contentType = "image/webp"
			}

			req.Header.Set("Authorization", "Bearer "+supabaseKey)
			req.Header.Set("Content-Type", contentType)
			req.Header.Set("x-upsert", "true")

			client := &http.Client{Timeout: 30 * time.Second}
			resp, err := client.Do(req)
			if err == nil {
				defer resp.Body.Close()
				if resp.StatusCode == 200 {
					publicURL = fmt.Sprintf("%s/storage/v1/object/public/avatars/%s", supabaseURL, filename)
				}
			}
		}
	}

	fullDeskripsi := fmt.Sprintf("[%s] %s", kategori, deskripsi)

	if err := h.AdminUsecase.CreateLaporan(userID, platNomor, jenisKendaraan, fullDeskripsi, publicURL); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": "success", "message": "Laporan berhasil dikirim"})
}

// EditUser handles PUT /api/admin/users/:id
func (h *AdminHandler) EditUser(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID user tidak valid"})
		return
	}

	var input struct {
		Nama           string `json:"nama" binding:"required"`
		Nim            string `json:"nim"`
		RoleID         uint   `json:"id_role" binding:"required"`
		NomorPolisi    string `json:"nomor_polisi"`
		JenisKendaraan string `json:"jenis_kendaraan"`
		Status         string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.UpdateUserAdmin(uint(id), input.Nama, input.Nim, input.RoleID, input.Status, input.NomorPolisi, input.JenisKendaraan); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Data pengguna berhasil diperbarui"})
}
