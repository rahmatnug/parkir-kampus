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

	adminRoutes := r.Group("/api/admin")
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
	}
}

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

