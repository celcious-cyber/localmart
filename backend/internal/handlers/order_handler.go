package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

// GetStoreOrders - GET /api/v1/user/store/orders
func GetStoreOrders(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)

	// Cari toko milik user
	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Anda belum terdaftar sebagai Toko"})
		return
	}

	status := c.Query("status") // "Baru", "Diproses", "Dikirim", "Selesai"
	
	// Map frontend status to backend status
	backendStatus := ""
	switch status {
	case "Baru":
		backendStatus = "pending"
	case "Diproses":
		backendStatus = "processed"
	case "Dikirim":
		backendStatus = "shipping"
	case "Selesai":
		backendStatus = "completed"
	}

	var orders []models.Order
	query := config.DB.Preload("Items.Product").Preload("User").Where("store_id = ?", store.ID)
	
	if backendStatus != "" {
		query = query.Where("status = ?", backendStatus)
	}

	if err := query.Order("created_at DESC").Find(&orders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal mengambil data pesanan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    orders,
	})
}

// UpdateOrderStatus - PATCH /api/v1/user/store/orders/:id/status
func UpdateOrderStatus(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid := userID.(uint)
	orderID := c.Param("id")

	var req struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Status wajib diisi"})
		return
	}

	// Cari toko milik user
	var store models.Store
	if err := config.DB.Where("user_id = ?", uid).First(&store).Error; err != nil {
		c.JSON(http.StatusForbidden, gin.H{"success": false, "message": "Akses ditolak"})
		return
	}

	// Cari pesanan dan pastikan milik toko ini
	var order models.Order
	if err := config.DB.Where("id = ? AND store_id = ?", orderID, store.ID).First(&order).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "message": "Pesanan tidak ditemukan"})
		return
	}

	// Update status
	oldStatus := order.Status
	order.Status = req.Status
	
	if err := config.DB.Save(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal update status"})
		return
	}

	// Logika Saldo: Jika status berubah jadi 'completed', tambahkan ke saldo toko
	if req.Status == "completed" && oldStatus != "completed" {
		config.DB.Model(&store).Update("balance", store.Balance + order.TotalAmount)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Status pesanan berhasil diperbarui",
		"data":    order,
	})
}
