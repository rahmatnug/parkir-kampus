package usecase

import (
	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

type adminUsecase struct {
	adminRepo domain.AdminRepository
}

func NewAdminUsecase(repo domain.AdminRepository) domain.AdminUsecase {
	return &adminUsecase{
		adminRepo: repo,
	}
}

func (u *adminUsecase) GetDashboardData() (*domain.DashboardStats, error) {
	return u.adminRepo.GetDashboardStats()
}

func (u *adminUsecase) GetUsersList() ([]domain.AdminUserItem, error) {
	return u.adminRepo.GetAllUsers()
}

func (u *adminUsecase) GetActivityLogs() ([]domain.AdminActivityItem, error) {
	return u.adminRepo.GetAllActivities()
}
