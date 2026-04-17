package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

// ModuleDiscovery - grouping data per modular service
type ModuleDiscovery struct {
	Name           string            `json:"name"`
	DiscoveryTitle string            `json:"discovery_title"`
	Slug           string            `json:"slug"`
	Categories     []models.Category `json:"categories"`
	Products       []models.Product  `json:"products"`
}

// HomeResponse - response lengkap untuk homepage Flutter
type HomeResponse struct {
	Banners       []models.Banner       `json:"banners"`
	BannerSliders []models.Banner       `json:"banner_sliders"`
	Sections      []models.Section      `json:"sections"`
	DiscoveryTabs []models.DiscoveryTab `json:"discovery_tabs"`
	Modules       []ModuleDiscovery     `json:"modules"`
}

// GetHomeData mengembalikan semua data homepage dalam satu request
func GetHomeData(c *gin.Context) {
	var banners []models.Banner
	var sliders []models.Banner
	var sections []models.Section
	var discoveryTabs []models.DiscoveryTab

	// 1. Fetch Basic Layout Data
	config.DB.Where("position LIKE ? AND is_active = ?", "%home%", true).Order("sort_order ASC").Find(&banners)
	config.DB.Where("position LIKE ? AND is_active = ?", "%slider%", true).Order("sort_order ASC").Find(&sliders)
	config.DB.Where("is_active = ?", true).Order("sort_order ASC").Find(&sections)
	config.DB.Where("is_active = ?", true).Order("sort_order ASC").Find(&discoveryTabs)

	// 2. Fetch Modular Discovery Data (9 Dinamic Modules)
	moduleTypes := []struct {
		Name           string
		DiscoveryTitle string
		Slug           string
		Type           string
	}{
		{Name: "Local Food", DiscoveryTitle: "Kuliner Pilihan", Slug: "food", Type: "food"},
		{Name: "Info Kost", DiscoveryTitle: "Info Kost & Kontrakan", Slug: "kost", Type: "kost"},
		{Name: "Rental", DiscoveryTitle: "Sewa Kendaraan", Slug: "rental", Type: "rental"},
		{Name: "Transport", DiscoveryTitle: "Tiket Transportasi", Slug: "transport", Type: "transport"},
		{Name: "Jasa Utama", DiscoveryTitle: "Layanan Jasa Utama", Slug: "jasa", Type: "jasa"},
		{Name: "UMKM Pilihan", DiscoveryTitle: "UMKM Unggulan", Slug: "umkm", Type: "umkm"},
		{Name: "Hasil Bumi", DiscoveryTitle: "Panen Hari Ini", Slug: "bumi", Type: "bumi"},
		{Name: "Eksplor Wisata", DiscoveryTitle: "Eksplor Wisata", Slug: "wisata", Type: "wisata"},
		{Name: "Barang Bekas", DiscoveryTitle: "Barang Bekas Berkualitas", Slug: "second", Type: "second"},
	}

	var modules []ModuleDiscovery
	for _, m := range moduleTypes {
		var categories []models.Category
		var products []models.Product

		// Fetch Categories for this module
		config.DB.Where("service_type = ? AND is_active = ?", m.Type, true).
			Order("sort_order ASC").
			Find(&categories)

		// Fetch curated Products for this module
		categoryIDs := []uint{}
		for _, cat := range categories {
			categoryIDs = append(categoryIDs, cat.ID)
		}

		if len(categoryIDs) > 0 {
			config.DB.Preload("Images").Preload("Store").
				Where("category_id IN ? AND is_active = ?", categoryIDs, true).
				Order("created_at DESC").
				Limit(6).
				Find(&products)
		}

		modules = append(modules, ModuleDiscovery{
			Name:           m.Name,
			DiscoveryTitle: m.DiscoveryTitle,
			Slug:           m.Slug,
			Categories:     categories,
			Products:       products,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": HomeResponse{
			Banners:       banners,
			BannerSliders: sliders,
			Sections:      sections,
			DiscoveryTabs: discoveryTabs,
			Modules:       modules,
		},
	})
}

// GetBanners mengembalikan list banner aktif berdasarkan position
func GetBanners(c *gin.Context) {
	position := c.DefaultQuery("position", "home")

	var banners []models.Banner
	config.DB.Where("position LIKE ? AND is_active = ?", "%"+position+"%", true).
		Order("sort_order ASC").
		Find(&banners)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    banners,
	})
}

// GetCategories mengembalikan list kategori aktif + produknya
func GetCategories(c *gin.Context) {
	typeParam := c.Query("type")
	serviceType := c.Query("service_type")

	var categories []models.Category
	query := config.DB.Where("is_active = ?", true)

	// Jika ada service_type (modular), utamakan itu
	// Jika tidak ada service_type, gunakan default/explicit typeParam
	if serviceType != "" {
		query = query.Where("service_type = ?", serviceType)
		if typeParam != "" {
			query = query.Where("type = ?", typeParam)
		}
	} else {
		if typeParam == "" {
			typeParam = "BARANG"
		}
		query = query.Where("type = ?", typeParam)
	}

	query.Order("sort_order ASC").
		Preload("Products.Images").
		Preload("Products", "is_active = ?", true).
		Preload("Products.Store").
		Preload("Products.StoreCategories").
		Find(&categories)
	

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    categories,
	})
}

// GetProductsByCategory mengembalikan list produk berdasarkan kategori slug
func GetProductsByCategory(c *gin.Context) {
	slug := c.Param("slug")

	var category models.Category
	result := config.DB.Where("slug = ? AND is_active = ?", slug, true).
		Preload("Products.Images").
		Preload("Products", "is_active = ?", true).
		Preload("Products.Store").
		Preload("Products.StoreCategories").
		First(&category)
	

	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Kategori tidak ditemukan",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    category.Products,
	})
}

// GetDiscoveryTabs mengembalikan list discovery tab aktif
func GetDiscoveryTabs(c *gin.Context) {
	var tabs []models.DiscoveryTab
	config.DB.Where("is_active = ?", true).
		Order("sort_order ASC").
		Find(&tabs)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    tabs,
	})
}

// GetDiscoveryProducts - GET /api/v1/products/discovery?tag=panen_hari_ini
func GetDiscoveryProducts(c *gin.Context) {
	tag := c.Query("tag")
	serviceType := c.Query("service_type")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	var products []models.Product
	query := config.DB.Preload("Images").Preload("Store").Where("is_active = ?", true)

	// Filter berdasarkan serviceType (Module)
	if serviceType != "" {
		query = query.Where("service_type = ?", serviceType)
	}

	// Filter berdasarkan tag
	switch tag {
	case "panen_hari_ini":
		query = query.Where("is_fresh = ?", true)
	case "umkm_pilihan":
		query = query.Where("is_featured = ?", true)
	case "eksplore_ksb":
		query = query.Where("is_local_gem = ?", true)
	default:
		// Jika tag tidak dikenal, ambil produk terbaru secara umum
	}

	// Ambil data dengan limit dan urutan terbaru
	err := query.Order("created_at DESC").Limit(limit).Find(&products).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Gagal mengambil data produk discovery",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// GlobalSearch - GET /api/v1/search?q=query
func GlobalSearch(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": gin.H{
				"products": []models.Product{},
				"stores":   []models.Store{},
			},
		})
		return
	}

	var products []models.Product
	var stores []models.Store

	searchQuery := "%" + query + "%"

	// Search Products
	config.DB.Where("name LIKE ? AND is_active = ?", searchQuery, true).
		Preload("Images").
		Preload("Store").
		Preload("StoreCategories").
		Limit(20).
		Find(&products)

	// Search Stores
	config.DB.Where("name LIKE ? AND is_active = ?", searchQuery, true).
		Limit(20).
		Find(&stores)
	

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"products": products,
			"stores":   stores,
		},
	})
}

// GetStoresPublic mencari toko berdasarkan modul bisnis (e.g. food, umkm)
func GetStoresPublic(c *gin.Context) {
	module := c.Query("module")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	var stores []models.Store
	query := config.DB.Where("is_active = ?", true)

	if module != "" {
		query = query.Joins("JOIN store_business_modules sbm ON sbm.store_id = stores.id").
			Joins("JOIN business_modules bm ON bm.id = sbm.business_module_id").
			Where("bm.code = ?", module)
	}

	err := query.Order("rating DESC, review_count DESC").Limit(limit).Find(&stores).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Gagal mengambil data toko",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stores,
	})
}

// GetStoreDetail - GET /api/v1/stores/:id
func GetStoreDetail(c *gin.Context) {
	id := c.Param("id")

	var store models.Store
	if err := config.DB.Preload("User").First(&store, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Toko tidak ditemukan"})
		return
	}

	// Calculate Stats
	var productCount int64
	var followerCount int64
	var transactionCount int64
	
	config.DB.Model(&models.Product{}).Where("store_id = ? AND is_active = ?", store.ID, true).Count(&productCount)
	config.DB.Model(&models.StoreFollower{}).Where("store_id = ?", store.ID).Count(&followerCount)
	config.DB.Model(&models.Order{}).Where("store_id = ? AND status = ?", store.ID, "COMPLETED").Count(&transactionCount)

	// Fetch Store Categories (Etalase)
	var storeCategories []models.StoreCategory
	config.DB.Where("store_id = ?", store.ID).Order("sort_order ASC").Find(&storeCategories)

	// Update store object with real counts
	store.ProductCount = int(productCount)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"store":             store,
			"follower_count":    followerCount,
			"transaction_count": transactionCount,
			"categories":        storeCategories,
		},
	})
}

// GetStoreProductsPublic - GET /api/v1/stores/:id/products?category_id=X&page=Y
func GetStoreProductsPublic(c *gin.Context) {
	storeID := c.Param("id")
	categoryID := c.Query("category_id")
	storeCategoryID := c.Query("store_category_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize := 20
	offset := (page - 1) * pageSize

	var products []models.Product
	query := config.DB.Preload("Images").Preload("Store").Where("store_id = ? AND is_active = ?", storeID, true)

	if categoryID != "" {
		query = query.Where("products.category_id = ?", categoryID)
	}

	if storeCategoryID != "" {
		query = query.Joins("JOIN product_store_categories psc ON psc.product_id = products.id").
			Where("psc.store_category_id = ?", storeCategoryID)
	}

	query.Preload("StoreCategories").Order("products.created_at DESC").Limit(pageSize).Offset(offset).Find(&products)


	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// GetProductDetail mengembalikan detail produk dengan rating/ulasan asli
func GetProductDetail(c *gin.Context) {
	id := c.Param("id")

	var product models.Product
	if err := config.DB.Preload("Images").Preload("Store").Preload("Variants").Preload("StoreCategories").First(&product, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
		return
	}

	// Hitung Rating & ReviewCount secara real-time dari tabel reviews
	var stats struct {
		AverageRating float64
		ReviewCount   int64
	}

	config.DB.Model(&models.Review{}).
		Where("product_id = ?", product.ID).
		Select("COALESCE(AVG(rating), 0) as average_rating, COUNT(*) as review_count").
		Scan(&stats)

	product.Rating = stats.AverageRating
	product.ReviewCount = int(stats.ReviewCount)

	// Hitung Statistik Toko secara real-time
	if product.Store != nil {
		var storeStats struct {
			AverageRating float64
			ProductCount  int64
		}
		// Average Rating Toko (dari semua ulasan produk miliknya)
		config.DB.Model(&models.Review{}).
			Joins("JOIN products ON products.id = reviews.product_id").
			Where("products.store_id = ?", product.Store.ID).
			Select("COALESCE(AVG(reviews.rating), 0) as average_rating").
			Scan(&storeStats)

		// Product Count Toko
		config.DB.Model(&models.Product{}).
			Where("store_id = ? AND is_active = ?", product.Store.ID, true).
			Count(&storeStats.ProductCount)

		product.Store.Rating = storeStats.AverageRating
		product.Store.ProductCount = int(storeStats.ProductCount)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    product,
	})
}

// GetProducts mengembalikan daftar produk global dengan filter kategori (limit 10)
func GetProducts(c *gin.Context) {
	categoryID := c.Query("category_id")
	limit := 10

	var products []models.Product
	query := config.DB.Preload("Images").Preload("Store").Where("is_active = ?", true)

	if categoryID != "" {
		query = query.Where("category_id = ?", categoryID)
	}

	if err := query.Order("created_at DESC").Limit(limit).Find(&products).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengambil data produk"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}
