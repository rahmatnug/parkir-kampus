package jwt

import (
	"time"

	"github.com/golang-jwt/jwt/v4"
)

var JWTKey = []byte("super-secret-parkirkampus-key") // Ideally use env var

// Claims represents the JWT Claims structure
type Claims struct {
	IDUser uint   `json:"id_user"`
	IDRole uint   `json:"id_role"`
	jwt.RegisteredClaims
}

// GenerateToken generates a new JWT token with id_user and id_role claims
func GenerateToken(idUser uint, idRole uint) (string, error) {
	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		IDUser: idUser,
		IDRole: idRole,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(JWTKey)
}
