package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/routes"
	"github.com/joho/godotenv"
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

	// Mendaftarkan semua rute API
	routes.SetupRoutes(r)

	// Menjalankan server di port 8080 (bisa diubah via env PORT)
	r.Run() // secara default mendengarkan localhost:8080
}
