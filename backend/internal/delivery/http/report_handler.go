package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

// ReportHandler serves the reporting & analytics endpoints.
// These are read-only queries isolated from real-time transactions.
type ReportHandler struct {
	ReportUsecase domain.ReportUsecase
}

// NewReportHandler registers the /api/v1/reports/* routes
func NewReportHandler(r *gin.Engine, uc domain.ReportUsecase) {
	handler := &ReportHandler{
		ReportUsecase: uc,
	}

	reports := r.Group("/api/v1/reports")
	reports.Use(AuthMiddleware(), AuthAdminMiddleware())
	{
		reports.GET("/daily", handler.GetDailyReport)
		reports.GET("/analytical", handler.GetAnalyticalReport)
		reports.GET("/audit", handler.GetAuditReport)
	}
}

// GetDailyReport returns total occupancy per zone, current queue, and
// accumulated vehicle entries for today.
func (h *ReportHandler) GetDailyReport(c *gin.Context) {
	data, err := h.ReportUsecase.GetDailyReport()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   data,
	})
}

// GetAnalyticalReport accepts start_date and end_date query params.
// Returns AWT per role, busy-hour chart, and total vehicles.
func (h *ReportHandler) GetAnalyticalReport(c *gin.Context) {
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	data, err := h.ReportUsecase.GetAnalyticalReport(startDate, endDate)
	if err != nil {
		status := http.StatusInternalServerError
		if startDate == "" || endDate == "" {
			status = http.StatusBadRequest
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   data,
	})
}

// GetAuditReport returns top penalty users, blacklist history, and
// illegal access history.
func (h *ReportHandler) GetAuditReport(c *gin.Context) {
	data, err := h.ReportUsecase.GetAuditReport()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data":   data,
	})
}
