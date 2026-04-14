package main

import (
	"fmt"
	"log"

	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// 1. Initialize DB
	config.ConnectDB()

	// 2. Check if admin exists
	var admin models.Admin
	result := config.DB.Where("username = ?", "admin").First(&admin)

	// 3. Prepare Password
	password := "adminpassword"
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatal("Gagal hash password:", err)
	}

	if result.Error == nil {
		// Admin exists, update password
		fmt.Println("Admin 'admin' ditemukan. Mengupdate password...")
		admin.Password = string(hashedPassword)
		if err := config.DB.Save(&admin).Error; err != nil {
			log.Fatal("Gagal update password admin:", err)
		}
		fmt.Println("✅ Password Admin berhasil direset!")
	} else {
		// Admin doesn't exist, create new
		fmt.Println("Admin 'admin' tidak ditemukan. Membuat baru...")
		admin = models.Admin{
			Username: "admin",
			Password: string(hashedPassword),
		}
		if err := config.DB.Create(&admin).Error; err != nil {
			log.Fatal("Gagal membuat admin:", err)
		}
		fmt.Println("✅ Admin Default Berhasil Dibuat!")
	}

	fmt.Println("-------------------------------")
	fmt.Println("Username : admin")
	fmt.Println("Password : adminpassword")
	fmt.Println("-------------------------------")
	fmt.Println("Gunakan kredensial ini untuk masuk ke dashboard admin.")
}
