package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

// GetModuleSpecifications - GET /api/v1/modules/:code/specifications
func GetModuleSpecifications(c *gin.Context) {
	code := c.Param("code")

	var specs []models.ModuleSpecification
	if err := config.DB.Where("module_code = ?", code).Order("sort_order ASC").Find(&specs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengambil spesifikasi modul"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    specs,
	})
}

// --- ADMIN HANDLERS ---

// ListModuleSpecifications - GET /api/v1/admin/module-specifications
func ListModuleSpecifications(c *gin.Context) {
	var specs []models.ModuleSpecification
	if err := config.DB.Order("module_code ASC, sort_order ASC").Find(&specs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengambil daftar spesifikasi"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    specs,
	})
}

// CreateModuleSpecification - POST /api/v1/admin/modules/specifications
func CreateModuleSpecification(c *gin.Context) {
	var spec models.ModuleSpecification
	if err := c.ShouldBindJSON(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	if err := config.DB.Create(&spec).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal membuat spesifikasi"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"success": true, "data": spec})
}

// UpdateModuleSpecification - PUT /api/v1/admin/modules/specifications/:id
func UpdateModuleSpecification(c *gin.Context) {
	id := c.Param("id")
	var spec models.ModuleSpecification
	if err := config.DB.First(&spec, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Spesifikasi tidak ditemukan"})
		return
	}

	if err := c.ShouldBindJSON(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	config.DB.Save(&spec)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": spec})
}

// DeleteModuleSpecification - DELETE /api/v1/admin/modules/specifications/:id
func DeleteModuleSpecification(c *gin.Context) {
	id := c.Param("id")
	if err := config.DB.Delete(&models.ModuleSpecification{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menghapus spesifikasi"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Spesifikasi berhasil dihapus"})
}
