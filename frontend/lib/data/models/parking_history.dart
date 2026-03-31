enum HistoryStatus { selesai, penalti }

class ParkingHistory {
  final String tanggal;
  final String waktuMasuk;
  final String waktuKeluar;
  final String zona;
  final String slot;
  final HistoryStatus status;

  ParkingHistory({
    required this.tanggal,
    required this.waktuMasuk,
    required this.waktuKeluar,
    required this.zona,
    required this.slot,
    required this.status,
  });
}

final List<ParkingHistory> dummyHistoryData = [
  ParkingHistory(
    tanggal: "28 Mar 2026",
    waktuMasuk: "08:15",
    waktuKeluar: "12:30",
    zona: "Zona A",
    slot: "A-05",
    status: HistoryStatus.selesai,
  ),
  ParkingHistory(
    tanggal: "27 Mar 2026",
    waktuMasuk: "10:00",
    waktuKeluar: "18:15",
    zona: "Zona B",
    slot: "B-12",
    status: HistoryStatus.penalti,
  ),
  ParkingHistory(
    tanggal: "25 Mar 2026",
    waktuMasuk: "07:30",
    waktuKeluar: "15:45",
    zona: "Zona A",
    slot: "A-21",
    status: HistoryStatus.selesai,
  ),
  ParkingHistory(
    tanggal: "24 Mar 2026",
    waktuMasuk: "09:20",
    waktuKeluar: "11:05",
    zona: "Zona C",
    slot: "C-02",
    status: HistoryStatus.selesai,
  ),
  ParkingHistory(
    tanggal: "22 Mar 2026",
    waktuMasuk: "13:00",
    waktuKeluar: "17:30",
    zona: "Zona D",
    slot: "D-09",
    status: HistoryStatus.penalti,
  ),
];
