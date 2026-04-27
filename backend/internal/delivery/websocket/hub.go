package websocket

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

// ──────────────────────────────────────────────────────────────────────────────
// Client represents a single WebSocket connection bound to a user
// ──────────────────────────────────────────────────────────────────────────────

type Client struct {
	Hub    *Hub
	Conn   *websocket.Conn
	Send   chan []byte
	UserID uint
}

// writePump drains the Send channel and pushes messages to the socket.
func (c *Client) writePump() {
	defer func() {
		c.Conn.Close()
	}()
	for msg := range c.Send {
		if err := c.Conn.WriteMessage(websocket.TextMessage, msg); err != nil {
			log.Printf("[ws] write error user=%d: %v", c.UserID, err)
			return
		}
	}
}

// readPump keeps the connection alive, detects close frames.
func (c *Client) readPump() {
	defer func() {
		c.Hub.Unregister <- c
		c.Conn.Close()
	}()
	c.Conn.SetReadLimit(512)
	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})
	for {
		_, _, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				log.Printf("[ws] unexpected close user=%d: %v", c.UserID, err)
			}
			break
		}
	}
}

// ──────────────────────────────────────────────────────────────────────────────
// Hub is the central WebSocket manager — handles register/unregister/broadcast
// ──────────────────────────────────────────────────────────────────────────────

type Hub struct {
	// All connected clients keyed by pointer
	Clients map[*Client]bool

	// Mutex-protected map for targeted sends (UserID → []*Client)
	userClients map[uint][]*Client
	mu          sync.RWMutex

	// Channels
	Register   chan *Client
	Unregister chan *Client
	Broadcast  chan []byte
}

// NewHub creates and returns a new Hub instance.
func NewHub() *Hub {
	return &Hub{
		Clients:     make(map[*Client]bool),
		userClients: make(map[uint][]*Client),
		Register:    make(chan *Client),
		Unregister:  make(chan *Client),
		Broadcast:   make(chan []byte, 256),
	}
}

// Run starts the hub event loop. Call this in a goroutine: go hub.Run()
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.Clients[client] = true
			h.mu.Lock()
			h.userClients[client.UserID] = append(h.userClients[client.UserID], client)
			h.mu.Unlock()
			log.Printf("[ws] client registered user=%d (total=%d)", client.UserID, len(h.Clients))

		case client := <-h.Unregister:
			if _, ok := h.Clients[client]; ok {
				delete(h.Clients, client)
				close(client.Send)

				h.mu.Lock()
				clients := h.userClients[client.UserID]
				for i, c := range clients {
					if c == client {
						h.userClients[client.UserID] = append(clients[:i], clients[i+1:]...)
						break
					}
				}
				if len(h.userClients[client.UserID]) == 0 {
					delete(h.userClients, client.UserID)
				}
				h.mu.Unlock()
				log.Printf("[ws] client unregistered user=%d (total=%d)", client.UserID, len(h.Clients))
			}

		case message := <-h.Broadcast:
			for client := range h.Clients {
				select {
				case client.Send <- message:
				default:
					// Slow client — drop
					close(client.Send)
					delete(h.Clients, client)
				}
			}
		}
	}
}

// ──────────────────────────────────────────────────────────────────────────────
// Public API — used by other packages to push events
// ──────────────────────────────────────────────────────────────────────────────

// BroadcastEvent sends a WSEvent to ALL connected clients.
func (h *Hub) BroadcastEvent(eventType string, data interface{}) {
	evt := domain.WSEvent{
		Event:     eventType,
		Timestamp: time.Now(),
		Data:      data,
	}
	payload, err := json.Marshal(evt)
	if err != nil {
		log.Printf("[ws] marshal error: %v", err)
		return
	}
	h.Broadcast <- payload
}

// SendToUser sends a WSEvent to a specific user only (e.g. QUEUE_POP).
func (h *Hub) SendToUser(userID uint, eventType string, data interface{}) {
	evt := domain.WSEvent{
		Event:     eventType,
		Timestamp: time.Now(),
		Data:      data,
	}
	payload, err := json.Marshal(evt)
	if err != nil {
		log.Printf("[ws] marshal error: %v", err)
		return
	}

	h.mu.RLock()
	clients := h.userClients[userID]
	h.mu.RUnlock()

	for _, c := range clients {
		select {
		case c.Send <- payload:
		default:
			log.Printf("[ws] send buffer full user=%d, dropping", userID)
		}
	}
}

// ──────────────────────────────────────────────────────────────────────────────
// Convenience helpers for the 3 event types
// ──────────────────────────────────────────────────────────────────────────────

// NotifySlotUpdate broadcasts a SLOT_UPDATE event to all clients.
func (h *Hub) NotifySlotUpdate(data domain.SlotUpdateData) {
	h.BroadcastEvent(domain.EventSlotUpdate, data)
}

// NotifyQueuePop sends a QUEUE_POP event to a specific user.
func (h *Hub) NotifyQueuePop(userID uint, data domain.QueuePopData) {
	h.SendToUser(userID, domain.EventQueuePop, data)
}

// NotifySystemAlert broadcasts a SYSTEM_ALERT to all clients
// (e.g., IoT gateway unreachable — HTTP 504 / ERR_IOT_TIMEOUT).
func (h *Hub) NotifySystemAlert(data domain.SystemAlertData) {
	h.BroadcastEvent(domain.EventSystemAlert, data)
}
