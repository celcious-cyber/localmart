package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/handlers"
	"github.com/ksb/localmart/backend/internal/middleware"
)

// SetupRoutes mendefinisikan dan mengelompokkan API endpoint
func SetupRoutes(router *gin.Engine) {

	// API Versi 1
	v1 := router.Group("/api/v1")
	{
		// Health Check Endpoint
		v1.GET("/ping", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"message": "pong",
				"status":  "LocalMart Backend Golang is running smoothly!",
				"version": "1.0",
			})
		})

		// ══════════════════════════════════════════════
		// PUBLIC ENDPOINTS (untuk Flutter App)
		// ══════════════════════════════════════════════
		home := v1.Group("/home")
		{
			home.GET("", handlers.GetHomeData)
			home.GET("/banners", handlers.GetBanners)
			home.GET("/categories", handlers.GetCategories)
			home.GET("/products/:slug", handlers.GetProductsByCategory)
			home.GET("/discovery", handlers.GetDiscoveryTabs)
			home.GET("/search", handlers.GlobalSearch)
		}

		// ══════════════════════════════════════════════
		// USER AUTH & PROFILE ENDPOINTS
		// ══════════════════════════════════════════════
		auth := v1.Group("/auth")
		{
			auth.POST("/register", handlers.UserRegister)
			auth.POST("/login", handlers.UserLogin)
		}

		user := v1.Group("/user")
		user.Use(middleware.AuthMiddleware())
		{
			user.GET("/profile", handlers.GetUserProfile)
			user.POST("/store/register", handlers.RegisterStore)
			user.POST("/driver/register", handlers.RegisterDriver)

			// Store Management
			user.GET("/store/products", handlers.GetStoreProducts)
			user.POST("/store/products", handlers.CreateStoreProduct)
			user.PUT("/store/products/:id", handlers.UpdateStoreProduct)
			user.DELETE("/store/products/:id", handlers.DeleteStoreProduct)

			// Full Store Management
			user.GET("/store/dashboard", handlers.GetStoreDashboard)
			user.PATCH("/store/profile", handlers.UpdateStoreProfile)
			user.GET("/store/orders", handlers.GetStoreOrders)
			user.PATCH("/store/orders/:id/status", handlers.UpdateOrderStatus)
			user.POST("/upload", handlers.UploadImage)
		}

		// ══════════════════════════════════════════════
		// ADMIN ENDPOINTS (untuk CMS Panel)
		// ══════════════════════════════════════════════

		// Login (tanpa auth)
		v1.POST("/admin/login", handlers.AdminLogin)

		// Protected admin routes (perlu JWT)
		admin := v1.Group("/admin")
		admin.Use(middleware.AuthMiddleware())
		{
			// Dashboard
			admin.GET("/me", handlers.AdminMe)
			admin.GET("/stats", handlers.AdminDashboardStats)

			// Banners
			admin.GET("/banners", handlers.AdminGetBanners)
			admin.POST("/banners", handlers.AdminCreateBanner)
			admin.PUT("/banners/:id", handlers.AdminUpdateBanner)
			admin.DELETE("/banners/:id", handlers.AdminDeleteBanner)

			// Categories
			admin.GET("/categories", handlers.AdminGetCategories)
			admin.POST("/categories", handlers.AdminCreateCategory)
			admin.PUT("/categories/:id", handlers.AdminUpdateCategory)
			admin.DELETE("/categories/:id", handlers.AdminDeleteCategory)

			// Products
			admin.GET("/products", handlers.AdminGetProducts)
			admin.POST("/products", handlers.AdminCreateProduct)
			admin.PUT("/products/:id", handlers.AdminUpdateProduct)
			admin.DELETE("/products/:id", handlers.AdminDeleteProduct)

			// Stores & Drivers
			admin.GET("/stores", handlers.AdminGetStores)
			admin.PATCH("/stores/:id/status", handlers.AdminUpdateStoreStatus)
			admin.GET("/drivers", handlers.AdminGetDrivers)
			admin.PATCH("/drivers/:id/status", handlers.AdminUpdateDriverStatus)

			// Sections
			admin.GET("/sections", handlers.AdminGetSections)
			admin.PUT("/sections/:id", handlers.AdminUpdateSection)

			// Discovery Tabs
			admin.GET("/discovery-tabs", handlers.AdminGetDiscoveryTabs)
			admin.POST("/discovery-tabs", handlers.AdminCreateDiscoveryTab)
			admin.PUT("/discovery-tabs/:id", handlers.AdminUpdateDiscoveryTab)
			admin.DELETE("/discovery-tabs/:id", handlers.AdminDeleteDiscoveryTab)

			// Upload
			admin.POST("/upload", handlers.AdminUploadImage)
		}
	}
}
