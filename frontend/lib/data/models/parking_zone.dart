class ParkingZone {
  final String id;
  final String nama;
  final int kapasitasMaksimal;
  final int terisiSaatIni;

  ParkingZone({
    required this.id,
    required this.nama,
    required this.kapasitasMaksimal,
    required this.terisiSaatIni,
  });

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    return ParkingZone(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      kapasitasMaksimal: json['kapasitas_maksimal'] ?? 0,
      terisiSaatIni: json['terisi_saat_ini'] ?? 0,
    );
  }

  ParkingZone copyWith({int? terisiSaatIni}) {
    return ParkingZone(
      id: id,
      nama: nama,
      kapasitasMaksimal: kapasitasMaksimal,
      terisiSaatIni: terisiSaatIni ?? this.terisiSaatIni,
    );
  }
}

final List<Map<String, dynamic>> dummyZonesJson = [
  {"id": "1", "nama": "Zona A", "kapasitas_maksimal": 50, "terisi_saat_ini": 10},
  {"id": "2", "nama": "Zona B", "kapasitas_maksimal": 30, "terisi_saat_ini": 30},
  {"id": "3", "nama": "Zona C", "kapasitas_maksimal": 40, "terisi_saat_ini": 25},
  {"id": "4", "nama": "Zona D", "kapasitas_maksimal": 20, "terisi_saat_ini": 5},
  {"id": "5", "nama": "Zona E", "kapasitas_maksimal": 60, "terisi_saat_ini": 60},
];

Stream<List<ParkingZone>> getParkingUpdates() async* {
  var zones = dummyZonesJson.map((e) => ParkingZone.fromJson(e)).toList();
  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    zones = zones.map((z) {
      int change = (DateTime.now().second % 2 == 0) ? 1 : -1;
      int newVal = (z.terisiSaatIni + change).clamp(0, z.kapasitasMaksimal);
      return z.copyWith(terisiSaatIni: newVal);
    }).toList();
    yield zones;
  }
}
