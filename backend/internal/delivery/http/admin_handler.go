package http

import (
	"net/http"
	"strconv"

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
		adminRoutes.GET("/activities", handler.GetActivities)
		adminRoutes.DELETE("/users/:id", handler.DeleteUser)
		adminRoutes.PUT("/users/:id/role", handler.UpdateUserRole)
		adminRoutes.GET("/blacklist", handler.GetBlacklist)
		adminRoutes.POST("/activities/:id/force-exit", handler.ForceExitActivity)
		adminRoutes.POST("/users/:id/penalty", handler.AddPenalty)
		adminRoutes.DELETE("/users/:id/penalty", handler.RemovePenalty)

		// Zone CRUD
		adminRoutes.POST("/zones", handler.CreateZone)
		adminRoutes.GET("/zones", handler.GetAllZones)
		adminRoutes.PUT("/zones/:id", handler.UpdateZone)
		adminRoutes.DELETE("/zones/:id", handler.DeleteZone)

		// Slot CRUD
		adminRoutes.POST("/slots", handler.CreateSlot)
		adminRoutes.GET("/zones/:id/slots", handler.GetSlotsByZone)
		adminRoutes.DELETE("/slots/:id", handler.DeleteSlot)
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

// GetBlacklist handles GET /api/admin/blacklist
func (h *AdminHandler) GetBlacklist(c *gin.Context) {
	data, err := h.AdminUsecase.GetBlacklist()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"blacklist": data})
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

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Penalti berhasil dihapus"})
}

// ─── Zone Handlers ──────────────────────────────────────────────────────────

// CreateZone handles POST /api/admin/zones
func (h *AdminHandler) CreateZone(c *gin.Context) {
	var input struct {
		NamaZona       string `json:"nama_zona" binding:"required"`
		Deskripsi      string `json:"deskripsi"`
		Kapasitas      int    `json:"kapasitas" binding:"required,gt=0"`
		JenisKendaraan string `json:"jenis_kendaraan" binding:"required,oneof=motor mobil"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.CreateZone(input.NamaZona, input.Deskripsi, input.Kapasitas, input.JenisKendaraan); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": "success", "message": "Zona berhasil dibuat"})
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
		Kapasitas      int    `json:"kapasitas" binding:"required,gt=0"`
		JenisKendaraan string `json:"jenis_kendaraan" binding:"required,oneof=motor mobil"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	if err := h.AdminUsecase.UpdateZone(uint(id), input.NamaZona, input.Deskripsi, input.Kapasitas, input.JenisKendaraan); err != nil {
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
