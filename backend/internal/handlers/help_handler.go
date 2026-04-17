package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

// GetHelpCenters returns all help center/FAQ items
func GetHelpCenters(c *gin.Context) {
	var helpItems []models.HelpCenter
	
	if err := config.DB.Order("sort_order asc").Find(&helpItems).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil data bantuan"})
		return
	}
	
	// Group by category
	grouped := make(map[string][]models.HelpCenter)
	for _, item := range helpItems {
		grouped[item.Category] = append(grouped[item.Category], item)
	}
	
	c.JSON(http.StatusOK, gin.H{
		"data": grouped,
	})
}
