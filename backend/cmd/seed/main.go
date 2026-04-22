package main

import (
	"log"
	"strings"

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
		&models.ModuleSpecification{},
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
	db.Exec("DELETE FROM drivers")
	db.Exec("DELETE FROM users")
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

	// 2.6 Seed Admin (KEEP EXISTING)
	log.Println("[Seeder] Ensuring Admin Account...")
	var existingAdmin models.Admin
	if err := db.Where("username = ?", "admin").First(&existingAdmin).Error; err != nil {
		adminPassword, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
		db.Create(&models.Admin{
			Username: "admin",
			Password: string(adminPassword),
		})
	}

	// 3. Seed 8 Specific Role Accounts
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	
	roles := []struct {
		Name  string
		Email string
		Phone string
	}{
		{"Mitra Driver", "driver@localmart.com", "081001"},
		{"Merchant UMKM", "umkm@localmart.com", "081002"},
		{"Kuliner Lokal", "food@localmart.com", "081003"},
		{"Rental KSB", "rental@localmart.com", "081004"},
		{"Penyedia Jasa", "jasa@localmart.com", "081005"},
		{"Petani Modern", "petani@localmart.com", "081006"},
		{"Pemandu Wisata", "wisata@localmart.com", "081007"},
		{"Barang Second", "second@localmart.com", "081008"},
		{"Properti & Kost", "kost@localmart.com", "081009"},
	}

	log.Println("[Seeder] Creating specific role accounts...")
	for _, r := range roles {
		user := models.User{
			FirstName: r.Name,
			LastName:  "(Tester)",
			Email:     r.Email,
			Phone:     r.Phone,
			Password:  string(hashedPassword),
			Points:    5000,
		}
		db.Create(&user)
		
		// Create appropriate profiles based on role
		if r.Email == "driver@localmart.com" {
			db.Create(&models.Driver{
				UserID:      user.ID,
				VehicleType: "Motor",
				PlateNumber: "EA 1234 XX",
				Status:      "approved",
				IsActive:    true,
			})
		} else {
			// Create Store for others
			store := models.Store{
				UserID:      user.ID,
				Name:        "Toko " + r.Name,
				Category:    "Official",
				Description: "Akun pengujian resmi untuk kategori " + r.Name,
				Status:      "approved",
				IsActive:    true,
			}
			
			// Map modules
			var modCode string
			switch r.Email {
			case "umkm@localmart.com": modCode = "umkm"
			case "food@localmart.com": modCode = "food"
			case "rental@localmart.com": modCode = "rental"
			case "jasa@localmart.com": modCode = "jasa"
			case "petani@localmart.com": modCode = "bumi"
			case "wisata@localmart.com": modCode = "wisata"
			case "second@localmart.com": modCode = "second"
			case "kost@localmart.com": modCode = "kost"
			}
			
			if modCode != "" {
				store.BusinessModules = []models.BusinessModule{moduleMap[modCode], moduleMap["mart"]}
			}
			db.Create(&store)
		}
	}

	// 3.5 Seed Default Specifications for each module
	log.Println("[Seeder] Seeding default Module Specifications...")
	specs := []models.ModuleSpecification{
		// Kost
		{ModuleCode: "kost", Label: "Luas Kamar", Key: "luas_area", InputType: "text", IsRequired: true, SortOrder: 1},
		{ModuleCode: "kost", Label: "Fasilitas Kamar", Key: "fasilitas", InputType: "text", IsRequired: false, SortOrder: 2},
		{ModuleCode: "kost", Label: "Fasum Terdekat", Key: "fasum", InputType: "text", IsRequired: false, SortOrder: 3},
		
		// Wisata
		{ModuleCode: "wisata", Label: "Titik Kumpul", Key: "meeting_point", InputType: "text", IsRequired: true, SortOrder: 1},
		{ModuleCode: "wisata", Label: "Ada Kedai Makan?", Key: "ada_kedai", InputType: "boolean", IsRequired: false, SortOrder: 2},
		
		// Food
		{ModuleCode: "food", Label: "Estimasi Masak (Menit)", Key: "cook_time", InputType: "number", IsRequired: false, SortOrder: 1},
		{ModuleCode: "food", Label: "Level Pedas", Key: "spicy_level", InputType: "select", Options: "Tidak Pedas, Sedang, Pedas, Sangat Pedas", IsRequired: false, SortOrder: 2},
	}
	for _, s := range specs {
		db.Create(&s)
	}

	log.Println("Seeding akun selesai! Melanjutkan ke metadata UI...")

	// 4. Seed Banners (Modular)
	banners_seed := []models.Banner{
		{Title: "Voucher Weekend", ImageURL: "https://images.unsplash.com/photo-1607082349566-187342175e2f?auto=format&fit=crop&q=80&w=800", Position: "home,food", SortOrder: 0, IsActive: true},
		{Title: "Promo Member Baru", ImageURL: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&q=80&w=800", Position: "home", SortOrder: 1, IsActive: true},
		{Title: "Explore Alam Sumbawa", ImageURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=800", Position: "home", SortOrder: 2, IsActive: true},
	}
	db.Create(&banners_seed)

	// 5. Seed Sections (Modular Discovery)
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

	// 6. Seed Discovery Tabs
	tabs_seed := []models.DiscoveryTab{
		{Name: "Panen Hari Ini", SortOrder: 1, IsActive: true},
		{Name: "UMKM Pilihan", SortOrder: 2, IsActive: true},
		{Name: "Eksplore KSB", SortOrder: 3, IsActive: true},
		{Name: "Local Mart", SortOrder: 4, IsActive: true},
	}
	db.Create(&tabs_seed)

	// 7. Seed Help Center
	helpCenters := []models.HelpCenter{
		{Category: "Panduan", Title: "Cara Pesan Jasa", Content: "Pilih jasa, hubungi penyedia, dan bayar aman di aplikasi.", Icon: "handyman", SortOrder: 1},
		{Category: "Keamanan", Title: "Transaksi Aman", Content: "LocalMart menjamin dana Anda kembali jika layanan tidak sesuai.", Icon: "security", SortOrder: 2},
	}
	db.Create(&helpCenters)

	log.Println("Seeding metadata UI selesai!")
}
