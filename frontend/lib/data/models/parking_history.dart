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
