class ParkingZone {
  final String id;
  final String nama;
  final int kapasitasMotor;
  final int kapasitasMobil;
  final int terpakaiMotor;
  final int terpakaiMobil;
  final double xCoord;
  final double yCoord;

  ParkingZone({
    required this.id,
    required this.nama,
    required this.kapasitasMotor,
    required this.kapasitasMobil,
    required this.terpakaiMotor,
    required this.terpakaiMobil,
    this.xCoord = 0.0,
    this.yCoord = 0.0,
  });

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
      kapasitasMotor: _safeInt(json['kapasitas_motor']),
      kapasitasMobil: _safeInt(json['kapasitas_mobil']),
      terpakaiMotor: _safeInt(json['terpakai_motor']),
      terpakaiMobil: _safeInt(json['terpakai_mobil']),
      xCoord: (json['x_coord'] as num?)?.toDouble() ?? 0.0,
      yCoord: (json['y_coord'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ParkingZone copyWith({int? terpakaiMotor, int? terpakaiMobil}) {
    return ParkingZone(
      id: id,
      nama: nama,
      kapasitasMotor: kapasitasMotor,
      kapasitasMobil: kapasitasMobil,
      terpakaiMotor: terpakaiMotor ?? this.terpakaiMotor,
      terpakaiMobil: terpakaiMobil ?? this.terpakaiMobil,
      xCoord: xCoord,
      yCoord: yCoord,
    );
  }

  bool get isFullMotor => kapasitasMotor > 0 && terpakaiMotor >= kapasitasMotor;
  bool get isFullMobil => kapasitasMobil > 0 && terpakaiMobil >= kapasitasMobil;
  bool get isFull => (kapasitasMotor == 0 || isFullMotor) && (kapasitasMobil == 0 || isFullMobil);

  String get letter {
    final parts = nama.split(' ');
    if (parts.length > 1) return parts.last[0];
    return nama.isNotEmpty ? nama[0] : '?';
  }
}
