package http

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

type ParkingHandler struct {
	Usecase domain.ParkingUsecase
}

func NewParkingHandler(r *gin.Engine, us domain.ParkingUsecase) {
	handler := &ParkingHandler{
		Usecase: us,
	}

	parking := r.Group("/api/parking")
	parking.Use(AuthMiddleware())
	{
		parking.POST("/tap-in", handler.TapIn)
		parking.POST("/tap-out", handler.TapOut)
	}

	// User-facing scan endpoint (v1)
	scan := r.Group("/api/v1/parking")
	scan.Use(AuthMiddleware())
	{
		scan.POST("/scan", handler.ScanQR)
		scan.POST("/exit", handler.ExitParking)
	}
}

func (h *ParkingHandler) TapIn(c *gin.Context) {
	var input struct {
		IDKendaraan uint `json:"id_kendaraan" binding:"required"`
		IDZona      uint `json:"id_zona" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": err.Error()})
		return
	}

	userID := c.MustGet("id_user").(uint)

	tx, status, err := h.Usecase.TapIn(userID, input.IDKendaraan, input.IDZona)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	switch status {
	case "waiting":
		c.JSON(http.StatusAccepted, gin.H{
			"status":  "waiting",
			"message": "Kapasitas penuh. Anda telah dimasukkan ke dalam daftar antrean (Waiting List) berdasarkan prioritas.",
		})
	case "conflict":
		c.JSON(http.StatusConflict, gin.H{
			"status":     "error",
			"error_code": "ERR_SLOT_CONFLICT",
			"message":    "Sistem sedang sibuk",
		})
	default:
		c.JSON(http.StatusOK, gin.H{
			"status":  "success",
			"message": "Tap-In berhasil",
			"data":    tx,
		})
	}
}

func (h *ParkingHandler) TapOut(c *gin.Context) {
	userID := c.MustGet("id_user").(uint)

	tx, err := h.Usecase.TapOut(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Tap-Out berhasil",
		"data":    tx,
	})
}

// ScanQR handles POST /api/v1/parking/scan
// Payload: { "qr_code": "ZONE-B" }
func (h *ParkingHandler) ScanQR(c *gin.Context) {
	var input struct {
		QRCode string `json:"qr_code" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":     "error",
			"error_code": "INVALID_INPUT",
			"message":    "QR code diperlukan",
		})
		return
	}

	userID := c.MustGet("id_user").(uint)

	result, err := h.Usecase.ProcessParkingEntry(userID, input.QRCode)
	if err != nil {
		errMsg := err.Error()
		statusCode := http.StatusInternalServerError
		errCode := "SERVER_ERROR"

		if strings.HasPrefix(errMsg, "ZONE_FULL:") {
			statusCode = http.StatusConflict
			errCode = "ZONE_FULL"
		} else if strings.HasPrefix(errMsg, "BLACKLISTED:") {
			statusCode = http.StatusForbidden
			errCode = "BLACKLISTED"
		} else if strings.HasPrefix(errMsg, "ALREADY_PARKED:") {
			statusCode = http.StatusConflict
			errCode = "ALREADY_PARKED"
		} else if strings.HasPrefix(errMsg, "INVALID_ZONE:") {
			statusCode = http.StatusNotFound
			errCode = "INVALID_ZONE"
		} else if strings.HasPrefix(errMsg, "ZONE_INACTIVE:") {
			statusCode = http.StatusForbidden
			errCode = "ZONE_INACTIVE"
		} else if strings.HasPrefix(errMsg, "NO_VEHICLE:") {
			statusCode = http.StatusBadRequest
			errCode = "NO_VEHICLE"
		}

		c.JSON(statusCode, gin.H{
			"status":     "error",
			"error_code": errCode,
			"message":    errMsg,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Berhasil masuk parkir",
		"data":    result,
	})
}

// ExitParking handles POST /api/v1/parking/exit
func (h *ParkingHandler) ExitParking(c *gin.Context) {
	userID := c.MustGet("id_user").(uint)

	tx, err := h.Usecase.ProcessParkingExit(userID)
	if err != nil {
		errMsg := err.Error()
		statusCode := http.StatusInternalServerError
		errCode := "SERVER_ERROR"

		if strings.HasPrefix(errMsg, "NO_ACTIVE_SESSION:") {
			statusCode = http.StatusBadRequest
			errCode = "NO_ACTIVE_SESSION"
		}

		c.JSON(statusCode, gin.H{
			"status":     "error",
			"error_code": errCode,
			"message":    errMsg,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Berhasil keluar parkir",
		"data":    tx,
	})
}

