package main

import (
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

func main() {
	// 1. Initialize DB
	config.ConnectDB()

	// 2. Find the first store
	var store models.Store
	if err := config.DB.First(&store).Error; err != nil {
		log.Fatalf("Gagal menemukan toko: %v. Pastikan Anda sudah mendaftar sebagai toko.", err)
	}
	fmt.Printf("Seeding data untuk toko: %s (ID: %d)\n", store.Name, store.ID)

	// 3. Find some products for this store
	var products []models.Product
	if err := config.DB.Where("store_id = ?", store.ID).Find(&products).Error; err != nil || len(products) == 0 {
		log.Fatalf("Toko tidak memiliki produk. Silakan tambah produk dulu.")
	}

	// 4. Find or create a dummy user as buyer
	var buyer models.User
	if err := config.DB.Where("email = ?", "customer@example.com").First(&buyer).Error; err != nil {
		buyer = models.User{
			FirstName: "Budi",
			LastName:  "Pelanggan",
			Email:     "customer@example.com",
			Phone:     "081234567890",
			Password:  "password123", // Ini hash aslinya harusnya, tapi untuk seed ini ok
		}
		config.DB.Create(&buyer)
		fmt.Println("User dummy 'Budi Pelanggan' dibuat.")
	}

	// 5. Generate Orders
	statuses := []string{"pending", "pending", "pending", "processed", "shipping", "completed", "completed"}
	
	for i := 1; i <= 7; i++ {
		status := statuses[i-1]
		orderNumber := fmt.Sprintf("ORD-%d%d", time.Now().Unix()%10000, i)
		
		// Random products for this order
		nItems := rand.Intn(2) + 1
		var orderItems []models.OrderItem
		var totalAmount float64
		
		for j := 0; j < nItems; j++ {
			p := products[rand.Intn(len(products))]
			qty := rand.Intn(3) + 1
			orderItems = append(orderItems, models.OrderItem{
				ProductID: p.ID,
				Quantity:  qty,
				PriceAtPurchase: p.Price,
			})
			totalAmount += p.Price * float64(qty)
			
			// Increment sold count
			config.DB.Model(&p).Update("sold", p.Sold + qty)
		}

		order := models.Order{
			UserID:      buyer.ID,
			StoreID:     store.ID,
			OrderNumber: orderNumber,
			TotalAmount: totalAmount,
			Status:      status,
			Address:     "Jl. Pesanggrahan No. 12, Taliwang, KSB",
			Items:       orderItems,
			CreatedAt:   time.Now().Add(-time.Duration(i) * time.Hour),
		}

		if err := config.DB.Create(&order).Error; err != nil {
			fmt.Printf("Gagal buat order %d: %v\n", i, err)
		} else {
			fmt.Printf("Berhasil buat order %s dengan status %s\n", orderNumber, status)
			
			// If completed, update store balance
			if status == "completed" {
				store.Balance += totalAmount
			}
		}
	}

	// Update store balance in DB
	config.DB.Save(&store)
	fmt.Printf("\nSeed Selesai! Saldo toko sekarang: Rp %.2f\n", store.Balance)
	fmt.Println("Silakan buka aplikasi LocalMart dan cek halaman Profil -> Toko.")
}
