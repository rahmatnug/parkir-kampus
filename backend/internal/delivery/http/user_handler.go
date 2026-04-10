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
}

// Register handler
func (a *UserHandler) Register(c *gin.Context) {
	var input struct {
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := a.UserUsecase.Register(input.Email, input.Password)
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

	token, err := a.UserUsecase.Login(input.Email, input.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   token,
	})
}
