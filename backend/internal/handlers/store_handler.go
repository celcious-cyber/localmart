package handlers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
	"gorm.io/gorm"
	"log"
)

type StoreRegisterRequest struct {
	Name     string `json:"name" binding:"required"`
	Category string `json:"category" binding:"required"`
	Address  string `json:"address" binding:"required"`
}

type StoreProfileRequest struct {
	Name        string `json:"name"`
	Category    string `json:"category"`
	Description string `json:"description"`
	Address     string `json:"address"`
	ImageURL    string `json:"image_url"`
}

// RegisterStore - POST /api/v1/user/store/register
func RegisterStore(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var req StoreRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data pendaftaran tidak valid: " + err.Error()})
		return
	}

	// Cek apakah sudah punya toko
	var existingStore models.Store
	if config.DB.Where("user_id = ?", uid).First(&existingStore).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"success": false, "message": "Anda sudah memiliki toko yang terdaftar"})
		return
	}

	store := models.Store{
		UserID:   uid,
		Name:     req.Name,
		Category: req.Category,
		Address:  req.Address,
		Status:   "pending",
		IsActive: true,
	}

	if err := config.DB.Create(&store).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal membuat profil toko"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Pendaftaran toko berhasil!",
		"data":    store,
	})
}

// ══════════════════════════════════════════════════════════════
// STORE PRODUCT MANAGEMENT
// ══════════════════════════════════════════════════════════════

// GetStoreProducts - GET /api/v1/user/store/products
func GetStoreProducts(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Anda belum terdaftar sebagai Toko"})
		return
	}

	var products []models.Product
	config.DB.Preload("Images").Where("store_id = ?", store.ID).Order("created_at DESC").Find(&products)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// UploadImage - POST /api/v1/user/upload
func UploadImage(c *gin.Context) {
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		log.Printf("Gagal ambil file 'image': %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "File gambar wajib diisi: " + err.Error()})
		return
	}
	defer file.Close()

	// Validasi ekstensi
	log.Printf("Menerima file: %s", header.Filename)
	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg" // Default fallback
	}
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true}
	if !allowed[ext] {
		log.Printf("Ekstensi tidak didukung: %s", ext)
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Format file tidak didukung: " + ext})
		return
	}

	// Buat folder uploads jika belum ada
	if _, err := os.Stat("uploads"); os.IsNotExist(err) {
		os.Mkdir("uploads", 0755)
	}

	// Nama unik
	filename := fmt.Sprintf("seller_%d_%d%s", time.Now().UnixNano(), time.Now().Unix(), ext)
	savePath := filepath.Join("uploads", filename)

	out, err := os.Create(savePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal simpan file di server"})
		return
	}
	defer out.Close()

	if _, err = io.Copy(out, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal copy file"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"url": fmt.Sprintf("/uploads/%s", filename),
		},
	})
}

// CreateStoreProduct - POST /api/v1/user/store/products
func CreateStoreProduct(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Anda belum terdaftar sebagai Toko"})
		return
	}

	var product models.Product
	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data produk tidak valid"})
		return
	}

	// Gunakan Transaction untuk memastikan konsistensi (Produk + Images)
	log.Printf("Menyimpan produk baru: %s dengan %d gambar", product.Name, len(product.Images))
	
	err := config.DB.Transaction(func(tx *gorm.DB) error {
		// 1. Simpan produk utama
		product.StoreID = store.ID
		if err := tx.Create(&product).Error; err != nil {
			return err
		}
		// GORM akan otomatis menyimpan product.Images karena ada foreignKey
		// Tapi kita bisa paksa jika perlu: tx.Model(&product).Association("Images").Replace(product.Images)
		return nil
	})

	if err != nil {
		log.Printf("Gagal simpan produk: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menambahkan produk: " + err.Error()})
		return
	}

	// Reload dengan images untuk response
	config.DB.Preload("Images").First(&product, product.ID)

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Produk berhasil ditambahkan",
		"data":    product,
	})
}

// UpdateStoreProduct - PUT /api/v1/user/store/products/:id
func UpdateStoreProduct(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)
	productID := c.Param("id")

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	var product models.Product
	if err := config.DB.Where("id = ? AND store_id = ?", productID, store.ID).First(&product).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan atau bukan milik Anda"})
		return
	}

	if err := c.ShouldBindJSON(&product); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data update tidak valid"})
		return
	}

	log.Printf("Update produk ID %s: %s dengan %d gambar", productID, product.Name, len(product.Images))

	// Gunakan Transaction untuk memastikan konsistensi update
	err := config.DB.Transaction(func(tx *gorm.DB) error {
		// 1. Update data utama produk
		if err := tx.Save(&product).Error; err != nil {
			return err
		}
		// 2. Sinkronkan asosisasi Images (Replace yang lama dengan yang baru)
		if err := tx.Model(&product).Association("Images").Replace(product.Images); err != nil {
			log.Printf("Gagal sinkron gambar: %v", err)
			return err
		}
		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update produk: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Produk berhasil diperbarui",
		"data":    product,
	})
}

// DeleteStoreProduct - DELETE /api/v1/user/store/products/:id
func DeleteStoreProduct(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)
	productID := c.Param("id")

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	result := config.DB.Where("id = ? AND store_id = ?", productID, store.ID).Delete(&models.Product{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Produk berhasil dihapus"})
}

// ══════════════════════════════════════════════════════════════
// STORE DASHBOARD & SETTINGS
// ══════════════════════════════════════════════════════════════

// GetStoreDashboard - GET /api/v1/user/store/dashboard
func GetStoreDashboard(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	// Hitung Statistik
	var totalOrders int64
	var totalSales float64
	var pendingOrders int64

	config.DB.Model(&models.Order{}).Where("store_id = ?", store.ID).Count(&totalOrders)
	config.DB.Model(&models.Order{}).Where("store_id = ? AND status = 'completed'", store.ID).Select("SUM(total_amount)").Row().Scan(&totalSales)
	config.DB.Model(&models.Order{}).Where("store_id = ? AND status = 'pending'", store.ID).Count(&pendingOrders)

	// Ambil 5 produk terlaris
	var topProducts []models.Product
	config.DB.Where("store_id = ?", store.ID).Order("sold DESC").Limit(5).Find(&topProducts)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"balance":        store.Balance,
			"total_orders":   totalOrders,
			"total_sales":    totalSales,
			"pending_orders": pendingOrders,
			"top_products":   topProducts,
			"store":          store,
		},
	})
}

// UpdateStoreProfile - PATCH /api/v1/user/store/profile
func UpdateStoreProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	var req StoreProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	// Update fields if provided
	if req.Name != "" {
		store.Name = req.Name
	}
	if req.Category != "" {
		store.Category = req.Category
	}
	if req.Description != "" {
		store.Description = req.Description
	}
	if req.Address != "" {
		store.Address = req.Address
	}
	if req.ImageURL != "" {
		store.ImageURL = req.ImageURL
	}

	if err := config.DB.Save(&store).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update profil toko"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Profil toko berhasil diperbarui",
		"data":    store,
	})
}
