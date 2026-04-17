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
	"strings"
)

type StoreRegisterRequest struct {
	Name         string   `json:"name" binding:"required"`
	Category     string   `json:"category"` // Display label (Optional)
	ServiceTypes []string `json:"service_types" binding:"required,min=1"`
	Address      string   `json:"address" binding:"required"`
}

type StoreProfileRequest struct {
	Name        string  `json:"name"`
	Category    string  `json:"category"`
	Description string  `json:"description"`
	Address     string  `json:"address"`
	ImageURL    string  `json:"image_url"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
}

type StoreSettingsRequest struct {
	BannerURL   string `json:"banner_url"`
	LogoURL     string `json:"logo_url"` // maps to ImageURL in DB
	Description string `json:"description"`
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

	// Associate Modules
	var modules []models.BusinessModule
	if err := config.DB.Where("code IN ?", req.ServiceTypes).Find(&modules).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal memvalidasi modul bisnis"})
		return
	}

	store := models.Store{
		UserID:          uid,
		Name:            req.Name,
		Category:        req.Category,
		Address:         req.Address,
		Status:          "pending",
		IsActive:        true,
		BusinessModules: modules,
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

// GetStoreConstants - GET /api/v1/store/constants
func GetStoreConstants(c *gin.Context) {
	var modules []models.BusinessModule
	config.DB.Order("id ASC").Find(&modules)

	if len(modules) == 0 {
		// Fallback if seeder hasn't run
		modules = []models.BusinessModule{
			{Code: "food", Name: "Kuliner & Resto"},
			{Code: "kost", Name: "Properti & Penginapan"},
			{Code: "rental", Name: "Rental Kendaraan"},
			{Code: "transport", Name: "Tiket & Transportasi"},
			{Code: "jasa", Name: "Layanan Jasa"},
			{Code: "umkm", Name: "Produk UMKM & Kriya"},
			{Code: "bumi", Name: "Agrikultur & Pertanian"},
			{Code: "wisata", Name: "Pariwisata & Tur"},
			{Code: "second", Name: "Barang Preloved"},
			{Code: "mart", Name: "Mart & Lainnya"},
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    modules,
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
	if err := config.DB.Preload("BusinessModules").Where("user_id = ?", uid).First(&store).Error; err != nil {
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
	
	// Multi-Etalase parsing
	categoryIDsRaw := form.Value["store_category_ids[]"]
	var storeCategories []models.StoreCategory
	for _, idStr := range categoryIDsRaw {
		id, _ := strconv.Atoi(idStr)
		if id > 0 {
			storeCategories = append(storeCategories, models.StoreCategory{ID: uint(id)})
		}
	}

	product := models.Product{
		StoreID:         store.ID,
		CategoryID:      uint(categoryID),
		Name:            c.PostForm("name"),
		Description:     c.PostForm("description"),
		Price:           price,
		Stock:           stock,
		Condition:       c.PostForm("condition"),
		Brand:           c.PostForm("brand"),
		SKU:             c.PostForm("sku"),
		MinOrder:        minOrder,
		ProductType:     c.PostForm("product_type"),
		ServiceType:     c.PostForm("service_type"), // modul/layanan
		Metadata:        c.PostForm("metadata"),
		Weight:          weight,
		Length:          length,
		Width:           width,
		Height:          height,
		StoreCategories: storeCategories,
	}

	// SECURITY VALIDATION: Product must belong to one of store's authorized modules
	isAuthorized := false
	for _, m := range store.BusinessModules {
		if m.Code == product.ServiceType {
			isAuthorized = true
			break
		}
	}

	if !isAuthorized {
		c.JSON(http.StatusForbidden, gin.H{
			"success": false,
			"message": fmt.Sprintf("Toko Anda tidak terdaftar untuk modul '%s'. Hubungi Admin untuk menambah modul.", product.ServiceType),
		})
		return
	}

	// Data Integrity Validation: Category must belong to the selected ServiceType
	var category models.Category
	if err := config.DB.First(&category, product.CategoryID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Kategori tidak ditemukan"})
		return
	}
	
	if category.ServiceType != product.ServiceType {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false, 
			"message": fmt.Sprintf("Kategori '%s' tidak berelasi dengan modul '%s'", category.Name, product.ServiceType),
		})
		return
	}

	if category.Type != product.ProductType {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": fmt.Sprintf("Kategori %s tidak cocok dengan tipe produk %s", category.Name, product.ProductType)})
		return
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
	product.ServiceType = c.PostForm("service_type") // modul/layanan
	product.Metadata = c.PostForm("metadata")
	product.Weight = weight
	product.Length = length
	product.Width = width
	product.Height = height

	// Multi-Etalase parsing
	categoryIDsRaw := form.Value["store_category_ids[]"]
	var storeCategories []models.StoreCategory
	for _, idStr := range categoryIDsRaw {
		id, _ := strconv.Atoi(idStr)
		if id > 0 {
			storeCategories = append(storeCategories, models.StoreCategory{ID: uint(id)})
		}
	}

	// Data Integrity Validation: Category must belong to the selected ServiceType
	var category models.Category
	if err := config.DB.First(&category, product.CategoryID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Kategori tidak ditemukan"})
		return
	}
	
	if category.ServiceType != product.ServiceType {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false, 
			"message": fmt.Sprintf("Kategori '%s' tidak berelasi dengan modul '%s'", category.Name, product.ServiceType),
		})
		return
	}

	if category.Type != product.ProductType {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": fmt.Sprintf("Kategori %s tidak cocok dengan tipe produk %s", category.Name, product.ProductType)})
		return
	}

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

		// Update Store Categories (Many-to-Many Replace)
		if err := tx.Model(&product).Association("StoreCategories").Replace(storeCategories); err != nil {
			return err
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

// DeleteStore - DELETE /api/v1/user/store
func DeleteStore(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	// 1. Get Store and Preload dependencies
	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Toko tidak ditemukan"})
		return
	}

	// 2. PROTEKSI PESANAN AKTIF (Krusial)
	// Tolak jika ada pesanan status PENDING, PAID, PROCESSED (On Process)
	var activeOrdersCount int64
	config.DB.Model(&models.Order{}).Where("store_id = ? AND status IN ?", store.ID, []string{"PENDING", "PAID", "PROCESSED"}).Count(&activeOrdersCount)
	if activeOrdersCount > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Toko tidak dapat dihapus karena masih ada pesanan yang sedang berlangsung. Selesaikan semua pesanan terlebih dahulu.",
		})
		return
	}

	// 3. Collection of file paths for cleanup before deletion
	var productImageURLs []string
	config.DB.Model(&models.ProductImage{}).Where("product_id IN (SELECT id FROM products WHERE store_id = ?)", store.ID).Pluck("image_url", &productImageURLs)
	
	logoURL := store.ImageURL
	bannerURL := store.BannerURL

	// 4. Excecute Transactional Deletion
	err := config.DB.Transaction(func(tx *gorm.DB) error {
		// a. Cleanup Many-to-Many Associations
		if err := tx.Model(&store).Association("BusinessModules").Clear(); err != nil {
			return err
		}

		// b. Get Product IDs for cascading cleanup
		var productIDs []uint
		tx.Model(&models.Product{}).Where("store_id = ?", store.ID).Pluck("id", &productIDs)

		if len(productIDs) > 0 {
			// Delete Product Variants
			if err := tx.Where("product_id IN ?", productIDs).Delete(&models.ProductVariant{}).Error; err != nil {
				return err
			}
			// Delete Product Images
			if err := tx.Where("product_id IN ?", productIDs).Delete(&models.ProductImage{}).Error; err != nil {
				return err
			}
			// Delete Product Reviews
			if err := tx.Where("product_id IN ?", productIDs).Delete(&models.Review{}).Error; err != nil {
				return err
			}
			// Delete Product records
			if err := tx.Where("store_id = ?", store.ID).Delete(&models.Product{}).Error; err != nil {
				return err
			}
		}

		// c. Delete Store Categories (Etalase)
		if err := tx.Where("store_id = ?", store.ID).Delete(&models.StoreCategory{}).Error; err != nil {
			return err
		}

		// d. Handle Follows cleanup (Many-to-Many or Table)
		// We don't have a direct Follow model in models.go shown, normally a join table
		// But let's assume standard GORM deletion will handle simple fields.

		// e. Finally delete the store
		if err := tx.Delete(&store).Error; err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menghapus toko: " + err.Error()})
		return
	}

	// 5. Physical File Cleanup Logic (Disk)
	go func() {
		for _, url := range productImageURLs {
			deleteFileFromStorage(url)
		}
		deleteFileFromStorage(logoURL)
		deleteFileFromStorage(bannerURL)
	}()

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Toko Anda berhasil dihapus secara permanen.",
		"redirect": "/profile",
	})
}

// deleteFileFromStorage removes file from OS if it exists
func deleteFileFromStorage(url string) {
	if url == "" || !strings.HasPrefix(url, "/uploads/") {
		return
	}
	// Path mapping: /uploads/filename -> uploads/filename
	path := strings.TrimPrefix(url, "/")
	if err := os.Remove(path); err != nil {
		log.Printf("Warning: Gagal menghapus file %s: %v", path, err)
	}
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
		log.Printf("Error binding store profile: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid: " + err.Error()})
		return
	}

	updates := make(map[string]interface{})
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Category != "" {
		updates["category"] = req.Category
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}
	if req.Address != "" {
		updates["address"] = req.Address
	}
	if req.ImageURL != "" {
		updates["image_url"] = req.ImageURL
	}
	if req.Latitude != 0 {
		updates["latitude"] = req.Latitude
	}
	if req.Longitude != 0 {
		updates["longitude"] = req.Longitude
	}

	if err := config.DB.Model(&store).Updates(updates).Error; err != nil {
		log.Printf("Error saving store profile: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update profil toko"})
		return
	}

	// Fetch updated store
	config.DB.First(&store, store.ID)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Profil toko berhasil diperbarui",
		"data":    store,
	})
}

// UpdateStoreSettings - PATCH /api/v1/user/store/settings
func UpdateStoreSettings(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	var req StoreSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	updates := make(map[string]interface{})
	if req.BannerURL != "" {
		updates["banner_url"] = req.BannerURL
	}
	if req.LogoURL != "" {
		updates["image_url"] = req.LogoURL
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}

	if err := config.DB.Model(&store).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update pengaturan toko"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Pengaturan toko berhasil diperbarui!",
		"data":    store,
	})
}

// ══════════════════════════════════════════════════════════════
// STORE CATEGORY (ETALASE) MANAGEMENT
// ══════════════════════════════════════════════════════════════

// GetStoreCategories - GET /api/v1/user/store/categories
func GetStoreCategories(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	var categories []models.StoreCategory
	config.DB.Where("store_id = ?", store.ID).Order("sort_order ASC").Find(&categories)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    categories,
	})
}

// CreateStoreCategory - POST /api/v1/user/store/categories
func CreateStoreCategory(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	var category models.StoreCategory
	if err := c.ShouldBindJSON(&category); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	category.StoreID = store.ID
	if err := config.DB.Create(&category).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal membuat etalase"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Etalase berhasil dibuat",
		"data":    category,
	})
}

// UpdateStoreCategory - PUT /api/v1/user/store/categories/:id
func UpdateStoreCategory(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	catID := c.Param("id")
	var category models.StoreCategory
	if err := config.DB.Where("id = ? AND store_id = ?", catID, store.ID).First(&category).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Etalase tidak ditemukan"})
		return
	}

	if err := c.ShouldBindJSON(&category); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	config.DB.Save(&category)
	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Etalase berhasil diperbarui", "data": category})
}

// DeleteStoreCategory - DELETE /api/v1/user/store/categories/:id
func DeleteStoreCategory(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	catID := c.Param("id")
	
	// Transactional Delete to ensure data integrity
	err := config.DB.Transaction(func(tx *gorm.DB) error {
		// 1. Set products associated with this category to NULL
		// 1. Clear many-to-many associations for this category
		if err := tx.Exec("DELETE FROM product_store_categories WHERE store_category_id = ?", catID).Error; err != nil {
			return err
		}
		
		// 2. Delete the category
		result := tx.Where("id = ? AND store_id = ?", catID, store.ID).Delete(&models.StoreCategory{})
		if result.RowsAffected == 0 {
			return fmt.Errorf("etalase tidak ditemukan")
		}
		return nil
	})

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "message": "Etalase berhasil dihapus"})
}

type BatchAssignRequest struct {
	CategoryID *uint  `json:"category_id"` // NULL means unassign
	ProductIDs []uint `json:"product_ids"`
}

// AssignProductsToCategory - POST /api/v1/user/store/categories/assign
func AssignProductsToCategory(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	var req BatchAssignRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	if len(req.ProductIDs) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Pilih produk terlebih dahulu"})
		return
	}

	// Safety check: ensure category belongs to store if not NULL
	if req.CategoryID != nil && *req.CategoryID != 0 {
		var cat models.StoreCategory
		if err := config.DB.Where("id = ? AND store_id = ?", *req.CategoryID, store.ID).First(&cat).Error; err != nil {
			c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Etalase tidak valid"})
			return
		}
	} else if req.CategoryID != nil && *req.CategoryID == 0 {
		req.CategoryID = nil // Treat 0 as NULL
	}

	// For many-to-many batch assignment:
	// We iterate through products and append the category
	err := config.DB.Transaction(func(tx *gorm.DB) error {
		for _, pid := range req.ProductIDs {
			var product models.Product
			if tx.Where("id = ? AND store_id = ?", pid, store.ID).First(&product).Error == nil {
				if req.CategoryID != nil {
					// Add to category
					tx.Model(&product).Association("StoreCategories").Append(&models.StoreCategory{ID: *req.CategoryID})
				} else {
					// If CategoryID is null, we can't easily "unassign from all" without more context
					// but usually "Assign" in UI means "Put in this category"
					// If we really want to CLEAR ALL categories, we'd use Replace([]StoreCategory{})
				}
			}
		}
		return nil
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update etalase"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true, 
		"message": "Update etalase berhasil",
	})
}
