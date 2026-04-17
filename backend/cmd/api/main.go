package main

import (
	"log"
	"os"

	"net/http"
	"strings"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/routes"
)

func main() {
	// Memuat konfigurasi dari file .env
	if err := godotenv.Load(); err != nil {
		log.Println("Peringatan: File .env tidak ditemukan, menggunakan environment OS")
	}

	// Inisialisasi koneksi database
	config.ConnectDB()

	// Inisialisasi router Gin
	r := gin.Default()

	// CORS middleware — izinkan Flutter app mengakses API
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Serve static uploads folder
	r.Static("/uploads", "./uploads")

	// Serve admin web panel (SPA Support)
	r.Static("/admin/css", "./web/admin/css")
	r.Static("/admin/js", "./web/admin/js")

	// Admin Web Entry Points
	adminGroup := r.Group("/admin")
	{
		adminGroup.GET("/", func(c *gin.Context) { c.File("./web/admin/index.html") })
		adminGroup.GET("/index.html", func(c *gin.Context) { c.File("./web/admin/index.html") })
		adminGroup.GET("/dashboard.html", func(c *gin.Context) { c.File("./web/admin/dashboard.html") })
	}

	// SPA Fallback for Admin Panel Sub-paths
	r.NoRoute(func(c *gin.Context) {
		path := c.Request.URL.Path
		log.Printf("[DEBUG] NoRoute hit: %s", path)

		if strings.HasPrefix(path, "/admin") {
			// All other sub-paths (like /admin/vouchers) serve dashboard.html
			c.File("./web/admin/dashboard.html")
			return
		}
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Rute tidak ditemukan"})
	})

	// Mendaftarkan semua rute API
	routes.SetupRoutes(r)

	// Buat folder uploads jika belum ada
	if _, err := os.Stat("uploads"); os.IsNotExist(err) {
		os.Mkdir("uploads", 0755)
		log.Println("Folder uploads/ dibuat")
	}

	// Menjalankan server di port 8080 (bisa diubah via env PORT)
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Server berjalan di http://localhost:%s", port)
	r.Run(":" + port)
}
