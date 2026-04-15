package main

import (
	"fmt"
	"log"

	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

func main() {
	config.ConnectDB()
	
	// Ensure tables exist
	config.DB.AutoMigrate(&models.User{}, &models.Voucher{}, &models.PointTransaction{})

	var users []models.User
	if err := config.DB.Find(&users).Error; err != nil {
		log.Fatalf("Gagal mengambil data user: %v", err)
	}

	fmt.Printf("Memulai migrasi poin untuk %d user...\n", len(users))

	for _, user := range users {
		tx := config.DB.Begin()

		// 1. Tambah Poin (Jika belum pernah dapet bonus pendaftaran / asumsikan semua blm dapet)
		user.Points += 1000
		if err := tx.Save(&user).Error; err != nil {
			tx.Rollback()
			fmt.Printf("Gagal update poin ID %d: %v\n", user.ID, err)
			continue
		}

		// 2. Catat Transaksi
		pointTx := models.PointTransaction{
			UserID:      user.ID,
			Amount:      1000,
			Type:        "EARN",
			Description: "Bonus Pendaftaran (Migration)",
		}
		if err := tx.Create(&pointTx).Error; err != nil {
			tx.Rollback()
			fmt.Printf("Gagal catat transaksi ID %d: %v\n", user.ID, err)
			continue
		}

		tx.Commit()
		fmt.Printf("ID %d (%s) berhasil mendapatkan 1.000 Poin.\n", user.ID, user.FirstName)
	}

	fmt.Println("\nMigrasi Selesai!")
}
