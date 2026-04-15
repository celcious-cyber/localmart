package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
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

// CreateStoreProduct - POST /api/v1/user/store/products (Multipart)
func CreateStoreProduct(c *gin.Context) {
	c.Request.ParseMultipartForm(8 << 20) // 8MB limit
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Anda belum terdaftar sebagai Toko"})
		return
	}

	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Gagal membaca data multipart"})
		return
	}

	// 1. Basic Fields
	price, _ := strconv.ParseFloat(c.PostForm("price"), 64)
	categoryID, _ := strconv.Atoi(c.PostForm("category_id"))
	stock, _ := strconv.Atoi(c.PostForm("stock"))
	minOrder, _ := strconv.Atoi(c.PostForm("min_order"))
	
	// Logistics
	weight, _ := strconv.ParseFloat(c.PostForm("weight"), 64)
	length, _ := strconv.Atoi(c.PostForm("length"))
	width, _ := strconv.Atoi(c.PostForm("width"))
	height, _ := strconv.Atoi(c.PostForm("height"))

	product := models.Product{
		StoreID:     store.ID,
		CategoryID:  uint(categoryID),
		Name:        c.PostForm("name"),
		Description: c.PostForm("description"),
		Price:       price,
		Stock:       stock,
		Condition:   c.PostForm("condition"),
		Brand:       c.PostForm("brand"),
		SKU:         c.PostForm("sku"),
		MinOrder:    minOrder,
		ProductType: c.PostForm("product_type"),
		Metadata:    c.PostForm("metadata"), // Stringified JSON dari frontend
		Weight:      weight,
		Length:      length,
		Width:       width,
		Height:      height,
	}

	// 2. Parse Variants (JSON String)
	variantsJSON := c.PostForm("variants")
	if variantsJSON != "" && variantsJSON != "[]" {
		if err := json.Unmarshal([]byte(variantsJSON), &product.Variants); err != nil {
			log.Printf("Gagal parse varian: %v", err)
		}
	}

	// 3. Process Images
	files := form.File["images[]"]
	err = config.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&product).Error; err != nil {
			return err
		}

		// Handle Uploaded Images
		for i, file := range files {
			ext := filepath.Ext(file.Filename)
			if ext == "" { ext = ".jpg" }
			filename := fmt.Sprintf("prod_%d_%d_%d%s", product.ID, i, time.Now().Unix(), ext)
			savePath := filepath.Join("uploads", filename)
			
			if err := c.SaveUploadedFile(file, savePath); err != nil {
				return err
			}

			url := "/uploads/" + filename
			if i == 0 {
				tx.Model(&product).Update("image_url", url)
			}
			
			img := models.ProductImage{ProductID: product.ID, ImageURL: url}
			if err := tx.Create(&img).Error; err != nil {
				return err
			}
		}
		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal simpan produk: " + err.Error()})
		return
	}

	config.DB.Preload("Images").Preload("Variants").First(&product, product.ID)
	c.JSON(http.StatusCreated, gin.H{"success": true, "message": "Produk berhasil ditambahkan", "data": product})
}

// UpdateStoreProduct - PUT /api/v1/user/store/products/:id (Multipart)
func UpdateStoreProduct(c *gin.Context) {
	c.Request.ParseMultipartForm(8 << 20) // 8MB limit
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
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
		return
	}

	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Gagal membaca data multipart"})
		return
	}

	// 1. Map Fields
	price, _ := strconv.ParseFloat(c.PostForm("price"), 64)
	categoryID, _ := strconv.Atoi(c.PostForm("category_id"))
	stock, _ := strconv.Atoi(c.PostForm("stock"))
	minOrder, _ := strconv.Atoi(c.PostForm("min_order"))
	
	weight, _ := strconv.ParseFloat(c.PostForm("weight"), 64)
	length, _ := strconv.Atoi(c.PostForm("length"))
	width, _ := strconv.Atoi(c.PostForm("width"))
	height, _ := strconv.Atoi(c.PostForm("height"))

	product.Name = c.PostForm("name")
	product.CategoryID = uint(categoryID)
	product.Description = c.PostForm("description")
	product.Price = price
	product.Stock = stock
	product.Condition = c.PostForm("condition")
	product.Brand = c.PostForm("brand")
	product.SKU = c.PostForm("sku")
	product.MinOrder = minOrder
	product.ProductType = c.PostForm("product_type")
	product.Metadata = c.PostForm("metadata")
	product.Weight = weight
	product.Length = length
	product.Width = width
	product.Height = height

	// 2. Parse Variants & Existing Images
	var variants []models.ProductVariant
	json.Unmarshal([]byte(c.PostForm("variants")), &variants)
	
	var existingImages []string
	json.Unmarshal([]byte(c.PostForm("existing_images")), &existingImages)

	// 3. Process Transaction
	err = config.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Save(&product).Error; err != nil {
			return err
		}

		// Update Variants (Replace)
		tx.Where("product_id = ?", product.ID).Delete(&models.ProductVariant{})
		for i := range variants {
			variants[i].ProductID = product.ID
			variants[i].ID = 0
		}
		if len(variants) > 0 {
			tx.Create(&variants)
		}

		// Update Images
		tx.Where("product_id = ? AND image_url NOT IN ?", product.ID, existingImages).Delete(&models.ProductImage{})
		
		// New Image Uploads
		files := form.File["images[]"]
		for i, file := range files {
			filename := fmt.Sprintf("upd_%d_%d_%d%s", product.ID, i, time.Now().Unix(), filepath.Ext(file.Filename))
			savePath := filepath.Join("uploads", filename)
			if err := c.SaveUploadedFile(file, savePath); err != nil {
				return err
			}
			url := "/uploads/" + filename
			tx.Create(&models.ProductImage{ProductID: product.ID, ImageURL: url})
		}
		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update produk: " + err.Error()})
		return
	}

	config.DB.Preload("Images").Preload("Variants").First(&product, product.ID)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Produk berhasil diperbarui", "data": product})
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
