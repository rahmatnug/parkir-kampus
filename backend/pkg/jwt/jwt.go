package jwt

import (
	"os"
	"time"

	"github.com/golang-jwt/jwt/v4"
)

// JWTKey is loaded from the JWT_SECRET environment variable.
// Falls back to a default key if not set (for development only).
var JWTKey []byte

func init() {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "super-secret-parkirkampus-key" // Fallback for dev; override in production!
	}
	JWTKey = []byte(secret)
}

// Claims represents the JWT Claims structure
type Claims struct {
	IDUser   uint   `json:"id_user"`
	IDRole   uint   `json:"id_role"`
	RoleName string `json:"role_name"`
	jwt.RegisteredClaims
}

// GenerateToken generates a new JWT token with id_user and id_role claims.
// Token expires in 7 days.
func GenerateToken(idUser uint, idRole uint, roleName string) (string, error) {
	expirationTime := time.Now().Add(7 * 24 * time.Hour)
	claims := &Claims{
		IDUser:   idUser,
		IDRole:   idRole,
		RoleName: roleName,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(JWTKey)
}
