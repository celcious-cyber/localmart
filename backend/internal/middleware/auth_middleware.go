package middleware

import (
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret []byte

func init() {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "localmart-ksb-secret-2026" // default untuk development
	}
	jwtSecret = []byte(secret)
}

// Claims - JWT claims untuk Admin dan User
type Claims struct {
	ID    uint   `json:"id"`
	Email string `json:"email"`
	Role  string `json:"role"` // "admin" atau "user"
	jwt.RegisteredClaims
}

// GenerateToken membuat JWT token (role: "admin" atau "user")
func GenerateToken(id uint, email string, role string) (string, error) {
	claims := Claims{
		ID:    id,
		Email: email,
		Role:  role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(720 * time.Hour)), // 30 hari (untuk "Remember Me")
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// AuthMiddleware memverifikasi JWT token
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		tokenString := ""

		if authHeader != "" {
			tokenString = strings.TrimPrefix(authHeader, "Bearer ")
		} else {
			// Fallback: cek query parameter "token" (untuk WebSocket)
			tokenString = c.Query("token")
		}

		if tokenString == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Token tidak ditemukan"})
			c.Abort()
			return
		}

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Token tidak valid atau expired"})
			c.Abort()
			return
		}

		// Set info ke context berdasarkan role
		c.Set("user_id", claims.ID)
		c.Set("email", claims.Email)
		c.Set("role", claims.Role)

		// Alias untuk kompatibilitas dengan handler admin lama
		if claims.Role == "admin" {
			c.Set("admin_id", claims.ID)
			c.Set("username", claims.Email)
		}

		c.Next()
	}
}
