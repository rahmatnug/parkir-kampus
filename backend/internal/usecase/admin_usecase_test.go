package usecase

import (
	"errors"
	"testing"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

// ─── Mock Repository ────────────────────────────────────────────────────────

type mockAdminRepo struct {
	addPenaltyErr       error
	totalPenaltyPoints  int
	totalPenaltyErr     error
	createBlacklistErr  error
	hasActiveTxn        bool
	hasActiveTxnErr     error
	deleteUserErr       error
	createZoneErr       error
	findZoneByNameResult *domain.ZonaParkir
	findZoneByNameErr   error

	// Track calls
	addPenaltyCalled      bool
	createBlacklistCalled bool
	deleteUserCalled      bool
	createZoneCalled      bool
}

func (m *mockAdminRepo) GetDashboardStats() (*domain.DashboardStats, error)        { return nil, nil }
func (m *mockAdminRepo) GetAllUsers() ([]domain.AdminUserItem, error)              { return nil, nil }
func (m *mockAdminRepo) GetAllActivities() ([]domain.AdminActivityItem, error)     { return nil, nil }
func (m *mockAdminRepo) UpdateUserRole(userID uint, newRole string) error           { return nil }
func (m *mockAdminRepo) UpdateUserStatus(userID uint, newStatus string) error       { return nil }
func (m *mockAdminRepo) GetBlacklistedUsers() ([]domain.BlacklistItem, error)      { return nil, nil }
func (m *mockAdminRepo) ForceExitActivity(activityID uint) error                    { return nil }
func (m *mockAdminRepo) RemovePenalty(userID uint) error                            { return nil }
func (m *mockAdminRepo) GetAllZones() ([]domain.ZoneWithSlots, error)              { return nil, nil }
func (m *mockAdminRepo) UpdateZone(zone *domain.ZonaParkir) error                   { return nil }
func (m *mockAdminRepo) DeleteZone(zonaID uint) error                               { return nil }
func (m *mockAdminRepo) CreateSlot(slot *domain.SlotParkir) error                   { return nil }
func (m *mockAdminRepo) GetSlotsByZone(zonaID uint) ([]domain.SlotParkir, error)   { return nil, nil }
func (m *mockAdminRepo) DeleteSlot(slotID uint) error                               { return nil }

func (m *mockAdminRepo) DeleteUser(userID uint) error {
	m.deleteUserCalled = true
	return m.deleteUserErr
}

func (m *mockAdminRepo) HasActiveTransaction(userID uint) (bool, error) {
	return m.hasActiveTxn, m.hasActiveTxnErr
}

func (m *mockAdminRepo) AddPenalty(userID uint, poin int, keterangan string) error {
	m.addPenaltyCalled = true
	return m.addPenaltyErr
}

func (m *mockAdminRepo) GetTotalPenaltyPoints(userID uint) (int, error) {
	return m.totalPenaltyPoints, m.totalPenaltyErr
}

func (m *mockAdminRepo) CreateBlacklist(userID uint, alasan string) error {
	m.createBlacklistCalled = true
	return m.createBlacklistErr
}

func (m *mockAdminRepo) CreateZone(zone *domain.ZonaParkir) error {
	m.createZoneCalled = true
	return m.createZoneErr
}

func (m *mockAdminRepo) FindZoneByName(name string) (*domain.ZonaParkir, error) {
	return m.findZoneByNameResult, m.findZoneByNameErr
}

// ─── Mock WebSocket Hub ─────────────────────────────────────────────────────

type mockWSHub struct{}

func (m *mockWSHub) NotifySlotUpdate(data domain.SlotUpdateData)        {}
func (m *mockWSHub) NotifyQueuePop(userID uint, data domain.QueuePopData) {}
func (m *mockWSHub) NotifySystemAlert(data domain.SystemAlertData)       {}
func (m *mockWSHub) NotifyLayoutUpdate()                                 {}

// ─── Tests ──────────────────────────────────────────────────────────────────

func TestAddPenalty_NegativePoints_Rejected(t *testing.T) {
	repo := &mockAdminRepo{}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.AddPenalty(1, -10, "Parking violation")
	if err == nil {
		t.Fatal("expected error for negative penalty points, got nil")
	}
	expected := "poin penalti harus lebih besar dari 0"
	if err.Error() != expected {
		t.Fatalf("expected error message %q, got %q", expected, err.Error())
	}
	if repo.addPenaltyCalled {
		t.Fatal("repository.AddPenalty should NOT have been called for negative points")
	}
}

func TestAddPenalty_ZeroPoints_Rejected(t *testing.T) {
	repo := &mockAdminRepo{}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.AddPenalty(1, 0, "Some violation")
	if err == nil {
		t.Fatal("expected error for zero penalty points, got nil")
	}
}

func TestAddPenalty_EmptyKeterangan_Rejected(t *testing.T) {
	repo := &mockAdminRepo{}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.AddPenalty(1, 10, "   ")
	if err == nil {
		t.Fatal("expected error for empty keterangan, got nil")
	}
}

func TestAddPenalty_Success_NoBlacklist(t *testing.T) {
	repo := &mockAdminRepo{
		totalPenaltyPoints: 50, // Below threshold (100)
	}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.AddPenalty(1, 10, "Parking violation")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.addPenaltyCalled {
		t.Fatal("expected AddPenalty to be called")
	}
	if repo.createBlacklistCalled {
		t.Fatal("CreateBlacklist should NOT be called when below threshold")
	}
}

func TestAddPenalty_Success_AutoBlacklist(t *testing.T) {
	repo := &mockAdminRepo{
		totalPenaltyPoints: 100, // Meets threshold
	}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.AddPenalty(1, 20, "Repeated violation")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.addPenaltyCalled {
		t.Fatal("expected AddPenalty to be called")
	}
	if !repo.createBlacklistCalled {
		t.Fatal("expected CreateBlacklist to be called when threshold is reached")
	}
}

func TestDeleteUser_WithActiveTransaction_Rejected(t *testing.T) {
	repo := &mockAdminRepo{
		hasActiveTxn: true,
	}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.DeleteUser(1)
	if err == nil {
		t.Fatal("expected error when user has active transaction, got nil")
	}
	if repo.deleteUserCalled {
		t.Fatal("repository.DeleteUser should NOT have been called")
	}
}

func TestDeleteUser_NoActiveTransaction_Success(t *testing.T) {
	repo := &mockAdminRepo{
		hasActiveTxn: false,
	}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.DeleteUser(1)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.deleteUserCalled {
		t.Fatal("expected repository.DeleteUser to be called")
	}
}

func TestDeleteUser_ZeroID_Rejected(t *testing.T) {
	repo := &mockAdminRepo{}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.DeleteUser(0)
	if err == nil {
		t.Fatal("expected error for zero user ID, got nil")
	}
}

func TestCreateZone_DuplicateName_Rejected(t *testing.T) {
	repo := &mockAdminRepo{
		findZoneByNameResult: &domain.ZonaParkir{IDZona: 1, NamaZona: "Zone A"},
	}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.CreateZone("Zone A", "desc", 50, "motor")
	if err == nil {
		t.Fatal("expected error for duplicate zone name, got nil")
	}
	if repo.createZoneCalled {
		t.Fatal("repository.CreateZone should NOT have been called for duplicate name")
	}
}

func TestCreateZone_ZeroCapacity_Rejected(t *testing.T) {
	repo := &mockAdminRepo{}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.CreateZone("Zone X", "desc", 0, "motor")
	if err == nil {
		t.Fatal("expected error for zero capacity, got nil")
	}
}

func TestCreateZone_EmptyName_Rejected(t *testing.T) {
	repo := &mockAdminRepo{}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.CreateZone("  ", "desc", 50, "motor")
	if err == nil {
		t.Fatal("expected error for empty zone name, got nil")
	}
}

func TestCreateZone_Success(t *testing.T) {
	repo := &mockAdminRepo{
		findZoneByNameResult: nil, // No duplicate
	}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.CreateZone("Zone D", "new zone", 30, "mobil")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.createZoneCalled {
		t.Fatal("expected repository.CreateZone to be called")
	}
}

func TestAddPenalty_RepoFailure_PropagatesError(t *testing.T) {
	repo := &mockAdminRepo{
		addPenaltyErr: errors.New("db connection lost"),
	}
	uc := NewAdminUsecase(repo, &mockWSHub{})

	err := uc.AddPenalty(1, 10, "Violation")
	if err == nil {
		t.Fatal("expected error to be propagated from repository")
	}
	if err.Error() != "db connection lost" {
		t.Fatalf("expected 'db connection lost', got %q", err.Error())
	}
}
