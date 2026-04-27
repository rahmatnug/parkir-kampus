package websocket

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"github.com/gorilla/websocket"
	pkgjwt "github.com/rahmatnug/parkir-kampus-backend/pkg/jwt"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// Allow cross-origin in dev — tighten CheckOrigin for production
	CheckOrigin: func(r *http.Request) bool { return true },
}

// NewWSHandler registers GET /api/v1/ws/connect?token=X
func NewWSHandler(r *gin.Engine, hub *Hub) {
	r.GET("/api/v1/ws/connect", func(c *gin.Context) {
		handleWSConnect(c, hub)
	})
}

// handleWSConnect validates the JWT token during the HTTP handshake phase.
// If the token is missing, invalid, or expired the server responds with
// HTTP 401 BEFORE the protocol upgrade — keeping the WebSocket layer clean.
func handleWSConnect(c *gin.Context, hub *Hub) {
	tokenStr := c.Query("token")
	if tokenStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "missing token query parameter",
			"code":  "ERR_NO_TOKEN",
		})
		return
	}

	// Parse and validate the JWT
	claims := &pkgjwt.Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
		return pkgjwt.JWTKey, nil
	})
	if err != nil || !token.Valid {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "invalid or expired token",
			"code":  "ERR_TOKEN_EXPIRED",
		})
		return
	}

	// ─── Token is valid — upgrade to WebSocket ──────────────────────────
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("[ws] upgrade failed for user=%d: %v", claims.IDUser, err)
		return
	}

	client := &Client{
		Hub:    hub,
		Conn:   conn,
		Send:   make(chan []byte, 256),
		UserID: claims.IDUser,
	}

	hub.Register <- client

	// Start read/write pumps in separate goroutines
	go client.writePump()
	go client.readPump()

	log.Printf("[ws] connection established user=%d role=%d", claims.IDUser, claims.IDRole)
}
