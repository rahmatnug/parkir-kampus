package http

import (
	"net/http"

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
