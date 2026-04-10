package http

import (
	"net/http"

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
