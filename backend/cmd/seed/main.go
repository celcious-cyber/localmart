package main

import (
	"fmt"
	"log"
	"math/rand"
	"strings"
	"time"

	"github.com/glebarez/sqlite"
	"github.com/ksb/localmart/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Simple slug generator
func makeSlug(name string) string {
	return strings.ToLower(strings.ReplaceAll(name, " ", "-"))
}

// Global map for category caching
var categoryCache = make(map[string]uint)

func getOrCreateCategory(db *gorm.DB, name string, icon string, catType string, serviceType string) uint {
	if id, ok := categoryCache[name]; ok {
		return id
	}

	var cat models.Category
	err := db.Where("name = ?", name).First(&cat).Error
	if err == nil {
		// Update existing category service_type if needed for re-seeding
		db.Model(&cat).Update("service_type", serviceType)
		categoryCache[name] = cat.ID
		return cat.ID
	}

	// Not found, create it
	log.Printf("[Seeder] Category '%s' not found. Creating new...", name)
	newCat := models.Category{
		Name:        name,
		Slug:        makeSlug(name),
		IconName:    icon,
		Type:        catType,
		ServiceType: serviceType,
		IsActive:    true,
	}
	db.Create(&newCat)
	log.Printf("[Seeder] Created category '%s' with ID: %d", name, newCat.ID)
	
	categoryCache[name] = newCat.ID
	return newCat.ID
}

func main() {
	db, err := gorm.Open(sqlite.Open("localmart.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Gagal terhubung ke database:", err)
	}

	log.Println("Memulai proses seeding data 'Sumbawa Vibe'...")

	// 0. Pastikan tabel ada (Migrasi)
	db.AutoMigrate(
		&models.Admin{},
		&models.Category{},
		&models.Store{},
		&models.Product{},
		&models.Conversation{},
		&models.Message{},
		&models.HelpCenter{},
		&models.User{},
		&models.Banner{},
		&models.Section{},
		&models.DiscoveryTab{},
		&models.BusinessModule{},
	)

	// 1. Bersihkan data lama (Urutan penting untuk Foregin Key)
	db.Exec("DELETE FROM admins")
	db.Exec("DELETE FROM help_centers")
	db.Exec("DELETE FROM messages")
	db.Exec("DELETE FROM conversations")
	db.Exec("DELETE FROM reviews")
	db.Exec("DELETE FROM product_store_categories")
	db.Exec("DELETE FROM product_variant_options")
	db.Exec("DELETE FROM product_variants")
	db.Exec("DELETE FROM product_images")
	db.Exec("DELETE FROM products")
	db.Exec("DELETE FROM store_categories")
	db.Exec("DELETE FROM stores")
	db.Exec("DELETE FROM categories")
	db.Exec("DELETE FROM banners")
	db.Exec("DELETE FROM sections")
	db.Exec("DELETE FROM discovery_tabs")
	db.Exec("DELETE FROM store_business_modules")
	db.Exec("DELETE FROM business_modules")

	// 2. Pre-seed Categories (Ensuring IDs are known)
	catBase := []struct {
		Name    string
		Icon    string
		Type    string
		Service string
	}{
		// 1. Food
		{"Kuliner Lokal", "restaurant", "BARANG", "food"},
		{"Nasi Goreng", "restaurant", "BARANG", "food"},
		{"Mie & Bakso", "ramen_dining", "BARANG", "food"},
		// 2. Kost
		{"Kost Putra", "home_work", "JASA", "kost"},
		{"Kost Putri", "home_work", "JASA", "kost"},
		{"Kontrakan", "house", "JASA", "kost"},
		// 3. Rental
		{"Sewa Motor", "two_wheeler", "RENTAL", "rental"},
		{"Sewa Mobil", "directions_car", "RENTAL", "rental"},
		// 4. Transport
		{"Tiket Damri", "directions_bus", "JASA", "transport"},
		{"Travel KSB", "airport_shuttle", "JASA", "transport"},
		// 5. Jasa Utama
		{"Servis AC", "ac_unit", "JASA", "jasa"},
		{"Tukang Las", "handyman", "JASA", "jasa"},
		{"Sol Sepatu", "style", "JASA", "jasa"},
		// 6. UMKM Unggulan
		{"Kerajinan Khas", "brush", "BARANG", "umkm"},
		{"Souvenir KSB", "shopping_bag", "BARANG", "umkm"},
		// 7. Panen Hasil Bumi
		{"Madu Hutan", "local_drink", "BARANG", "bumi"},
		{"Beras Organik", "agriculture", "BARANG", "bumi"},
		{"Jagung Kering", "agriculture", "BARANG", "bumi"},
		// 8. Eksplor Wisata
		{"Tour Guiding", "explore", "JASA", "wisata"},
		{"Sewa Camping", "terrain", "JASA", "wisata"},
		// 9. Barang Bekas
		{"Elektronik Bekas", "devices", "BARANG", "second"},
		{"Pakaian Preloved", "checkroom", "BARANG", "second"},

		// Extra categories for Quick Actions (not for discovery sections)
		{"Layanan Kurir", "delivery_dining", "JASA", "send"},
		{"Topup & Tagihan", "receipt_long", "JASA", "bill"},
	}

	for _, c := range catBase {
		getOrCreateCategory(db, c.Name, c.Icon, c.Type, c.Service)
	}
	
	// 2.5 Seed Business Modules (9 Utama)
	log.Println("[Seeder] Seeding 9 Business Modules...")
	busModules := []models.BusinessModule{
		{Code: "food", Name: "Kuliner & Resto"},
		{Code: "kost", Name: "Properti & Penginapan"},
		{Code: "rental", Name: "Rental Kendaraan"},
		{Code: "transport", Name: "Tiket & Transportasi"},
		{Code: "jasa", Name: "Layanan Jasa"},
		{Code: "umkm", Name: "Produk UMKM & Kriya"},
		{Code: "bumi", Name: "Agrikultur & Pertanian"},
		{Code: "wisata", Name: "Pariwisata & Tur"},
		{Code: "second", Name: "Barang Preloved"},
		{Code: "mart", Name: "Mart & Lainnya"},
	}
	for i := range busModules {
		db.Create(&busModules[i])
	}
	
	var martModule models.BusinessModule
	db.Where("code = ?", "mart").First(&martModule)
	
	// Map to help assigning
	moduleMap := make(map[string]models.BusinessModule)
	for _, m := range busModules {
		moduleMap[m.Code] = m
	}

	// 2.6 Seed Admin (NEW)
	log.Println("[Seeder] Seeding Admin Account...")
	adminPassword, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	db.Create(&models.Admin{
		Username: "admin",
		Password: string(adminPassword),
	})

	// 3. Seed Users (Demo User & Stores Owner)
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	
	demoUser := models.User{
		FirstName: "Muhammad",
		LastName:  "Akmal",
		Email:     "user@mail.com",
		Phone:     "081234567890",
		Password:  string(hashedPassword), // WAJIB HASHED
		AvatarURL: "https://i.pravatar.cc/150?u=akmal",
	}
	db.Create(&demoUser)

	celciousUser := models.User{
		FirstName: "Celcious",
		LastName:  "Admin",
		Email:     "celcious@mail.com",
		Phone:     "08777666555",
		Password:  string(hashedPassword),
		AvatarURL: "https://i.pravatar.cc/150?u=celcious",
	}
	db.Create(&celciousUser)

	// 4. Seed Stores (10 Stores)
	stores := []models.Store{
		{
			UserID:      celciousUser.ID,
			Name:        "CELCIOUS STORE",
			Category:    "Official Merchant",
			Description: "Toko resmi LocalMart yang menyediakan berbagai kebutuhan gadget dan aksesoris premium.",
			Address:     "Jl. Sudirman, Taliwang, KSB",
			ImageURL:    "https://images.unsplash.com/photo-1531297484001-80022131f5a1?auto=format&fit=crop&q=80&w=400",
			Status:      "approved",
			Level:       "mall",
			IsVerified:  true,
		},
		{
			UserID:      demoUser.ID,
			Name:        "Lesehan Taliwang Berkah",
			Category:    "Kuliner Lokal",
			Description: "Ayam Taliwang asli dengan bumbu rempah rahasia keluarga sejak 1990.",
			Address:     "Jl. Raya Taliwang No. 12, KSB",
			ImageURL:    "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=400",
			Status:      "approved",
			Level:       "star",
			IsVerified:  true,
		},
		{
			UserID:      demoUser.ID + 10,
			Name:        "Tenun Mantar Jaya",
			Category:    "Kerajinan Khas",
			Description: "Pusat kain tenun tradisional Mantar dengan pewarna alami.",
			Address:     "Desa Mantar, Poto Tano, KSB",
			ImageURL:    "https://images.unsplash.com/photo-1558171813-4c088753af8f?auto=format&fit=crop&q=80&w=400",
			Status:      "approved",
			Level:       "regular",
		},
		{
			UserID:      demoUser.ID + 11,
			Name:        "Madu Asli KSB",
			Category:    "Hasil Bumi",
			Description: "Madu hutan murni dari pegunungan Sumbawa Barat.",
			Address:     "Kecamatan Jereweh, KSB",
			ImageURL:    "https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&q=80&w=400",
			Status:      "approved",
		},
		{
			UserID:      demoUser.ID + 12,
			Name:        "Apotek Maluk Sehat",
			Category:    "Kesehatan",
			Description: "Melayani obat-obatan dan konsultasi kesehatan 24 jam.",
			Address:     "Jl. Pantai Maluk, Maluk, KSB",
			ImageURL:    "https://images.unsplash.com/photo-1586015555751-63bb77f4322a?auto=format&fit=crop&q=80&w=400",
			Status:      "approved",
		},
		{
			UserID:      demoUser.ID + 13,
			Name:        "Sewa Motor Maluk Beach",
			Category:    "Sewa & Rental",
			Description: "Rental motor harian untuk explore pantai-pantai indah di Sekongkang.",
			Address:     "Dekat Gerbang Maluk Town Site, KSB",
			ImageURL:    "https://images.unsplash.com/photo-1558981403-c5f91cbba527?auto=format&fit=crop&q=80&w=400",
			Status:      "approved",
		},
	}

	// Assign 'mart' module to all stores by default + specific modules
	for i := range stores {
		stores[i].BusinessModules = []models.BusinessModule{martModule}
		
		// Map existing category to new modules
		cat := stores[i].Category
		switch cat {
		case "Kuliner Lokal":
			stores[i].BusinessModules = append(stores[i].BusinessModules, moduleMap["food"])
		case "Kerajinan Khas":
			stores[i].BusinessModules = append(stores[i].BusinessModules, moduleMap["umkm"])
		case "Hasil Bumi":
			stores[i].BusinessModules = append(stores[i].BusinessModules, moduleMap["bumi"])
		case "Sewa & Rental":
			stores[i].BusinessModules = append(stores[i].BusinessModules, moduleMap["rental"])
		}
		
		db.Create(&stores[i])
	}
	
	// Simpan ID toko yang valid
	var storeIDs []uint
	for _, s := range stores {
		storeIDs = append(storeIDs, s.ID)
	}
	log.Printf("[Seeder] Successfully seeded %d stores.", len(storeIDs))

	// 5. Seed Products (Modular Distribution)
	log.Println("[Seeder] Generating products for 9 discovery modules...")
	totalProducts := 0

	for _, cat := range catBase {
		// Skip non-discovery categories if needed, but for dummy data we fill everything
		catID := getOrCreateCategory(db, cat.Name, cat.Icon, cat.Type, cat.Service)
		
		// Create 3-5 products for each category
		numProducts := 3 + rand.Intn(3)
		for i := 1; i <= numProducts; i++ {
			storeID := storeIDs[rand.Intn(len(storeIDs))]
			
			price := 15000.0 + float64(rand.Intn(500))*1000.0
			switch cat.Service {
			case "food":
				price = 10000.0 + float64(rand.Intn(40))*1000.0
			case "second":
				price = 50000.0 + float64(rand.Intn(100))*5000.0
			}

			imgTag := strings.ToLower(cat.Name)
			if imgTag == "kuliner lokal" || imgTag == "nasi goreng" {
				imgTag = "food"
			}

			product := models.Product{
				StoreID:     storeID,
				CategoryID:  catID,
				Name:        fmt.Sprintf("%s %d", cat.Name, i),
				Price:       price,
				ImageURL:    fmt.Sprintf("https://images.unsplash.com/featured/?%s", imgTag),
				Description: fmt.Sprintf("Layanan/Produk unggulan %s terbaik di Sumbawa Barat untuk Anda.", cat.Name),
				ServiceType: cat.Service,
				IsActive:    true,
				IsFresh:     cat.Service == "food" || cat.Service == "bumi",
				IsFeatured:  cat.Service == "umkm" || i == 1,
			}
			db.Create(&product)
			totalProducts++
		}
	}
	log.Printf("[Seeder] Successfully seeded %d products.", totalProducts)

	// 6. Seed Conversations & Chat Flow
	conv := models.Conversation{
		Participant1ID: demoUser.ID,
		Participant2ID: celciousUser.ID,
		LastMessage:    "Ready Kak, silakan diorder.",
		UpdatedAt:      time.Now().Add(-45 * time.Minute),
	}
	db.Create(&conv)

	messages := []models.Message{
		{
			ConversationID: conv.ID,
			SenderID:       demoUser.ID,
			ReceiverID:     celciousUser.ID,
			Content:        "Halo, apakah ini bisa dikirim hari ini?",
			CreatedAt:      time.Now().Add(-60 * time.Minute),
		},
		{
			ConversationID: conv.ID,
			SenderID:       celciousUser.ID,
			ReceiverID:     demoUser.ID,
			Content:        "Tentu Kak, silakan dipesan sebelum jam 4.",
			CreatedAt:      time.Now().Add(-45 * time.Minute),
		},
	}
	db.Create(&messages)

	// 7. Seed Help Center
	helpCenters := []models.HelpCenter{
		{Category: "Panduan", Title: "Cara Pesan Jasa", Content: "Pilih jasa, hubungi penyedia, dan bayar aman di aplikasi.", Icon: "handyman", SortOrder: 1},
		{Category: "Keamanan", Title: "Transaksi Aman", Content: "LocalMart menjamin dana Anda kembali jika layanan tidak sesuai.", Icon: "security", SortOrder: 2},
	}
	db.Create(&helpCenters)

	// 8. Seed Banners (Modular)
	banners_seed := []models.Banner{
		// Multi-Module Banner (Home & Food)
		{Title: "Voucher Weekend", ImageURL: "https://images.unsplash.com/photo-1607082349566-187342175e2f?auto=format&fit=crop&q=80&w=800", Position: "home,food", SortOrder: 0, IsActive: true},
		
		// Home Banners
		{Title: "Promo Member Baru", ImageURL: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&q=80&w=800", Position: "home", SortOrder: 1, IsActive: true},
		{Title: "Explore Alam Sumbawa", ImageURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=800", Position: "home", SortOrder: 2, IsActive: true},
		
		// Food Banners
		{Title: "Diskon Kuliner Malam", ImageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=800", Position: "food", SortOrder: 1, IsActive: true},
		{Title: "Ayam Taliwang Spesial", ImageURL: "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80&w=800", Position: "food", SortOrder: 2, IsActive: true},

		// UMKM Banners
		{Title: "Pameran Kerajinan Mantar", ImageURL: "https://images.unsplash.com/photo-1558171813-4c088753af8f?auto=format&fit=crop&q=80&w=800", Position: "umkm", SortOrder: 1, IsActive: true},
		{Title: "Tenun Khas KSB", ImageURL: "https://images.unsplash.com/photo-1558171813-4c088753af8f?auto=format&fit=crop&q=80&w=400", Position: "umkm", SortOrder: 2, IsActive: true},
	}
	db.Create(&banners_seed)

	// 9. Seed Sections (Modular Discovery 9 Modules)
	sections_seed := []models.Section{
		{Key: "banner_top", Title: "Promo Terkini", SortOrder: 1, IsActive: true},
		{Key: "quick_actions", Title: "Layanan Kami", SortOrder: 2, IsActive: true},
		{Key: "module_food", Title: "Kuliner & Resto", SortOrder: 3, IsActive: true},
		{Key: "module_kost", Title: "Properti & Penginapan", SortOrder: 4, IsActive: true},
		{Key: "module_rental", Title: "Rental Kendaraan", SortOrder: 5, IsActive: true},
		{Key: "module_transport", Title: "Tiket & Transportasi", SortOrder: 6, IsActive: true},
		{Key: "module_jasa", Title: "Layanan Jasa", SortOrder: 7, IsActive: true},
		{Key: "module_umkm", Title: "Produk UMKM & Kriya", SortOrder: 8, IsActive: true},
		{Key: "module_bumi", Title: "Agrikultur & Pertanian", SortOrder: 9, IsActive: true},
		{Key: "module_wisata", Title: "Pariwisata & Tur", SortOrder: 10, IsActive: true},
		{Key: "module_second", Title: "Barang Preloved", SortOrder: 11, IsActive: true},
		{Key: "products", Title: "Rekomendasi", SortOrder: 12, IsActive: true},
	}
	db.Create(&sections_seed)

	// 10. Seed Discovery Tabs
	tabs_seed := []models.DiscoveryTab{
		{Name: "Panen Hari Ini", SortOrder: 1, IsActive: true},
		{Name: "UMKM Pilihan", SortOrder: 2, IsActive: true},
		{Name: "Eksplore KSB", SortOrder: 3, IsActive: true},
		{Name: "Local Mart", SortOrder: 4, IsActive: true},
	}
	db.Create(&tabs_seed)

	log.Println("Seeding selesai! Semua data tersambung dengan benar.")
}
