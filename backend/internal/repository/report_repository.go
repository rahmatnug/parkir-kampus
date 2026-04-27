package repository

import (
	"fmt"
	"time"

	"github.com/rahmatnug/parkir-kampus-backend/internal/domain"
	"gorm.io/gorm"
)

type reportRepository struct {
	db *gorm.DB
}

// NewReportRepository returns a read-only repository for reporting queries.
// All queries use SQL JOINs & GROUP BY on a separate read path so they
// never interfere with the real-time transaction flow.
func NewReportRepository(db *gorm.DB) domain.ReportRepository {
	return &reportRepository{db: db}
}

// ──────────────────────────────────────────────────────────────────────────────
// GET /api/v1/reports/daily
// ──────────────────────────────────────────────────────────────────────────────

func (r *reportRepository) GetDailyReport() (*domain.DailyReport, error) {
	today := time.Now().Format("2006-01-02")

	// 1) Okupansi per zona — LEFT JOIN + GROUP BY
	var occupancies []domain.ZoneOccupancy
	err := r.db.Raw(`
		SELECT
			zp.id_zona,
			zp.nama_zona,
			zp.kapasitas,
			COALESCE(COUNT(t.id_transaksi), 0) AS terisi
		FROM zona_parkirs zp
		LEFT JOIN slot_parkirs sp ON sp.id_zona = zp.id_zona
		LEFT JOIN transaksis t   ON t.id_slot = sp.id_slot AND t.status = 'parkir'
		WHERE zp.status = 'active'
		GROUP BY zp.id_zona, zp.nama_zona, zp.kapasitas
		ORDER BY zp.id_zona
	`).Scan(&occupancies).Error
	if err != nil {
		return nil, fmt.Errorf("occupancy query: %w", err)
	}
	for i := range occupancies {
		occupancies[i].Tersedia = occupancies[i].Kapasitas - occupancies[i].Terisi
		if occupancies[i].Tersedia < 0 {
			occupancies[i].Tersedia = 0
		}
		if occupancies[i].Kapasitas > 0 {
			occupancies[i].OkupasiPct = float64(occupancies[i].Terisi) / float64(occupancies[i].Kapasitas) * 100
		}
	}

	// 2) Antrian saat ini per zona — GROUP BY
	var queues []domain.QueueSnapshot
	err = r.db.Raw(`
		SELECT
			zp.id_zona,
			zp.nama_zona,
			COALESCE(COUNT(wl.id_waiting), 0) AS jumlah_antri
		FROM zona_parkirs zp
		LEFT JOIN waiting_lists wl ON wl.id_zona = zp.id_zona
		WHERE zp.status = 'active'
		GROUP BY zp.id_zona, zp.nama_zona
		ORDER BY zp.id_zona
	`).Scan(&queues).Error
	if err != nil {
		return nil, fmt.Errorf("queue query: %w", err)
	}

	// 3) Total kendaraan masuk hari ini
	var totalMasuk int
	err = r.db.Raw(`
		SELECT COALESCE(COUNT(*), 0)
		FROM transaksis
		WHERE DATE(waktu_masuk) = ?
	`, today).Scan(&totalMasuk).Error
	if err != nil {
		return nil, fmt.Errorf("total masuk query: %w", err)
	}

	return &domain.DailyReport{
		Tanggal:             today,
		OkupasiPerZona:      occupancies,
		AntrianSaatIni:      queues,
		TotalKendaraanMasuk: totalMasuk,
	}, nil
}

// ──────────────────────────────────────────────────────────────────────────────
// GET /api/v1/reports/analytical?start_date=...&end_date=...
// ──────────────────────────────────────────────────────────────────────────────

func (r *reportRepository) GetAnalyticalReport(startDate, endDate string) (*domain.AnalyticalReport, error) {

	// 1) AWT (Average Wait Time) per role — JOIN + GROUP BY
	//    "Wait time" = waktu_keluar - waktu_masuk for completed transactions.
	var awtRows []domain.AWTPerRole
	err := r.db.Raw(`
		SELECT
			ro.nama_role AS role,
			COALESCE(AVG(EXTRACT(EPOCH FROM (t.waktu_keluar - t.waktu_masuk)) / 60), 0) AS avg_wait_minutes
		FROM transaksis t
		JOIN users u  ON u.id_user  = t.id_user
		JOIN roles ro ON ro.id_role = u.id_role
		WHERE t.waktu_keluar IS NOT NULL
		  AND DATE(t.waktu_masuk) BETWEEN ? AND ?
		GROUP BY ro.nama_role
		ORDER BY ro.nama_role
	`, startDate, endDate).Scan(&awtRows).Error
	if err != nil {
		return nil, fmt.Errorf("awt query: %w", err)
	}

	// 2) Grafik jam sibuk — EXTRACT hour + GROUP BY
	var hourly []domain.HourlyTraffic
	err = r.db.Raw(`
		SELECT
			EXTRACT(HOUR FROM waktu_masuk)::int AS jam,
			COUNT(*) AS total
		FROM transaksis
		WHERE DATE(waktu_masuk) BETWEEN ? AND ?
		GROUP BY EXTRACT(HOUR FROM waktu_masuk)
		ORDER BY jam
	`, startDate, endDate).Scan(&hourly).Error
	if err != nil {
		return nil, fmt.Errorf("hourly query: %w", err)
	}

	// 3) Total kendaraan dalam rentang tanggal
	var totalKendaraan int
	err = r.db.Raw(`
		SELECT COALESCE(COUNT(*), 0)
		FROM transaksis
		WHERE DATE(waktu_masuk) BETWEEN ? AND ?
	`, startDate, endDate).Scan(&totalKendaraan).Error
	if err != nil {
		return nil, fmt.Errorf("total kendaraan query: %w", err)
	}

	return &domain.AnalyticalReport{
		StartDate:      startDate,
		EndDate:        endDate,
		AWTPerRole:     awtRows,
		GrafikJamSibuk: hourly,
		TotalKendaraan: totalKendaraan,
	}, nil
}

// ──────────────────────────────────────────────────────────────────────────────
// GET /api/v1/reports/audit
// ──────────────────────────────────────────────────────────────────────────────

func (r *reportRepository) GetAuditReport() (*domain.AuditReport, error) {

	// 1) Top penalty users — JOIN + GROUP BY + ORDER BY SUM DESC
	var topPenalty []domain.PenaltyTopUser
	err := r.db.Raw(`
		SELECT
			u.id_user,
			u.nama,
			u.email,
			COALESCE(SUM(p.poin_penalti), 0) AS total_poin,
			COUNT(p.id_penalti) AS jumlah_kasus
		FROM penaltis p
		JOIN users u ON u.id_user = p.id_user
		GROUP BY u.id_user, u.nama, u.email
		ORDER BY total_poin DESC
		LIMIT 20
	`).Scan(&topPenalty).Error
	if err != nil {
		return nil, fmt.Errorf("penalty query: %w", err)
	}

	// 2) Riwayat blacklist — JOIN
	var blacklists []domain.BlacklistRecord
	err = r.db.Raw(`
		SELECT
			b.id_blacklist,
			b.id_user,
			u.nama,
			b.alasan,
			b.tanggal_mulai,
			b.tanggal_selesai,
			b.status
		FROM blacklists b
		JOIN users u ON u.id_user = b.id_user
		ORDER BY b.tanggal_mulai DESC
		LIMIT 50
	`).Scan(&blacklists).Error
	if err != nil {
		return nil, fmt.Errorf("blacklist query: %w", err)
	}

	// 3) Histori akses ilegal — status = 'illegal' or 'ditolak'
	var illegal []domain.IllegalAccessRecord
	err = r.db.Raw(`
		SELECT
			t.id_transaksi,
			t.id_user,
			u.nama,
			k.nomor_polisi,
			t.waktu_masuk,
			t.status
		FROM transaksis t
		JOIN users u      ON u.id_user       = t.id_user
		JOIN kendaraans k ON k.id_kendaraan  = t.id_kendaraan
		WHERE t.status IN ('illegal', 'ditolak', 'forced_checkout')
		ORDER BY t.waktu_masuk DESC
		LIMIT 50
	`).Scan(&illegal).Error
	if err != nil {
		return nil, fmt.Errorf("illegal access query: %w", err)
	}

	return &domain.AuditReport{
		TopPenaltyUsers:  topPenalty,
		RiwayatBlacklist: blacklists,
		AksesIlegal:      illegal,
	}, nil
}
