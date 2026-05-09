package domain

import "time"

// ──────────────────────────────────────────────────────────────────────────────
// WebSocket event types
// ──────────────────────────────────────────────────────────────────────────────

const (
	EventSlotUpdate  = "SLOT_UPDATE"
	EventQueuePop    = "QUEUE_POP"
	EventSystemAlert = "SYSTEM_ALERT"
)

// WSEvent is the canonical JSON envelope sent to every WebSocket client.
//
//	{ "event": "SLOT_UPDATE", "timestamp": "...", "data": { ... } }
type WSEvent struct {
	Event     string      `json:"event"`
	Timestamp time.Time   `json:"timestamp"`
	Data      interface{} `json:"data"`
}

// ──────────────────────────────────────────────────────────────────────────────
// Event payloads
// ──────────────────────────────────────────────────────────────────────────────

// SlotUpdateData is broadcast when zone capacity changes
type SlotUpdateData struct {
	IDZona     uint   `json:"id_zona"`
	NamaZona   string `json:"nama_zona"`
	Tersedia   int    `json:"tersedia"`
	Kapasitas  int    `json:"kapasitas"`
}

// QueuePopData is sent to a specific user when ZPOPMIN allocates a slot
type QueuePopData struct {
	IDUser       uint   `json:"id_user"`
	IDZona       uint   `json:"id_zona"`
	NamaZona     string `json:"nama_zona"`
	AllocatedSlot string `json:"allocated_slot"`
	Message      string `json:"message"`
}

// SystemAlertData is broadcast when the IoT gateway is unreachable
type SystemAlertData struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Gateway string `json:"gateway"`
}

// WSHub defines the contract for WebSocket broadcasts
type WSHub interface {
	NotifySlotUpdate(data SlotUpdateData)
	NotifyQueuePop(userID uint, data QueuePopData)
	NotifySystemAlert(data SystemAlertData)
}

