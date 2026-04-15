package handlers

import (
	"crypto/rand"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/middleware"
	"github.com/ksb/localmart/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
)

type UserRegisterRequest struct {
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name"`
	Email     string `json:"email" binding:"required,email"`
	Phone     string `json:"phone" binding:"required"`
	Password  string `json:"password" binding:"required,min=6"`
}

type UserLoginRequest struct {
	Identifier string `json:"identifier" binding:"required"` // Bisa Email atau Phone
	Password   string `json:"password" binding:"required"`
}

// UserRegister - POST /api/v1/auth/register
func UserRegister(c *gin.Context) {
	var req UserRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid: " + err.Error()})
		return
	}

	// Cek apakah email/phone sudah terdaftar
	var existingUser models.User
	if config.DB.Where("email = ? OR phone = ?", req.Email, req.Phone).First(&existingUser).RowsAffected > 0 {
		c.JSON(http.StatusConflict, gin.H{"success": false, "message": "Email atau Nomor HP sudah terdaftar"})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal memproses password"})
		return
	}

	// ══════════════════════════════════════════════
	// START TRANSACTION
	// ══════════════════════════════════════════════
	tx := config.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	user := models.User{
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Phone:     req.Phone,
		Password:  string(hashedPassword),
		Points:    1000,
	}

	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menyimpan user"})
		return
	}

	// Catat Transaksi Poin Bonus
	pointTx := models.PointTransaction{
		UserID:      user.ID,
		Amount:      1000,
		Type:        "EARN",
		Description: "Bonus Pendaftaran",
	}
	if err := tx.Create(&pointTx).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mencatat bonus poin"})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal finalisasi registrasi"})
		return
	}

	// Langsung login-kan setelah register
	token, _ := middleware.GenerateToken(user.ID, user.Email, "user")

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Registrasi Berhasil! Anda mendapatkan bonus 1.000 Poin.",
		"data": gin.H{
			"token": token,
			"user":  user,
		},
	})
}

// UserLogin - POST /api/v1/auth/login
func UserLogin(c *gin.Context) {
	var req UserLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Email/HP dan password wajib diisi"})
		return
	}

	var user models.User
	// Login bisa pakai Email atau Nomor HP
	result := config.DB.Where("email = ? OR phone = ?", req.Identifier, req.Identifier).First(&user)
	if result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Akun tidak ditemukan atau password salah"})
		return
	}

	// Verifikasi Password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"success": false, "message": "Email/HP atau password salah"})
		return
	}

	token, err := middleware.GenerateToken(user.ID, user.Email, "user")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal generate session"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Login berhasil",
		"data": gin.H{
			"token": token,
			"user":  user,
		},
	})
}

// GetUserProfile - GET /api/v1/user/profile
func GetUserProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	
	var user models.User
	if err := config.DB.Preload("Store").Preload("Driver").First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "User tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    user,
	})
}

// GetFavorites - GET /api/v1/user/favorites
func GetFavorites(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var favorites []models.Favorite
	if err := config.DB.Preload("Product").Preload("Product.Store").Where("user_id = ?", userID).Find(&favorites).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengambil data favorit"})
		return
	}

	// Extract products from favorites
	products := make([]models.Product, 0)
	for _, f := range favorites {
		products = append(products, f.Product)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    products,
	})
}

// ToggleFavorite - POST /api/v1/user/favorites/:id
func ToggleFavorite(c *gin.Context) {
	userID, _ := c.Get("user_id")
	productID := c.Param("id")

	var favorite models.Favorite
	result := config.DB.Where("user_id = ? AND product_id = ?", userID, productID).First(&favorite)

	if result.RowsAffected > 0 {
		// Existing favorite, remove it
		if err := config.DB.Delete(&favorite).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menghapus favorit"})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Dihapus dari favorit",
			"data":    gin.H{"is_favorited": false},
		})
	} else {
		// New favorite, add it
		newFavorite := models.Favorite{
			UserID:    userID.(uint),
			ProductID: 0, // Placeholder, will convert productID string to uint
		}
		
		// Convert productID string to uint safely here or use a helper
		// Simple approach for now
		var pID uint
		config.DB.Raw("SELECT CAST(? AS UNSIGNED)", productID).Scan(&pID)
		newFavorite.ProductID = pID

		if err := config.DB.Create(&newFavorite).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menambah ke favorit"})
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"success": true,
			"message": "Berhasil ditambah ke favorit",
			"data":    gin.H{"is_favorited": true},
		})
	}
}

// ══════════════════════════════════════════════
// CART HANDLERS
// ══════════════════════════════════════════════

// GetCart - GET /api/v1/user/cart
func GetCart(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var cartItems []models.CartItem
	if err := config.DB.Preload("Product").Preload("Variant").Preload("Product.Store").Where("user_id = ?", userID).Find(&cartItems).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengambil data keranjang"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    cartItems,
	})
}

type AddToCartRequest struct {
	ProductID uint  `json:"product_id" binding:"required"`
	VariantID *uint `json:"variant_id"`
	Quantity  int   `json:"quantity" binding:"required,min=1"`
}

// AddToCart - POST /api/v1/user/cart/add
func AddToCart(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req AddToCartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	// 1. Cek stok di database
	var maxStock int
	if req.VariantID != nil {
		var variant models.ProductVariant
		if err := config.DB.First(&variant, req.VariantID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Varian tidak ditemukan"})
			return
		}
		maxStock = variant.Stock
	} else {
		var product models.Product
		if err := config.DB.First(&product, req.ProductID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
			return
		}
		maxStock = product.Stock
	}

	// 2. Cek apakah item sudah ada di keranjang
	var existingItem models.CartItem
	query := config.DB.Where("user_id = ? AND product_id = ?", userID, req.ProductID)
	if req.VariantID != nil {
		query = query.Where("variant_id = ?", req.VariantID)
	} else {
		query = query.Where("variant_id IS NULL")
	}

	result := query.First(&existingItem)

	// 3. Validasi Akumulasi Stok
	totalRequested := req.Quantity
	if result.RowsAffected > 0 {
		totalRequested += existingItem.Quantity
	}

	if totalRequested > maxStock {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Gagal menambah ke keranjang: Stok tidak mencukupi",
			"stock":   maxStock,
		})
		return
	}

	// 4. Update atau Create
	if result.RowsAffected > 0 {
		existingItem.Quantity = totalRequested
		config.DB.Save(&existingItem)
	} else {
		newItem := models.CartItem{
			UserID:    userID.(uint),
			ProductID: req.ProductID,
			VariantID: req.VariantID,
			Quantity:  req.Quantity,
		}
		if err := config.DB.Create(&newItem).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menambah ke keranjang"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Berhasil ditambahkan ke keranjang",
	})
}

// UpdateCart - PUT /api/v1/user/cart/:id
func UpdateCart(c *gin.Context) {
	userID, _ := c.Get("user_id")
	cartID := c.Param("id")

	var req struct {
		Quantity int `json:"quantity" binding:"required,min=1"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	var cartItem models.CartItem
	if err := config.DB.Preload("Product").Preload("Variant").Where("id = ? AND user_id = ?", cartID, userID).First(&cartItem).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Item keranjang tidak ditemukan"})
		return
	}

	// Cek stok terbaru
	var maxStock int
	if cartItem.VariantID != nil {
		maxStock = cartItem.Variant.Stock
	} else {
		maxStock = cartItem.Product.Stock
	}

	if req.Quantity > maxStock {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Stok tidak mencukupi", "stock": maxStock})
		return
	}

	cartItem.Quantity = req.Quantity
	config.DB.Save(&cartItem)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Jumlah berhasil diperbarui",
		"data":    cartItem,
	})
}

// RemoveFromCart - DELETE /api/v1/user/cart/:id
func RemoveFromCart(c *gin.Context) {
	userID, _ := c.Get("user_id")
	cartID := c.Param("id")

	if err := config.DB.Where("id = ? AND user_id = ?", cartID, userID).Delete(&models.CartItem{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menghapus item"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Item berhasil dihapus dari keranjang",
	})
}
// ══════════════════════════════════════════════
// CHECKOUT & ORDER HANDLERS
// ══════════════════════════════════════════════

type CheckoutItem struct {
	ProductID uint  `json:"product_id" binding:"required"`
	VariantID *uint `json:"variant_id"`
	Quantity  int   `json:"quantity" binding:"required,min=1"`
}

type CalculateCheckoutRequest struct {
	Items          []CheckoutItem `json:"items" binding:"required"`
	VoucherCode    string         `json:"voucher_code"`
	ShippingMethod string         `json:"shipping_method"`
	UsePoints      bool           `json:"use_points"`
}

// CalculateCheckout - POST /api/v1/user/checkout/calculate
func CalculateCheckout(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req CalculateCheckoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	var subtotal float64
	var totalWeight float64
	isPhysical := false

	for _, item := range req.Items {
		var product models.Product
		if err := config.DB.Preload("Variants").First(&product, item.ProductID).Error; err != nil {
			continue
		}

		price := product.Price
		if item.VariantID != nil {
			for _, v := range product.Variants {
				if v.ID == *item.VariantID {
					price = v.Price
					break
				}
			}
		}

		subtotal += price * float64(item.Quantity)
		totalWeight += product.Weight * float64(item.Quantity)
		if product.ProductType == "BARANG" {
			isPhysical = true
		}
	}

	// 4. Voucher Logic
	var voucherDiscount float64
	if req.VoucherCode != "" {
		var voucher models.Voucher
		if err := config.DB.Where("code = ? AND is_active = ?", req.VoucherCode, true).First(&voucher).Error; err == nil {
			if subtotal >= voucher.MinOrder {
				switch voucher.Type {
				case "FLAT":
					voucherDiscount = voucher.Value
				case "PERCENT":
					voucherDiscount = (subtotal * voucher.Value) / 100
					if voucher.MaxDiscount > 0 && voucherDiscount > voucher.MaxDiscount {
						voucherDiscount = voucher.MaxDiscount
					}
				}
			}
		}
	}

	// 5. Shipping Fee Logic
	shippingFee := 0.0
	if isPhysical {
		if req.ShippingMethod == "SELF_PICKUP" {
			shippingFee = 0.0
		} else {
			// Default or LOCALSEND
			shippingFee = 10000.0
		}
	}

	totalBeforePoints := (subtotal - voucherDiscount) + shippingFee
	if totalBeforePoints < 0 {
		totalBeforePoints = 0
	}

	// 5. LocalPoint Logic
	var pointDiscount float64
	if req.UsePoints {
		var user models.User
		if err := config.DB.First(&user, userID).Error; err == nil {
			pointDiscount = user.Points
			if pointDiscount > totalBeforePoints {
				pointDiscount = totalBeforePoints
			}
		}
	}

	finalTotal := totalBeforePoints - pointDiscount

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"subtotal":         subtotal,
			"shipping_fee":     shippingFee,
			"voucher_discount": voucherDiscount,
			"point_discount":   pointDiscount,
			"total_amount":     finalTotal,
			"weight":           totalWeight,
		},
	})
}

type CreateOrderRequest struct {
	Items           []CheckoutItem `json:"items" binding:"required"`
	ShippingAddress string         `json:"shipping_address" binding:"required"`
	ServiceDate     string         `json:"service_date"`
	VoucherCode     string         `json:"voucher_code"`
	PaymentMethod   string         `json:"payment_method" binding:"required"`  // TRANSFER, etc.
	ShippingMethod  string         `json:"shipping_method" binding:"required"` // LOCALSEND, SELF_PICKUP
	UsePoints       bool           `json:"use_points"`
}

// CreateOrder - POST /api/v1/user/checkout/create
func CreateOrder(c *gin.Context) {
	userID, _ := c.Get("user_id")
	var req CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Data tidak valid"})
		return
	}

	if len(req.Items) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Keranjang kosong"})
		return
	}

	// ══════════════════════════════════════════════
	// START TRANSACTION
	// ══════════════════════════════════════════════
	tx := config.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	// 1. Ambil StoreID dari item pertama
	var firstProduct models.Product
	if err := tx.First(&firstProduct, req.Items[0].ProductID).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
		return
	}

	// 2. Buat Header Order
	orderNumber := generateOrderNumber()
	order := models.Order{
		UserID:         userID.(uint),
		StoreID:        firstProduct.StoreID,
		OrderNumber:    orderNumber,
		Status:         "PENDING",
		Address:        req.ShippingAddress,
		ServiceDate:    req.ServiceDate,
		VoucherCode:    req.VoucherCode,
		PaymentMethod:  req.PaymentMethod,
		ShippingMethod: req.ShippingMethod,
	}

	var subtotal float64
	isPhysical := false

	// 3. Proses Items & Potong Stok
	var orderItems []models.OrderItem
	for _, item := range req.Items {
		var product models.Product
		if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&product, item.ProductID).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Produk tidak ditemukan"})
			return
		}

		price := product.Price
		if item.VariantID != nil {
			var variant models.ProductVariant
			if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&variant, *item.VariantID).Error; err != nil {
				tx.Rollback()
				c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Varian tidak ditemukan"})
				return
			}
			if variant.Stock < item.Quantity {
				tx.Rollback()
				c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Stok tidak mencukupi"})
				return
			}
			variant.Stock -= item.Quantity
			tx.Save(&variant)
			price = variant.Price
		} else {
			if product.Stock < item.Quantity {
				tx.Rollback()
				c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Stok tidak mencukupi"})
				return
			}
			product.Stock -= item.Quantity
			tx.Save(&product)
		}

		if product.ProductType == "BARANG" {
			isPhysical = true
		}

		subtotal += price * float64(item.Quantity)
		orderItems = append(orderItems, models.OrderItem{
			ProductID:       item.ProductID,
			VariantID:       item.VariantID,
			Quantity:        item.Quantity,
			PriceAtPurchase: price,
		})
	}

	// 4. Voucher Logic
	var voucherDiscount float64
	if req.VoucherCode != "" {
		var voucher models.Voucher
		if err := tx.Where("code = ? AND is_active = ?", req.VoucherCode, true).First(&voucher).Error; err == nil {
			if subtotal >= voucher.MinOrder {
				switch voucher.Type {
				case "FLAT":
					voucherDiscount = voucher.Value
				case "PERCENT":
					voucherDiscount = (subtotal * voucher.Value) / 100
					if voucher.MaxDiscount > 0 && voucherDiscount > voucher.MaxDiscount {
						voucherDiscount = voucher.MaxDiscount
					}
				}
			}
		}
	}
	order.VoucherDiscount = voucherDiscount

	// 5. Ongkir
	shippingFee := 0.0
	if isPhysical && req.ShippingMethod == "LOCALSEND" {
		shippingFee = 10000.0
	}
	order.ShippingFee = shippingFee

	totalBeforePoints := (subtotal - voucherDiscount) + shippingFee
	if totalBeforePoints < 0 {
		totalBeforePoints = 0
	}

	// 6. LocalPoint Logic (Stackable Discount)
	var pointDiscount float64
	if req.UsePoints {
		var user models.User
		if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&user, userID).Error; err == nil {
			pointDiscount = user.Points
			if pointDiscount > totalBeforePoints {
				pointDiscount = totalBeforePoints
			}

			if pointDiscount > 0 {
				// Potong Poin
				user.Points -= pointDiscount
				tx.Save(&user)

				// Catat Transaksi Poin
				pointTx := models.PointTransaction{
					UserID:      user.ID,
					Amount:      pointDiscount,
					Type:        "SPEND",
					Description: "Diskon Poin Pesanan " + order.OrderNumber,
				}
				tx.Create(&pointTx)
			}
		}
	}
	order.PointDiscount = pointDiscount
	order.TotalAmount = totalBeforePoints - pointDiscount

	// Jika total 0 (terbayar penuh poin), set PAID
	if order.TotalAmount <= 0 {
		order.Status = "PAID"
	}

	// Simpan Order
	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal membuat pesanan"})
		return
	}

	// Simpan Items (Link to OrderID)
	for i := range orderItems {
		orderItems[i].OrderID = order.ID
		if err := tx.Create(&orderItems[i]).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal menyimpan detail pesanan"})
			return
		}
	}

	// 4. Hapus Keranjang yang Sesuai
	for _, item := range req.Items {
		delQuery := tx.Where("user_id = ? AND product_id = ?", userID, item.ProductID)
		if item.VariantID != nil {
			delQuery = delQuery.Where("variant_id = ?", item.VariantID)
		} else {
			delQuery = delQuery.Where("variant_id IS NULL")
		}
		delQuery.Delete(&models.CartItem{})
	}

	// COMMIT TRANSACTION
	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal finalisasi transaksi"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Pesanan berhasil dibuat!",
		"data": gin.H{
			"order_id": order.ID,
			"order_number": order.OrderNumber,
		},
	})
}

// generateOrderNumber - LM-YYMM-HASH (LM-2604-A1B2C)
func generateOrderNumber() string {
	now := time.Now()
	timestamp := now.Format("0601") // YYMM
	
	b := make([]byte, 3)
	rand.Read(b)
	hash := fmt.Sprintf("%X", b)
	
	return fmt.Sprintf("LM-%s-%s", timestamp, hash)
}
