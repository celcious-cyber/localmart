package models

import (
	"log"

	"gorm.io/gorm"
)

// Migrate menjalankan auto-migration untuk semua model
func Migrate(db *gorm.DB) {
	err := db.AutoMigrate(
		&Banner{},
		&Category{},
		&Product{},
		&Section{},
		&DiscoveryTab{},
		&Admin{},
		&User{},
		&Store{},
		&Driver{},
		&Order{},
		&OrderItem{},
		&ProductImage{},
		&ProductVariant{},
		&Review{},
		&Favorite{},
		&StoreFollower{},
		&CartItem{},
		&StoreCategory{},
		&Conversation{},
		&Message{},
		&HelpCenter{},
	)
	if err != nil {
		log.Fatal("Gagal auto-migrate database:", err)
	}
	
	log.Println("Auto-migrate database berhasil!")
	
	// Seed data awal jika tabel kosong
	// seedData(db) // Dinonaktifkan: Gunakan cmd/seed/main.go untuk demo data
}

/* 
func seedData(db *gorm.DB) {
	// === SEED ADMIN ===
...
	}
}
*/
