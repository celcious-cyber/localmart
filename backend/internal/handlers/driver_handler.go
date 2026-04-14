package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

type DriverRegisterRequest struct {
	VehicleType string `json:"vehicle_type" binding:"required"`
	PlateNumber string `json:"plate_number" binding:"required"`
	PhoneNumber string `json:"phone_number" binding:"required"`
}

// RegisterDriver - POST /api/v1/user/driver/register
func RegisterDriver(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var req DriverRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data pendaftaran tidak valid: " + err.Error()})
		return
	}

	// Cek apakah sudah terdaftar driver
	var existingDriver models.Driver
	if config.DB.Where("user_id = ?", uid).First(&existingDriver).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"success": false, "message": "Anda sudah terdaftar sebagai Mitra Driver"})
		return
	}

	driver := models.Driver{
		UserID:      uid,
		VehicleType: req.VehicleType,
		PlateNumber: req.PlateNumber,
		PhoneNumber: req.PhoneNumber,
		IsOnline:    false,
		Balance:     0,
		Status:      "pending",
		IsActive:    true,
	}

	if err := config.DB.Create(&driver).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal membuat profil driver"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Pendaftaran Mitra Driver berhasil!",
		"data":    driver,
	})
}
