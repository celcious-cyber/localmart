package models

import (
	"log"

	"golang.org/x/crypto/bcrypt"
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

func seedData(db *gorm.DB) {
	// === SEED ADMIN ===
	var adminCount int64
	db.Model(&Admin{}).Count(&adminCount)
	if adminCount == 0 {
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
		db.Create(&Admin{
			Username: "admin",
			Password: string(hashedPassword),
		})
		log.Println("Seed: Admin default dibuat (admin / admin123)")
	}

	// === SEED SECTIONS ===
	var sectionCount int64
	db.Model(&Section{}).Count(&sectionCount)
	if sectionCount == 0 {
		sections := []Section{
			{Key: "quick_actions", Title: "Quick Actions", SortOrder: 1, IsActive: true},
			{Key: "banner_top", Title: "Banner Highlight", SortOrder: 2, IsActive: true},
			{Key: "categories", Title: "Kategori Produk", SortOrder: 3, IsActive: true},
			{Key: "products", Title: "Produk Kategori", SortOrder: 4, IsActive: true},
			{Key: "banner_slider", Title: "Banner Slider", SortOrder: 5, IsActive: true},
			{Key: "discovery", Title: "Discovery", SortOrder: 6, IsActive: true},
		}
		db.Create(&sections)
		log.Println("Seed: Sections dibuat")
	}

	// === SEED BANNERS ===
	var bannerCount int64
	db.Model(&Banner{}).Count(&bannerCount)
	if bannerCount == 0 {
		banners := []Banner{
			{
				Title:     "CASHBACK 50%",
				ImageURL:  "",
				LinkURL:   "",
				Position:  "top",
				SortOrder: 1,
				IsActive:  true,
			},
			{
				Title:     "Promo Akhir Pekan",
				ImageURL:  "",
				LinkURL:   "",
				Position:  "top",
				SortOrder: 2,
				IsActive:  true,
			},
			{
				Title:     "Gratis Ongkir",
				ImageURL:  "",
				LinkURL:   "",
				Position:  "slider",
				SortOrder: 1,
				IsActive:  true,
			},
			{
				Title:     "Flash Sale LocalMart",
				ImageURL:  "",
				LinkURL:   "",
				Position:  "slider",
				SortOrder: 2,
				IsActive:  true,
			},
		}
		db.Create(&banners)
		log.Println("Seed: Banners dibuat")
	}

	// === SEED CATEGORIES ===
	var catCount int64
	db.Model(&Category{}).Count(&catCount)
	if catCount <= 4 { // If old English categories or empty
		// Simple clean start for categories
		db.Exec("DELETE FROM categories")
		categories := []Category{
			{Name: "Hasil Bumi", Slug: "hasil-bumi", IconName: "agriculture", SortOrder: 1, Type: "BARANG", IsActive: true},
			{Name: "Pangan Lokal", Slug: "pangan-lokal", IconName: "restaurant", SortOrder: 2, Type: "BARANG", IsActive: true},
			{Name: "Kerajinan UMKM", Slug: "kerajinan-umkm", IconName: "brush", SortOrder: 3, Type: "BARANG", IsActive: true},
			{Name: "Sewa & Rental", Slug: "sewa-rental", IconName: "car_rental", SortOrder: 4, Type: "RENTAL", IsActive: true},
			{Name: "Wisata Lokal", Slug: "wisata-lokal", IconName: "tour", SortOrder: 5, Type: "WISATA", IsActive: true},
			{Name: "Jasa Ahli", Slug: "jasa-ahli", IconName: "handyman", SortOrder: 6, Type: "JASA", IsActive: true},
			{Name: "Elektronik", Slug: "elektronik", IconName: "devices", SortOrder: 7, Type: "BARANG", IsActive: true},
		}
		db.Create(&categories)
		log.Println("Seed: Categories (Localized) dibuat")
	}

	// === SEED STORES ===
	var storeCount int64
	db.Model(&Store{}).Count(&storeCount)
	if storeCount == 0 {
		// Ambil User
		var user User
		db.First(&user)
		if user.ID != 0 {
			store := Store{
				UserID:      user.ID,
				Name:        "KSB Kuliner",
				Category:    "Makanan & Minuman",
				Description: "Pusat kuliner terbaik di Sumbawa Barat.",
				Address:     "Jl. Raya Taliwang No. 123",
				Village:     "Kuang",
				District:    "Taliwang",
				IsVerified:  true,
				IsActive:    true,
				Status:      "approved",
			}
			db.Create(&store)
			log.Println("Seed: Store default dibuat")
		}
	}

	// === SEED PRODUCTS ===
	var productCount int64
	db.Model(&Product{}).Count(&productCount)
	if productCount == 0 {
		// Ambil category IDs
		var categories []Category
		db.Find(&categories)

		catMap := make(map[string]uint)
		for _, c := range categories {
			catMap[c.Slug] = c.ID
		}

		products := []Product{
			// Food & Drink
			{
				CategoryID:  catMap["food-drink"],
				Name:        "Nasi Goreng Spesial KSB",
				Description: "Nasi goreng khas Sumbawa Barat dengan bumbu rempah lokal yang kaya rasa.",
				Price:       90000,
				ImageURL:    "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			{
				CategoryID:  catMap["food-drink"],
				Name:        "Sate Ayam Taliwang",
				Description: "Sate ayam bumbu Taliwang asli, pedas dan gurih khas NTB.",
				Price:       85000,
				ImageURL:    "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			{
				CategoryID:  catMap["food-drink"],
				Name:        "Ayam Bakar Bumbu Rujak",
				Description: "Ayam bakar dengan bumbu rujak manis pedas yang menggugah selera.",
				Price:       75000,
				ImageURL:    "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			{
				CategoryID:  catMap["food-drink"],
				Name:        "Ikan Bakar Sambal Matah",
				Description: "Ikan segar bakar arang dengan sambal matah Bali yang segar.",
				Price:       95000,
				ImageURL:    "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			// Fashion
			{
				CategoryID:  catMap["fashion"],
				Name:        "Kain Tenun KSB",
				Description: "Kain tenun tradisional Sumbawa Barat dengan motif khas.",
				Price:       250000,
				ImageURL:    "https://images.unsplash.com/photo-1558171813-4c088753af8f?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			{
				CategoryID:  catMap["fashion"],
				Name:        "Batik Sasambo",
				Description: "Batik motif Sasambo asli buatan pengrajin lokal KSB.",
				Price:       180000,
				ImageURL:    "https://images.unsplash.com/photo-1594938328870-9623159c8c99?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			// Elektronik
			{
				CategoryID:  catMap["elektronik"],
				Name:        "Charger Fast Charging",
				Description: "Charger 65W fast charging kompatibel semua smartphone.",
				Price:       120000,
				ImageURL:    "https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			{
				CategoryID:  catMap["elektronik"],
				Name:        "TWS Earbuds Pro",
				Description: "Earbuds wireless dengan noise cancellation dan bass yang jernih.",
				Price:       350000,
				ImageURL:    "https://images.unsplash.com/photo-1590658268037-6bf12f032f55?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			// Asesoris
			{
				CategoryID:  catMap["asesoris"],
				Name:        "Gelang Mutiara Lombok",
				Description: "Gelang mutiara asli Lombok, cantik dan elegan.",
				Price:       150000,
				ImageURL:    "https://images.unsplash.com/photo-1611652022419-a9419f74343d?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
			{
				CategoryID:  catMap["asesoris"],
				Name:        "Tas Anyaman Rotan",
				Description: "Tas rotan anyaman tangan khas NTB, trendi dan ramah lingkungan.",
				Price:       200000,
				ImageURL:    "https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&q=80&w=400",
				IsActive:    true,
			},
		}
		db.Create(&products)
		log.Println("Seed: Products dibuat")

		// === SEED VARIANTS ===
		var p Product
		db.Where("name = ?", "Nasi Goreng Spesial KSB").First(&p)
		if p.ID != 0 {
			variants := []ProductVariant{
				{ProductID: p.ID, Name: "Porsi Kecil", Price: 75000, Stock: 20},
				{ProductID: p.ID, Name: "Porsi Besar", Price: 90000, Stock: 15},
			}
			db.Create(&variants)
			log.Println("Seed: Product Variants dibuat")
		}
	}

	// === SEED DISCOVERY TABS ===
	var discCount int64
	db.Model(&DiscoveryTab{}).Count(&discCount)
	if discCount == 0 {
		tabs := []DiscoveryTab{
			{Name: "Panen Hari Ini", SortOrder: 1, IsActive: true},
			{Name: "UMKM Pilihan", SortOrder: 2, IsActive: true},
			{Name: "Eksplore KSB", SortOrder: 3, IsActive: true},
			{Name: "Local Mart", SortOrder: 4, IsActive: true},
		}
		db.Create(&tabs)
		log.Println("Seed: Discovery Tabs dibuat")
	}
}
