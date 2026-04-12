package config

import (
	"log"

	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

// ConnectDB menginisialisasi koneksi SQLite menggunakan GORM
func ConnectDB() {
	// Koneksi ke file database SQLite lokal (localmart.db)
	database, err := gorm.Open(sqlite.Open("localmart.db"), &gorm.Config{})

	if err != nil {
		log.Println("Peringatan: Gagal membuat/terhubung ke database SQLite:", err)
		return
	}

	DB = database
	log.Println("Berhasil terhubung ke database SQLite (localmart.db)!")
}

