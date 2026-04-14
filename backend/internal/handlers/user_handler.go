package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/middleware"
	"github.com/ksb/localmart/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
)

type UserRegisterRequest struct {
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name"`
	Email     string `json:"email" binding:"required,email"`
	Phone     string `json:"phone" binding:"required"`
	Password  string `json:"password" binding:"required,min=6"`
}

type UserLoginRequest struct {
	Identifier string `json:"identifier" binding:"required"` // Bisa Email atau Phone
	Password   string `json:"password" binding:"required"`
}

// UserRegister - POST /api/v1/auth/register
func UserRegister(c *gin.Context) {
	var req UserRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid: " + err.Error()})
		return
	}

	// Cek apakah email/phone sudah terdaftar
	var existingUser models.User
	if config.DB.Where("email = ? OR phone = ?", req.Email, req.Phone).First(&existingUser).RowsAffected > 0 {
		c.JSON(http.StatusConflict, gin.H{"success": false, "message": "Email atau Nomor HP sudah terdaftar"})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal memproses password"})
		return
	}

	user := models.User{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Phone:     req.Phone,
		Password:  string(hashedPassword),
	}

	if err := config.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menyimpan user"})
		return
	}

	// Langsung login-kan setelah register
	token, _ := middleware.GenerateToken(user.ID, user.Email, "user")

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Registrasi berhasil",
		"data": gin.H{
			"token": token,
			"user":  user,
		},
	})
}

// UserLogin - POST /api/v1/auth/login
func UserLogin(c *gin.Context) {
	var req UserLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email/HP dan password wajib diisi"})
		return
	}

	var user models.User
	// Login bisa pakai Email atau Nomor HP
	result := config.DB.Where("email = ? OR phone = ?", req.Identifier, req.Identifier).First(&user)
	if result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Akun tidak ditemukan atau password salah"})
		return
	}

	// Verifikasi Password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Email/HP atau password salah"})
		return
	}

	token, err := middleware.GenerateToken(user.ID, user.Email, "user")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal generate session"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Login berhasil",
		"data": gin.H{
			"token": token,
			"user":  user,
		},
	})
}

// GetUserProfile - GET /api/v1/user/profile
func GetUserProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	
	var user models.User
	if err := config.DB.Preload("Store").Preload("Driver").First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "User tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}
