package usecase

import (
	"errors"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"github.com/rahmatnug/parkir-kampus-backend/pkg/jwt"
	"golang.org/x/crypto/bcrypt"
)

type userUsecase struct {
	userRepo domain.UserRepository
}

// NewUserUsecase creates a new user usecase
func NewUserUsecase(repo domain.UserRepository) domain.UserUsecase {
	return &userUsecase{
		userRepo: repo,
	}
}

func (u *userUsecase) Register(email, password string) (*domain.User, error) {
	existingUser, err := u.userRepo.FindByEmail(email)
	if err != nil {
		return nil, err
	}
	if existingUser != nil {
		return nil, errors.New("email already registered")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &domain.User{
		Email:        email,
		PasswordHash: string(hashedPassword),
		RoleID:       3, // Default to mahasiswa for open registration
		Nama:         "User Baru",
		Status:       "active",
	}

	err = u.userRepo.Create(user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (u *userUsecase) Login(email, password string) (string, error) {
	user, err := u.userRepo.FindByEmail(email)
	if err != nil {
		return "", err
	}
	if user == nil {
		return "", errors.New("invalid email or password")
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return "", errors.New("invalid email or password")
	}

	// Generate JWT token
	token, err := jwt.GenerateToken(user.ID, user.RoleID)
	if err != nil {
		return "", err
	}

	return token, nil
}

func (u *userUsecase) ChangePassword(userID uint, currentPassword, newPassword string) error {
	// 1. Find the user
	user, err := u.userRepo.FindByID(userID)
	if err != nil || user == nil {
		return errors.New("user tidak ditemukan")
	}

	// 2. Verify current password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(currentPassword)); err != nil {
		return errors.New("password saat ini tidak sesuai")
	}

	// 3. Hash the new password
	hashed, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// 4. Persist
	return u.userRepo.UpdatePassword(userID, string(hashed))
}
