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

func (u *adminUsecase) DeleteUser(userID uint) error {
	return u.adminRepo.DeleteUser(userID)
}

func (u *adminUsecase) UpdateUserRole(userID uint, newRole string) error {
	return u.adminRepo.UpdateUserRole(userID, newRole)
}

func (u *adminUsecase) GetBlacklist() ([]domain.BlacklistItem, error) {
	return u.adminRepo.GetBlacklistedUsers()
}

func (u *adminUsecase) ForceExitActivity(activityID uint) error {
	return u.adminRepo.ForceExitActivity(activityID)
}

func (u *adminUsecase) AddPenalty(userID uint, poin int, keterangan string) error {
	return u.adminRepo.AddPenalty(userID, poin, keterangan)
}

func (u *adminUsecase) RemovePenalty(userID uint) error {
	return u.adminRepo.RemovePenalty(userID)
}

