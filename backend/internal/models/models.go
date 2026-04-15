package models

import (
	"time"
)

// Banner - banner highlight & slider di homepage
type Banner struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Title     string    `gorm:"size:255;not null" json:"title"`
	ImageURL  string    `gorm:"size:500" json:"image_url"`
	LinkURL   string    `gorm:"size:500" json:"link_url"`
	Position  string    `gorm:"size:20;not null;default:'top'" json:"position"` // "top" atau "slider"
	SortOrder int       `gorm:"default:0" json:"sort_order"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Category - tab kategori di homepage (Food & Drink, Fashion, dll.)
type Category struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `gorm:"size:100;not null" json:"name"`
	Slug      string    `gorm:"size:100;uniqueIndex;not null" json:"slug"`
	IconName  string    `gorm:"size:100" json:"icon_name"` // nama icon Material Design
	SortOrder int       `gorm:"default:0" json:"sort_order"`
	Type      string    `gorm:"size:20;not null;default:'BARANG'" json:"type"` // BARANG, JASA, RENTAL, WISATA
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	Products  []Product `gorm:"foreignKey:CategoryID" json:"products,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// ProductImage - banyak foto untuk satu produk
type ProductImage struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	ProductID uint      `gorm:"not null;index" json:"product_id"`
	ImageURL  string    `gorm:"size:500;not null" json:"image_url"`
	CreatedAt time.Time `json:"created_at"`
}

// Product - produk dalam kategori
type Product struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	CategoryID  uint      `gorm:"not null;index" json:"category_id"`
	Name        string    `gorm:"size:255;not null" json:"name"`
	Description string    `gorm:"type:text" json:"description"`
	Price       float64   `gorm:"not null;default:0" json:"price"`
	ImageURL    string    `gorm:"size:500" json:"image_url"` // Thumbnail/Main image
	StoreID     uint      `gorm:"index" json:"store_id"`     // 0 jika produk global/admin
	Stock       int       `gorm:"default:0" json:"stock"`
	Sold        int       `gorm:"default:0" json:"sold"`
	Rating      float64   `gorm:"default:0" json:"rating"`
	ReviewCount int       `gorm:"default:0" json:"review_count"`
	
	// Dimensi & Berat & Logistics
	Weight      float64   `gorm:"default:0" json:"weight"` // dalam gram
	Length      int       `gorm:"default:0" json:"length"` // dalam cm
	Width       int       `gorm:"default:0" json:"width"`  // dalam cm
	Height      int       `gorm:"default:0" json:"height"` // dalam cm
	
	// Professional Metadata
	Condition   string    `gorm:"size:20;default:'Baru'" json:"condition"` // "Baru" atau "Bekas"
	Brand       string    `gorm:"size:100" json:"brand"`
	SKU         string    `gorm:"size:100" json:"sku"`
	MinOrder    int       `gorm:"default:1" json:"min_order"`
	
	// Modular Features (V2)
	ProductType string    `gorm:"size:20;not null;default:'BARANG'" json:"product_type"` // BARANG, JASA, RENTAL, WISATA
	Metadata    string    `gorm:"type:text" json:"metadata"`                           // JSON Stringified data
	
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Associations
	Store    *Store           `gorm:"foreignKey:StoreID" json:"store,omitempty"`
	Images   []ProductImage   `gorm:"foreignKey:ProductID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"images,omitempty"`
	Variants []ProductVariant `gorm:"foreignKey:ProductID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE;" json:"variants,omitempty"`
}

// ProductVariant - varian untuk produk (ukuran, kemasan, dll)
type ProductVariant struct {
	ID        uint    `gorm:"primaryKey" json:"id"`
	ProductID uint    `gorm:"not null;index" json:"product_id"`
	Name      string  `gorm:"size:100;not null" json:"name"`
	Price     float64 `gorm:"not null" json:"price"`
	Stock     int     `gorm:"default:0" json:"stock"`
}

// Section - kontrol tampilan section di homepage
type Section struct {
	ID        uint   `gorm:"primaryKey" json:"id"`
	Key       string `gorm:"size:50;uniqueIndex;not null" json:"key"` // "banner_top", "categories", "products", "banner_slider", "discovery"
	Title     string `gorm:"size:255" json:"title"`
	SortOrder int    `gorm:"default:0" json:"sort_order"`
	IsActive  bool   `gorm:"default:true" json:"is_active"`
}

// DiscoveryTab - tab discovery di bagian bawah homepage
type DiscoveryTab struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `gorm:"size:100;not null" json:"name"`
	SortOrder int       `gorm:"default:0" json:"sort_order"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	Products  []Product `gorm:"-" json:"products,omitempty"` // loaded manually
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Admin - user admin untuk CMS
type Admin struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Username  string    `gorm:"size:100;uniqueIndex;not null" json:"username"`
	Password  string    `gorm:"size:255;not null" json:"-"` // bcrypt hash, never exposed in JSON
	CreatedAt time.Time `json:"created_at"`
}

// User - pembeli/customer aplikasi LocalMart
type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	FirstName string    `gorm:"size:100;not null" json:"first_name"`
	LastName  string    `gorm:"size:100" json:"last_name"`
	Email     string    `gorm:"size:150;uniqueIndex;not null" json:"email"`
	Phone     string    `gorm:"size:20;uniqueIndex;not null" json:"phone"`
	Password  string    `gorm:"size:255;not null" json:"-"`
	AvatarURL string    `gorm:"size:500" json:"avatar_url"`
	Gender    string    `gorm:"size:10" json:"gender"`     // "Laki-laki" atau "Perempuan"
	BirthDate string    `gorm:"size:20" json:"birth_date"` // YYYY-MM-DD
	Latitude  float64   `gorm:"default:0" json:"latitude"`
	Longitude float64   `gorm:"default:0" json:"longitude"`
	Points    float64   `gorm:"default:0" json:"points"` // LocalPoints (1:1 with IDR)
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// Associations
	Store  *Store  `gorm:"foreignKey:UserID" json:"store,omitempty"`
	Driver *Driver `gorm:"foreignKey:UserID" json:"driver,omitempty"`
}

// Store - profil toko UMKM milik user
type Store struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"uniqueIndex;not null" json:"user_id"`
	Name        string    `gorm:"size:255;not null" json:"name"`
	Category    string    `gorm:"size:100;not null" json:"category"`
	Description string    `gorm:"type:text" json:"description"`
	Address     string    `gorm:"type:text" json:"address"`
	ImageURL    string    `gorm:"size:500" json:"image_url"`
	Balance     float64   `gorm:"default:0" json:"balance"`
	Status      string    `gorm:"size:20;default:'pending'" json:"status"` // "pending", "approved", "rejected"
	Level        string    `gorm:"size:20;default:'regular'" json:"level"` // "regular", "star", "mall"
	Latitude     float64   `gorm:"default:0" json:"latitude"`
	Longitude    float64   `gorm:"default:0" json:"longitude"`
	Village      string    `gorm:"size:100" json:"village"`
	District     string    `gorm:"size:100" json:"district"`
	IsVerified   bool      `gorm:"default:false" json:"is_verified"`
	Rating       float64   `gorm:"default:0" json:"rating"`
	ReviewCount  int       `gorm:"default:0" json:"review_count"`
	ProductCount int       `gorm:"default:0" json:"product_count"`
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`

	// Associations
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// Driver - profil mitra driver (kurir/ojek) milik user
type Driver struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	UserID       uint      `gorm:"uniqueIndex;not null" json:"user_id"`
	VehicleType  string    `gorm:"size:100;not null" json:"vehicle_type"`
	PlateNumber  string    `gorm:"size:20;uniqueIndex;not null" json:"plate_number"`
	PhoneNumber  string    `gorm:"size:20" json:"phone_number"` // Biasanya WhatsApp aktif
	IsOnline     bool      `gorm:"default:false" json:"is_online"`
	Balance      float64   `gorm:"default:0" json:"balance"`
	Status       string    `gorm:"size:20;default:'pending'" json:"status"` // "pending", "approved", "rejected"
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`

	// Associations
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// Order - pesanan dari pembeli ke toko
type Order struct {
	ID           uint        `gorm:"primaryKey" json:"id"`
	UserID       uint        `gorm:"not null;index" json:"user_id"`
	StoreID      uint        `gorm:"not null;index" json:"store_id"`
	OrderNumber     string      `gorm:"size:50;uniqueIndex;not null" json:"order_number"`
	TotalAmount     float64     `gorm:"not null" json:"total_amount"`
	ShippingFee     float64     `gorm:"not null;default:0" json:"shipping_fee"`
	VoucherCode     string      `gorm:"size:50" json:"voucher_code"`
	VoucherDiscount float64     `gorm:"default:0" json:"voucher_discount"`
	PointDiscount   float64     `gorm:"default:0" json:"point_discount"`
	PaymentMethod   string      `gorm:"size:50" json:"payment_method"`   // LOCALPAY, TRANSFER
	ShippingMethod  string      `gorm:"size:50" json:"shipping_method"`  // LOCALSEND, SELF_PICKUP
	Status          string      `gorm:"size:20;default:'PENDING'" json:"status"` // PENDING, PAID, PROCESSED, SHIPPED, COMPLETED, CANCELLED
	Address         string      `gorm:"type:text" json:"address"`
	Latitude     float64     `gorm:"default:0" json:"latitude"`
	Longitude    float64     `gorm:"default:0" json:"longitude"`
	ServiceDate  string      `gorm:"size:100" json:"service_date"` // Untuk Jasa/Rental/Wisata
	CreatedAt    time.Time   `json:"created_at"`
	UpdatedAt    time.Time   `json:"updated_at"`

	// Associations
	User  User        `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Store Store       `gorm:"foreignKey:StoreID" json:"store,omitempty"`
	Items []OrderItem `gorm:"foreignKey:OrderID" json:"items,omitempty"`
}

// TableName forces GORM to use "orders" and avoiding reserved keyword conflicts
func (Order) TableName() string {
	return "orders"
}

// OrderItem - item produk dalam satu pesanan
type OrderItem struct {
	ID              uint            `gorm:"primaryKey" json:"id"`
	OrderID         uint            `gorm:"not null;index" json:"order_id"`
	ProductID       uint            `gorm:"not null;index" json:"product_id"`
	VariantID       *uint           `gorm:"index" json:"variant_id"`
	Quantity        int             `gorm:"not null" json:"quantity"`
	PriceAtPurchase float64         `gorm:"not null" json:"price_at_purchase"` // Snapshot harga saat checkout
	
	// Associations
	Product Product        `gorm:"foreignKey:ProductID" json:"product,omitempty"`
	Variant *ProductVariant `gorm:"foreignKey:VariantID" json:"variant,omitempty"`
}

func (OrderItem) TableName() string {
	return "order_items"
}

// Voucher - kupon potongan harga
type Voucher struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	Code        string    `gorm:"size:50;uniqueIndex;not null" json:"code"`
	Type        string    `gorm:"size:20;not null" json:"type"` // "PERCENT", "FLAT"
	Value       float64   `gorm:"not null" json:"value"`
	MinOrder    float64   `gorm:"default:0" json:"min_order"`
	MaxDiscount float64   `gorm:"default:0" json:"max_discount"` // Hanya untuk PERCENT
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// PointTransaction - riwayat penambahan/pengurangan poin user
type PointTransaction struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"not null;index" json:"user_id"`
	Amount      float64   `gorm:"not null" json:"amount"`
	Type        string    `gorm:"size:10;not null" json:"type"` // "EARN", "SPEND"
	Description string    `gorm:"size:255" json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

// Review - ulasan produk dari pembeli
type Review struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	ProductID uint      `gorm:"not null;index" json:"product_id"`
	UserID    uint      `gorm:"not null;index" json:"user_id"`
	OrderID   uint      `gorm:"index" json:"order_id"` // Opsional, bisa review tanpa order jika diizinkan
	Rating    int       `gorm:"not null" json:"rating"`
	Comment   string    `gorm:"type:text" json:"comment"`
	CreatedAt time.Time `json:"created_at"`
	
	// Associations
	User    User    `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// Favorite - produk yang disukai user
type Favorite struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"not null;index" json:"user_id"`
	ProductID uint      `gorm:"not null;index" json:"product_id"`
	CreatedAt time.Time `json:"created_at"`

	// Associations
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// StoreFollower - pengikut toko
type StoreFollower struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"not null;index" json:"user_id"`
	StoreID   uint      `gorm:"not null;index" json:"store_id"`
	CreatedAt time.Time `json:"created_at"`
}

// CartItem - item dalam keranjang belanja
type CartItem struct {
	ID        uint            `gorm:"primaryKey" json:"id"`
	UserID    uint            `gorm:"not null;index" json:"user_id"`
	ProductID uint            `gorm:"not null;index" json:"product_id"`
	VariantID *uint           `gorm:"index" json:"variant_id"` // Nullable for products without variants
	Quantity  int             `gorm:"not null;default:1" json:"quantity"`
	CreatedAt time.Time       `json:"created_at"`

	// Associations
	Product *Product        `gorm:"foreignKey:ProductID" json:"product,omitempty"`
	Variant *ProductVariant `gorm:"foreignKey:VariantID" json:"variant,omitempty"`
}
