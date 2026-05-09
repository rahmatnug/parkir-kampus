package http

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	pkgjwt "github.com/rahmatnug/parkir-kampus-backend/pkg/jwt"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header format must be Bearer {token}"})
			c.Abort()
			return
		}

		tokenString := parts[1]
		claims := &pkgjwt.Claims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return pkgjwt.JWTKey, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		c.Set("id_user", claims.IDUser)
		c.Set("id_role", claims.IDRole)
		c.Next()
	}
}

// AuthAdminMiddleware ensures the authenticated user has admin role (id_role == 1).
// Must be used AFTER AuthMiddleware so that "id_role" is already set in the context.
func AuthAdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		idRole, exists := c.Get("id_role")
		if !exists {
			c.JSON(http.StatusForbidden, gin.H{"error": "Role information not found"})
			c.Abort()
			return
		}

		// id_role is stored as uint in AuthMiddleware via claims.IDRole
		roleID, ok := idRole.(uint)
		if !ok {
			c.JSON(http.StatusForbidden, gin.H{"error": "Invalid role format"})
			c.Abort()
			return
		}

		if roleID != 1 {
			c.JSON(http.StatusForbidden, gin.H{"error": "Access denied: admin role required"})
			c.Abort()
			return
		}

		c.Next()
	}
}
