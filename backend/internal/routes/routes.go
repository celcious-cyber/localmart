package routes

import (
	"github.com/gin-gonic/gin"
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
				"status": "LocalMart Backend Golang is running smoothly!",
				"version": "1.0",
			})
		})

		// Tambahkan rute lain di bawah sini nanti.
		// Contoh: v1.GET("/products", controllers.GetProducts)
	}
}
