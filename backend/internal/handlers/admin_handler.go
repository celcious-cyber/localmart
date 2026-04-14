package handlers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/middleware"
	"github.com/ksb/localmart/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
)

// ══════════════════════════════════════════════════════════════
// AUTH
// ══════════════════════════════════════════════════════════════

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// AdminLogin - POST /api/v1/admin/login
func AdminLogin(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Username dan password wajib diisi"})
		return
	}

	var admin models.Admin
	result := config.DB.Where("username = ?", req.Username).First(&admin)
	if result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Username atau password salah"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(admin.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Username atau password salah"})
		return
	}

	token, err := middleware.GenerateToken(admin.ID, admin.Username, "admin")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"token":    token,
			"username": admin.Username,
		},
	})
}

// AdminMe - GET /api/v1/admin/me
func AdminMe(c *gin.Context) {
	username, _ := c.Get("username")
	adminID, _ := c.Get("admin_id")
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":       adminID,
			"username": username,
		},
	})
}

// ══════════════════════════════════════════════════════════════
// BANNERS CRUD
// ══════════════════════════════════════════════════════════════

// AdminGetBanners - GET /api/v1/admin/banners
func AdminGetBanners(c *gin.Context) {
	var banners []models.Banner
	config.DB.Order("position ASC, sort_order ASC").Find(&banners)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": banners})
}

// AdminCreateBanner - POST /api/v1/admin/banners
func AdminCreateBanner(c *gin.Context) {
	var banner models.Banner
	if err := c.ShouldBindJSON(&banner); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid: " + err.Error()})
		return
	}
	config.DB.Create(&banner)
	c.JSON(http.StatusCreated, gin.H{"success": true, "data": banner})
}

// AdminUpdateBanner - PUT /api/v1/admin/banners/:id
func AdminUpdateBanner(c *gin.Context) {
	id := c.Param("id")
	var banner models.Banner
	if config.DB.First(&banner, id).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Banner tidak ditemukan"})
		return
	}

	if err := c.ShouldBindJSON(&banner); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}
	config.DB.Save(&banner)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": banner})
}

// AdminDeleteBanner - DELETE /api/v1/admin/banners/:id
func AdminDeleteBanner(c *gin.Context) {
	id := c.Param("id")
	result := config.DB.Delete(&models.Banner{}, id)
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Banner tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Banner berhasil dihapus"})
}

// ══════════════════════════════════════════════════════════════
// CATEGORIES CRUD
// ══════════════════════════════════════════════════════════════

// AdminGetCategories - GET /api/v1/admin/categories
func AdminGetCategories(c *gin.Context) {
	var categories []models.Category
	config.DB.Order("sort_order ASC").Find(&categories)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": categories})
}

// AdminCreateCategory - POST /api/v1/admin/categories
func AdminCreateCategory(c *gin.Context) {
	var category models.Category
	if err := c.ShouldBindJSON(&category); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid: " + err.Error()})
		return
	}
	config.DB.Create(&category)
	c.JSON(http.StatusCreated, gin.H{"success": true, "data": category})
}

// AdminUpdateCategory - PUT /api/v1/admin/categories/:id
func AdminUpdateCategory(c *gin.Context) {
	id := c.Param("id")
	var category models.Category
	if config.DB.First(&category, id).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Kategori tidak ditemukan"})
		return
	}
	if err := c.ShouldBindJSON(&category); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}
	config.DB.Save(&category)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": category})
}

// AdminDeleteCategory - DELETE /api/v1/admin/categories/:id
func AdminDeleteCategory(c *gin.Context) {
	id := c.Param("id")
	result := config.DB.Delete(&models.Category{}, id)
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Kategori tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Kategori berhasil dihapus"})
}

// ══════════════════════════════════════════════════════════════
// PRODUCTS CRUD
// ══════════════════════════════════════════════════════════════

// AdminGetProducts - GET /api/v1/admin/products
func AdminGetProducts(c *gin.Context) {
	var products []models.Product
	categoryID := c.Query("category_id")
	query := config.DB.Order("id DESC")
	if categoryID != "" {
		query = query.Where("category_id = ?", categoryID)
	}
	query.Find(&products)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": products})
}

// AdminCreateProduct - POST /api/v1/admin/products
func AdminCreateProduct(c *gin.Context) {
	var product models.Product
	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid: " + err.Error()})
		return
	}
	config.DB.Create(&product)
	c.JSON(http.StatusCreated, gin.H{"success": true, "data": product})
}

// AdminUpdateProduct - PUT /api/v1/admin/products/:id
func AdminUpdateProduct(c *gin.Context) {
	id := c.Param("id")
	var product models.Product
	if config.DB.First(&product, id).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
		return
	}
	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}
	config.DB.Save(&product)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": product})
}

// AdminDeleteProduct - DELETE /api/v1/admin/products/:id
func AdminDeleteProduct(c *gin.Context) {
	id := c.Param("id")
	result := config.DB.Delete(&models.Product{}, id)
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Produk berhasil dihapus"})
}

// ══════════════════════════════════════════════════════════════
// SECTIONS CRUD
// ══════════════════════════════════════════════════════════════

// AdminGetSections - GET /api/v1/admin/sections
func AdminGetSections(c *gin.Context) {
	var sections []models.Section
	config.DB.Order("sort_order ASC").Find(&sections)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": sections})
}

// AdminUpdateSection - PUT /api/v1/admin/sections/:id
func AdminUpdateSection(c *gin.Context) {
	id := c.Param("id")
	var section models.Section
	if config.DB.First(&section, id).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Section tidak ditemukan"})
		return
	}
	if err := c.ShouldBindJSON(&section); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}
	config.DB.Save(&section)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": section})
}

// ══════════════════════════════════════════════════════════════
// DISCOVERY TABS CRUD
// ══════════════════════════════════════════════════════════════

// AdminGetDiscoveryTabs - GET /api/v1/admin/discovery-tabs
func AdminGetDiscoveryTabs(c *gin.Context) {
	var tabs []models.DiscoveryTab
	config.DB.Order("sort_order ASC").Find(&tabs)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": tabs})
}

// AdminCreateDiscoveryTab - POST /api/v1/admin/discovery-tabs
func AdminCreateDiscoveryTab(c *gin.Context) {
	var tab models.DiscoveryTab
	if err := c.ShouldBindJSON(&tab); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}
	config.DB.Create(&tab)
	c.JSON(http.StatusCreated, gin.H{"success": true, "data": tab})
}

// AdminUpdateDiscoveryTab - PUT /api/v1/admin/discovery-tabs/:id
func AdminUpdateDiscoveryTab(c *gin.Context) {
	id := c.Param("id")
	var tab models.DiscoveryTab
	if config.DB.First(&tab, id).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Tab tidak ditemukan"})
		return
	}
	if err := c.ShouldBindJSON(&tab); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}
	config.DB.Save(&tab)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": tab})
}

// AdminDeleteDiscoveryTab - DELETE /api/v1/admin/discovery-tabs/:id
func AdminDeleteDiscoveryTab(c *gin.Context) {
	id := c.Param("id")
	result := config.DB.Delete(&models.DiscoveryTab{}, id)
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Tab tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Tab berhasil dihapus"})
}

// ══════════════════════════════════════════════════════════════
// STORES & DRIVERS VIEW
// ══════════════════════════════════════════════════════════════

// AdminGetStores - GET /api/v1/admin/stores
func AdminGetStores(c *gin.Context) {
	var stores []models.Store
	config.DB.Preload("User").Order("created_at DESC").Find(&stores)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": stores})
}

// AdminGetDrivers - GET /api/v1/admin/drivers
func AdminGetDrivers(c *gin.Context) {
	var drivers []models.Driver
	config.DB.Preload("User").Order("created_at DESC").Find(&drivers)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": drivers})
}

// AdminUpdateStoreStatus - PATCH /api/v1/admin/stores/:id/status
func AdminUpdateStoreStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status string `json:"status"`
		Level  string `json:"level"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Format request tidak valid"})
		return
	}

	updates := make(map[string]interface{})
	if req.Status != "" {
		updates["status"] = req.Status
	}
	if req.Level != "" {
		updates["level"] = req.Level
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Tidak ada data yang diupdate"})
		return
	}

	result := config.DB.Model(&models.Store{}).Where("id = ?", id).Updates(updates)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update status"})
		return
	}
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Toko tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Status toko berhasil diperbarui"})
}

// AdminUpdateDriverStatus - PATCH /api/v1/admin/drivers/:id/status
func AdminUpdateDriverStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Status wajib diisi"})
		return
	}

	result := config.DB.Model(&models.Driver{}).Where("id = ?", id).Update("status", req.Status)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update status"})
		return
	}
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Driver tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Status driver berhasil diperbarui"})
}

// ══════════════════════════════════════════════════════════════
// IMAGE UPLOAD
// ══════════════════════════════════════════════════════════════

// AdminUploadImage - POST /api/v1/admin/upload
func AdminUploadImage(c *gin.Context) {
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "File gambar wajib diisi"})
		return
	}
	defer file.Close()

	// Validasi ekstensi file
	ext := filepath.Ext(header.Filename)
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true, ".gif": true}
	if !allowed[ext] {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Format file tidak didukung"})
		return
	}

	// Validasi ukuran (max 5MB)
	if header.Size > 5*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Ukuran file maksimal 5MB"})
		return
	}

	// Generate nama unik
	filename := fmt.Sprintf("%d_%s%s", time.Now().UnixNano(), strconv.Itoa(int(time.Now().Unix())), ext)
	savePath := filepath.Join("uploads", filename)

	out, err := os.Create(savePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menyimpan file"})
		return
	}
	defer out.Close()

	_, err = io.Copy(out, file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menyimpan file"})
		return
	}

	// Return URL lengkap
	imageURL := fmt.Sprintf("/uploads/%s", filename)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"url":      imageURL,
			"filename": filename,
		},
	})
}

// ══════════════════════════════════════════════════════════════
// DASHBOARD STATS
// ══════════════════════════════════════════════════════════════

// AdminDashboardStats - GET /api/v1/admin/stats
func AdminDashboardStats(c *gin.Context) {
	var bannerCount, categoryCount, productCount, sectionCount, storeCount, driverCount int64
	config.DB.Model(&models.Banner{}).Count(&bannerCount)
	config.DB.Model(&models.Category{}).Count(&categoryCount)
	config.DB.Model(&models.Product{}).Count(&productCount)
	config.DB.Model(&models.Section{}).Count(&sectionCount)
	config.DB.Model(&models.Store{}).Count(&storeCount)
	config.DB.Model(&models.Driver{}).Count(&driverCount)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"banners":    bannerCount,
			"categories": categoryCount,
			"products":   productCount,
			"sections":   sectionCount,
			"stores":     storeCount,
			"drivers":    driverCount,
		},
	})
}
