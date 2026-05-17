class ParkingZone {
  final String id;
  final String nama;
  final int kapasitasMaksimal;
  final int terisiSaatIni;
  final String jenisKendaraan;
  final double xCoord;
  final double yCoord;

  ParkingZone({
    required this.id,
    required this.nama,
    required this.kapasitasMaksimal,
    required this.terisiSaatIni,
    this.jenisKendaraan = 'motor',
    this.xCoord = 0.0,
    this.yCoord = 0.0,
  });

  /// Parsing int yang aman — menangani tipe int maupun String dari API
  static int _safeInt(dynamic raw, {int fallback = 0}) {
    if (raw == null) return fallback;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw.toString()) ?? fallback;
  }

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      id: (json['id'] ?? json['id_zona'] ?? '').toString(),
      nama: (json['nama'] ?? json['nama_zona'] ?? '').toString(),
      // Parsing aman: cek 'kapasitas_maksimal' dulu, fallback ke 'kapasitas'
      kapasitasMaksimal: _safeInt(
        json['kapasitas_maksimal'] ?? json['kapasitas'],
      ),
      // Parsing aman: tidak ada default ?? 0.8 atau nilai palsu di sini
      terisiSaatIni: _safeInt(json['terisi_saat_ini']),
      jenisKendaraan: (json['jenis_kendaraan'] ?? 'motor').toString(),
      xCoord: (json['x_coord'] as num?)?.toDouble() ?? 0.0,
      yCoord: (json['y_coord'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ParkingZone copyWith({int? terisiSaatIni}) {
    return ParkingZone(
      id: id,
      nama: nama,
      kapasitasMaksimal: kapasitasMaksimal,
      terisiSaatIni: terisiSaatIni ?? this.terisiSaatIni,
      jenisKendaraan: jenisKendaraan,
      xCoord: xCoord,
      yCoord: yCoord,
    );
  }

  /// Available slots = capacity - occupied
  int get tersedia => kapasitasMaksimal - terisiSaatIni;

  /// Occupancy ratio (0.0 to 1.0)
  double get occupancyRatio =>
      kapasitasMaksimal > 0 ? terisiSaatIni / kapasitasMaksimal : 0.0;

  /// Zone letter (e.g. "A" from "Zone A")
  String get letter {
    final parts = nama.split(' ');
    if (parts.length > 1) return parts.last[0];
    return nama.isNotEmpty ? nama[0] : '?';
  }
}
