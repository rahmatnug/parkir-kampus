package usecase

import (
	"testing"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

// mockUserRepo is a simple mock implementing domain.UserRepository
type mockUserRepo struct {
	users map[string]*domain.User
}

func newMockUserRepo() *mockUserRepo {
	return &mockUserRepo{
		users: make(map[string]*domain.User),
	}
}

func (m *mockUserRepo) Create(user *domain.User) error {
	m.users[user.Email] = user
	return nil
}

func (m *mockUserRepo) FindByEmail(email string) (*domain.User, error) {
	u, ok := m.users[email]
	if !ok {
		return nil, nil
	}
	return u, nil
}

func (m *mockUserRepo) FindByNim(nim string) (*domain.User, error) {
	for _, u := range m.users {
		if u.Nim == nim {
			return u, nil
		}
	}
	return nil, nil
}

func (m *mockUserRepo) FindByID(id uint) (*domain.User, error) {
	for _, u := range m.users {
		if u.ID == id {
			return u, nil
		}
	}
	return nil, nil
}

func (m *mockUserRepo) UpdatePassword(userID uint, newPasswordHash string) error {
	return nil
}

func (m *mockUserRepo) UpdateProfileImageURL(userID uint, imageURL string) error {
	return nil
}

func (m *mockUserRepo) UpdateUserStatus(userID uint, status string) error {
	for _, u := range m.users {
		if u.ID == userID {
			u.Status = status
			return nil
		}
	}
	return nil
}

func (m *mockUserRepo) UpdateKendaraan(userID uint, kendaraanID uint, nomorPolisi, jenisKendaraan, warna string) error {
	return nil
}

// Test cases

func TestRegisterMahasiswaValidEmail(t *testing.T) {
	repo := newMockUserRepo()
	uc := NewUserUsecase(repo)

	user, err := uc.Register(
		"Budi Santoso",
		"21051204301",
		"21051204301@mhs.unesa.ac.id",
		"password123",
		"B 1234 ABC",
		"motor",
		"mahasiswa",
	)

	if err != nil {
		t.Fatalf("expected registration to succeed, got error: %v", err)
	}

	if user == nil {
		t.Fatal("expected registered user to be returned, got nil")
	}

	if user.RoleID != 3 {
		t.Errorf("expected RoleID to be 3 (mahasiswa), got %d", user.RoleID)
	}
}

func TestRegisterMahasiswaInvalidEmail(t *testing.T) {
	repo := newMockUserRepo()
	uc := NewUserUsecase(repo)

	_, err := uc.Register(
		"Budi Santoso",
		"21051204301",
		"budi@gmail.com",
		"password123",
		"B 1234 ABC",
		"motor",
		"mahasiswa",
	)

	if err == nil {
		t.Fatal("expected registration to fail for invalid student email, got nil")
	}

	expectedErr := "registrasi mahasiswa wajib menggunakan email kampus @mhs.unesa.ac.id"
	if err.Error() != expectedErr {
		t.Fatalf("expected error message %q, got %q", expectedErr, err.Error())
	}
}

func TestRegisterTamuValidGeneralEmail(t *testing.T) {
	repo := newMockUserRepo()
	uc := NewUserUsecase(repo)

	user, err := uc.Register(
		"Pengunjung Tamu",
		"", // Guest doesn't need NIM
		"tamu@gmail.com",
		"password123",
		"L 9901 AB",
		"mobil",
		"tamu",
	)

	if err != nil {
		t.Fatalf("expected registration to succeed for tamu, got error: %v", err)
	}

	if user == nil {
		t.Fatal("expected registered user to be returned, got nil")
	}

	if user.RoleID != 5 {
		t.Errorf("expected RoleID to be 5 (tamu), got %d", user.RoleID)
	}
}
