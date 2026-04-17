package main

import (
	"log"
	"os"
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

	// CORS middleware — Mendukung pemisahan Admin Panel dan testing via LAN/IP
	r.Use(func(c *gin.Context) {
		// Dapatkan origin dari request
		origin := c.Request.Header.Get("Origin")
		
		// Set header CORS
		// Catatan: Menggunakan "*" adalah yang paling fleksibel untuk development & LAN testing.
		// Untuk produksi, ganti "*" dengan origin spesifik (misal: "http://admin.localmart.com")
		c.Writer.Header().Set("Access-Control-Allow-Origin", origin) 
		if origin == "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		}
		
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Serve static uploads folder (Tetap dipertahankan untuk gambar produk)
	r.Static("/uploads", "./uploads")

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
