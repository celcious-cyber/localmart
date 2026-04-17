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
			home.GET("/products/discovery", handlers.GetDiscoveryProducts)
			home.GET("/search", handlers.GlobalSearch)
			home.GET("/stores", handlers.GetStoresPublic)
		}

		// Store Detail Endpoints (Public)
		stores := v1.Group("/stores")
		{
			stores.GET("/:id", handlers.GetStoreDetail)
			stores.GET("/:id/products", handlers.GetStoreProductsPublic)
			stores.GET("/:id/reviews", handlers.GetProductReviews)
		}

		v1.GET("/store/constants", handlers.GetStoreConstants)

		// Product Details & Reviews (Public)
		v1.GET("/products", handlers.GetProducts)
		v1.GET("/products/:id", handlers.GetProductDetail)
		v1.GET("/products/:id/reviews", handlers.GetProductReviews)

		// Help Center & FAQ
		v1.GET("/help", handlers.GetHelpCenters)

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
			user.PATCH("/store/settings", handlers.UpdateStoreSettings)
			user.GET("/store/orders", handlers.GetStoreOrders)
			user.PATCH("/store/orders/:id/status", handlers.UpdateOrderStatus)
			user.DELETE("/store", handlers.DeleteStore)
			user.POST("/upload", handlers.UploadImage)

			// Store Custom Categories (Etalase)
			user.GET("/store/categories", handlers.GetStoreCategories)
			user.POST("/store/categories", handlers.CreateStoreCategory)
			user.PUT("/store/categories/:id", handlers.UpdateStoreCategory)
			user.DELETE("/store/categories/:id", handlers.DeleteStoreCategory)
			user.POST("/store/categories/assign", handlers.AssignProductsToCategory)

			// Favorites
			user.GET("/favorites", handlers.GetFavorites)
			user.POST("/favorites/:id", handlers.ToggleFavorite)

			// Cart
			user.GET("/cart", handlers.GetCart)
			user.POST("/cart/add", handlers.AddToCart)
			user.PUT("/cart/update/:id", handlers.UpdateCart)
			user.DELETE("/cart/remove/:id", handlers.RemoveFromCart)

			// Checkout & Orders
			user.POST("/checkout/calculate", handlers.CalculateCheckout)
			user.POST("/checkout/create", handlers.CreateOrder)

			// Store Interactions (Follow & Review)
			user.POST("/stores/:id/follow", handlers.ToggleFollowStore)
			user.GET("/stores/:id/following", handlers.CheckFollowStatus)
			user.POST("/products/:id/review", handlers.CreateProductReview)
			user.GET("/products/:id/review/eligibility", handlers.CheckReviewEligibility)

			// Chat System
			user.GET("/conversations", handlers.GetConversations)
			user.GET("/conversations/:id/messages", handlers.GetMessages)
			user.POST("/conversations/start", handlers.StartConversation)
		}

		// WebSocket Engine
		v1.GET("/ws", middleware.AuthMiddleware(), handlers.HandleWebSocket)

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
			admin.PUT("/stores/:id", handlers.AdminUpdateStore)
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

			// Vouchers
			admin.GET("/vouchers", handlers.ListVouchers)
			admin.POST("/vouchers", handlers.CreateVoucher)
			admin.PUT("/vouchers/:id", handlers.UpdateVoucher)
			admin.DELETE("/vouchers/:id", handlers.DeleteVoucher)

			// Upload
			admin.POST("/upload", handlers.AdminUploadImage)
		}
	}
}
