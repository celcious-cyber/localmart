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

	// Categories dengan products (aktif, urut)
	config.DB.Where("is_active = ?", true).
		Order("sort_order ASC").
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
	var categories []models.Category
	config.DB.Where("is_active = ?", true).
		Order("sort_order ASC").
		Preload("Products", "is_active = ?", true).
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
		Preload("Products", "is_active = ?", true).
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
		Preload("Store").
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
