package cron

import (
	"log"
	"time"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"github.com/robfig/cron/v3"
)

type CronJob struct {
	repo domain.ParkingRepository
}

func NewCronJob(repo domain.ParkingRepository) *CronJob {
	return &CronJob{repo}
}

func (j *CronJob) Init() {
	// Asia/Jakarta timezone
	jakarta, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		log.Printf("Failed to load timezone: %v", err)
		jakarta = time.Local
	}

	c := cron.New(cron.WithLocation(jakarta))

	// Every day at 23:59 WIB
	_, err = c.AddFunc("59 23 * * *", j.GhostExitJob)
	if err != nil {
		log.Fatalf("Failed to add cron job: %v", err)
	}

	c.Start()
	log.Println("Cron scheduler started (Ghost Exit at 23:59 WIB)")
}

func (j *CronJob) GhostExitJob() {
	log.Println("Starting Ghost Exit Job...")

	txs, err := j.repo.FindInParkTransactions()
	if err != nil {
		log.Printf("Error finding transactions: %v", err)
		return
	}

	now := time.Now()
	for _, tx := range txs {
		// 1. Force checkout
		tx.WaktuKeluar = &now
		tx.Status = "selesai_paksa"
		if err := j.repo.UpdateTransaksi(&tx); err != nil {
			log.Printf("Failed to force checkout tx %d: %v", tx.IDTransaksi, err)
			continue
		}

		// 2. Add penalty
		penalty := &domain.Penalti{
			UserID:           tx.UserID,
			JenisPelanggaran: "Tidak Tap-Out (Ghost Exit)",
			PoinPenalti:      10,
			Tanggal:          now,
		}
		if err := j.repo.CreatePenalti(penalty); err != nil {
			log.Printf("Failed to create penalty for user %d: %v", tx.UserID, err)
		}

		// 3. Release slot
		if err := j.repo.UpdateSlotStatus(tx.SlotID, "available"); err != nil {
			log.Printf("Failed to release slot %d: %v", tx.SlotID, err)
		}

		log.Printf("Forced checkout and added penalty for user %d", tx.UserID)
	}

	log.Println("Ghost Exit Job completed.")
}
