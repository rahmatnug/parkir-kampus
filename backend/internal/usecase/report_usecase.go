package usecase

import (
	"errors"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
)

type reportUsecase struct {
	reportRepo domain.ReportRepository
}

// NewReportUsecase creates a new report usecase
func NewReportUsecase(repo domain.ReportRepository) domain.ReportUsecase {
	return &reportUsecase{
		reportRepo: repo,
	}
}

func (u *reportUsecase) GetDailyReport() (*domain.DailyReport, error) {
	return u.reportRepo.GetDailyReport()
}

func (u *reportUsecase) GetAnalyticalReport(startDate, endDate string) (*domain.AnalyticalReport, error) {
	if startDate == "" || endDate == "" {
		return nil, errors.New("start_date and end_date query parameters are required")
	}
	if startDate > endDate {
		return nil, errors.New("start_date must be before or equal to end_date")
	}
	return u.reportRepo.GetAnalyticalReport(startDate, endDate)
}

func (u *reportUsecase) GetAuditReport() (*domain.AuditReport, error) {
	return u.reportRepo.GetAuditReport()
}
