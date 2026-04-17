package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/ksb/localmart/backend/internal/config"
	"github.com/ksb/localmart/backend/internal/models"
)

// WebSocket Upgrader
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Di produksi, ganti dengan domain spesifik
	},
}

// ChatHub menyimpan koneksi aktif berdasarkan UserID
type ChatHub struct {
	clients map[uint]*websocket.Conn
	mu      sync.Mutex
}

var hub = ChatHub{
	clients: make(map[uint]*websocket.Conn),
}

// MessagePayload adalah struktur pesan yang dikirim/diterima via WS
type MessagePayload struct {
	Type           string    `json:"type"` // "chat", "ping", "read_event"
	ConversationID uint      `json:"conversation_id"`
	SenderID       uint      `json:"sender_id"`
	ReceiverID     uint      `json:"receiver_id"`
	Content        string    `json:"content"`
	SenderType     string    `json:"sender_type"` // "user", "merchant"
	CreatedAt      time.Time `json:"created_at"`
}

// HandleWebSocket mengelola koneksi WebSocket
func HandleWebSocket(c *gin.Context) {
	log.Printf("New WS Connection attempt from: %s", c.Request.RemoteAddr)
	
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDRaw.(uint)

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WS Upgrade Error: %v", err)
		return
	}

	// Registrasi client
	hub.mu.Lock()
	hub.clients[userID] = conn
	hub.mu.Unlock()

	log.Printf("User %d connected via WebSocket", userID)

	// Clean up saat disconnect
	defer func() {
		hub.mu.Lock()
		delete(hub.clients, userID)
		hub.mu.Unlock()
		conn.Close()
		log.Printf("User %d disconnected", userID)
	}()

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			break
		}

		var payload MessagePayload
		if err := json.Unmarshal(message, &payload); err != nil {
			log.Printf("JSON Unmarshal Error: %v", err)
			continue
		}

		// Set SenderID dari context auth
		payload.SenderID = userID
		payload.CreatedAt = time.Now()

		if payload.Type == "chat" {
			// 1. Simpan ke database
			dbMessage := models.Message{
				ConversationID: payload.ConversationID,
				SenderID:       payload.SenderID,
				ReceiverID:     payload.ReceiverID,
				SenderType:     payload.SenderType,
				Content:        payload.Content,
				CreatedAt:      payload.CreatedAt,
			}

			if err := config.DB.Create(&dbMessage).Error; err != nil {
				log.Printf("DB Save Error: %v", err)
				continue
			}

			// Update conversation last message & time
			config.DB.Model(&models.Conversation{}).Where("id = ?", payload.ConversationID).Updates(map[string]interface{}{
				"last_message": payload.Content,
				"updated_at":   payload.CreatedAt,
			})

			// 2. Kirim ke penerima jika online
			hub.mu.Lock()
			recipientConn, online := hub.clients[payload.ReceiverID]
			hub.mu.Unlock()

			if online {
				recipientConn.WriteJSON(payload)
			}
			
			// Kirim balik ke pengirim sebagai ACK (opsional tapi bagus untuk konfirmasi)
			conn.WriteJSON(payload)
		}
	}
}

// GetConversations mengambil daftar percakapan user
func GetConversations(c *gin.Context) {
	userID := c.MustGet("user_id").(uint)

	var conversations []models.Conversation
	err := config.DB.Preload("Participant1").Preload("Participant2").
		Where("participant1_id = ? OR participant2_id = ?", userID, userID).
		Order("updated_at desc").
		Find(&conversations).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil percakapan"})
		return
	}

	// Tambahkan status online untuk setiap percakapan
	type ConvWithStatus struct {
		models.Conversation
		IsOnline bool `json:"is_online"`
	}
	
	result := make([]ConvWithStatus, 0)
	hub.mu.Lock()
	for _, conv := range conversations {
		otherUserID := conv.Participant1ID
		if otherUserID == userID {
			otherUserID = conv.Participant2ID
		}
		
		_, online := hub.clients[otherUserID]
		result = append(result, ConvWithStatus{
			Conversation: conv,
			IsOnline:     online,
		})
	}
	hub.mu.Unlock()

	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
}

// GetMessages mengambil riwayat pesan dalam satu percakapan
func GetMessages(c *gin.Context) {
	conversationID := c.Param("id")

	var messages []models.Message
	err := config.DB.Where("conversation_id = ?", conversationID).
		Order("created_at desc").
		Find(&messages).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil pesan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": messages})
}

// StartConversation atau ambil yang sudah ada
func StartConversation(c *gin.Context) {
	userID := c.MustGet("user_id").(uint)
	var body struct {
		TargetUserID uint `json:"target_user_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if userID == body.TargetUserID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tidak bisa chat dengan diri sendiri"})
		return
	}

	// Cari ID yang lebih kecil untuk Participant1ID demi konsistensi
	p1, p2 := userID, body.TargetUserID
	if p1 > p2 {
		p1, p2 = p2, p1
	}

	var conv models.Conversation
	err := config.DB.Where("participant1_id = ? AND participant2_id = ?", p1, p2).First(&conv).Error

	if err != nil {
		// Buat baru jika belum ada
		conv = models.Conversation{
			Participant1ID: p1,
			Participant2ID: p2,
			LastMessage:   "Memulai percakapan...",
			UpdatedAt:     time.Now(),
		}
		if err := config.DB.Create(&conv).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat percakapan"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": conv})
}
