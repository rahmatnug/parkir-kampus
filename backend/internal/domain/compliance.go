package domain

import "time"

// Operational Compliance Constants
const (
	// MaxPenaltyPoints is the threshold of penalty points before a user is automatically blacklisted.
	MaxPenaltyPoints = 100

	// OverstayDurationLimit is the maximum allowed duration a vehicle can park before it is considered an overstay violation.
	OverstayDurationLimit = 24 * time.Hour
)
