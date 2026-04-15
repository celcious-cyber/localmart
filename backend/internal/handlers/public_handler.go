package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

// HomeResponse - response lengkap untuk homepage Flutter
type HomeResponse struct {
	Banners       []models.Banner       `json:"banners"`
	BannerSliders []models.Banner       `json:"banner_sliders"`
	Categories    []models.Category     `json:"categories"`
	Sections      []models.Section      `json:"sections"`
	DiscoveryTabs []models.DiscoveryTab `json:"discovery_tabs"`
}

// GetHomeData mengembalikan semua data homepage dalam satu request
func GetHomeData(c *gin.Context) {
	typeParam := c.Query("type")
	if typeParam == "" {
		typeParam = "BARANG" // Default ke barang fisik untuk discovery utama
	}

	var banners []models.Banner
	var sliders []models.Banner
	var categories []models.Category
	var sections []models.Section
	var discoveryTabs []models.DiscoveryTab

	// Banner top (aktif, urut)
	config.DB.Where("position = ? AND is_active = ?", "top", true).
		Order("sort_order ASC").
		Find(&banners)

	// Banner slider (aktif, urut)
	config.DB.Where("position = ? AND is_active = ?", "slider", true).
		Order("sort_order ASC").
		Find(&sliders)

	// Categories dengan products sesuai Tipe (aktif, urut)
	config.DB.Where("is_active = ? AND type = ?", true, typeParam).
		Order("sort_order ASC").
		Preload("Products.Images").
		Preload("Products.Store").
		Preload("Products", "is_active = ?", true).
		Find(&categories)

	// Sections (aktif, urut)
	config.DB.Where("is_active = ?", true).
		Order("sort_order ASC").
		Find(&sections)

	// Discovery Tabs (aktif, urut)
	config.DB.Where("is_active = ?", true).
		Order("sort_order ASC").
		Find(&discoveryTabs)
	
	// Inject Mock Data for UI High-Fidelity
	for i := range categories {
		for j := range categories[i].Products {
			categories[i].Products[j].Rating = 4.8
			categories[i].Products[j].ReviewCount = 150
			if categories[i].Products[j].Store != nil {
				categories[i].Products[j].Store.Rating = 4.0
				categories[i].Products[j].Store.ReviewCount = 38
				categories[i].Products[j].Store.ProductCount = 20
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": HomeResponse{
			Banners:       banners,
			BannerSliders: sliders,
			Categories:    categories,
			Sections:      sections,
			DiscoveryTabs: discoveryTabs,
		},
	})
}

// GetBanners mengembalikan list banner aktif berdasarkan position
func GetBanners(c *gin.Context) {
	position := c.DefaultQuery("position", "top")

	var banners []models.Banner
	config.DB.Where("position = ? AND is_active = ?", position, true).
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
	if typeParam == "" {
		typeParam = "BARANG"
	}

	var categories []models.Category
	config.DB.Where("is_active = ? AND type = ?", true, typeParam).
		Order("sort_order ASC").
		Preload("Products.Images").
		Preload("Products", "is_active = ?", true).
		Preload("Products.Store").
		Find(&categories)
	
	// Inject Mock Data
	for i := range categories {
		for j := range categories[i].Products {
			categories[i].Products[j].Rating = 4.8
			categories[i].Products[j].ReviewCount = 150
			if categories[i].Products[j].Store != nil {
				categories[i].Products[j].Store.Rating = 4.0
				categories[i].Products[j].Store.ReviewCount = 38
				categories[i].Products[j].Store.ProductCount = 20
			}
		}
	}

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
		First(&category)
	
	// Inject Mock Data
	for i := range category.Products {
		category.Products[i].Rating = 4.8
		category.Products[i].ReviewCount = 150
		if category.Products[i].Store != nil {
			category.Products[i].Store.Rating = 4.0
			category.Products[i].Store.ReviewCount = 38
			category.Products[i].Store.ProductCount = 20
		}
	}

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
		Limit(20).
		Find(&products)

	// Search Stores
	config.DB.Where("name LIKE ? AND is_active = ?", searchQuery, true).
		Limit(20).
		Find(&stores)
	
	// Inject Mock Data
	for i := range products {
		products[i].Rating = 4.8
		products[i].ReviewCount = 150
		if products[i].Store != nil {
			products[i].Store.Rating = 4.0
			products[i].Store.ReviewCount = 38
			products[i].Store.ProductCount = 20
		}
	}
	for i := range stores {
		stores[i].Rating = 4.0
		stores[i].ReviewCount = 38
		stores[i].ProductCount = 20
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"products": products,
			"stores":   stores,
		},
	})
}
