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
	
	// Dimensi & Berat
	Weight      float64   `gorm:"default:0" json:"weight"` // dalam gram
	Length      int       `gorm:"default:0" json:"length"` // dalam cm
	Width       int       `gorm:"default:0" json:"width"`  // dalam cm
	Height      int       `gorm:"default:0" json:"height"` // dalam cm
	
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

	// Associations
	Store  *Store         `gorm:"foreignKey:StoreID" json:"store,omitempty"`
	Images []ProductImage `gorm:"foreignKey:ProductID" json:"images,omitempty"`
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
	Level       string    `gorm:"size:20;default:'regular'" json:"level"` // "regular", "star", "mall"
	Latitude    float64   `gorm:"default:0" json:"latitude"`
	Longitude   float64   `gorm:"default:0" json:"longitude"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

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
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"not null;index" json:"user_id"`
	StoreID     uint      `gorm:"not null;index" json:"store_id"`
	OrderNumber string    `gorm:"size:50;uniqueIndex;not null" json:"order_number"`
	TotalAmount float64   `gorm:"not null" json:"total_amount"`
	Status      string    `gorm:"size:20;default:'pending'" json:"status"` // "pending", "processed", "shipping", "completed", "cancelled"
	Address     string    `gorm:"type:text" json:"address"`
	Latitude    float64   `gorm:"default:0" json:"latitude"`
	Longitude   float64   `gorm:"default:0" json:"longitude"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`

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
	ID        uint    `gorm:"primaryKey" json:"id"`
	OrderID   uint    `gorm:"not null;index" json:"order_id"`
	ProductID uint    `gorm:"not null;index" json:"product_id"`
	Quantity  int     `gorm:"not null" json:"quantity"`
	Price     float64 `gorm:"not null" json:"price"` // harga snapshot saat dibeli

	// Associations
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

func (OrderItem) TableName() string {
	return "order_items"
}
