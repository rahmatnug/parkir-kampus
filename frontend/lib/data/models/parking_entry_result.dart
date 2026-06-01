class ParkingEntryResult {
  final int transaksiId;
  final String nomorSlot;
  final String namaZona;
  final String status;
  final double xCoord;
  final double yCoord;

  ParkingEntryResult({
    required this.transaksiId,
    required this.nomorSlot,
    required this.namaZona,
    required this.status,
    required this.xCoord,
    required this.yCoord,
  });

  factory ParkingEntryResult.fromJson(Map<String, dynamic> json) {
    return ParkingEntryResult(
      transaksiId: json['id_transaksi'] as int? ?? 0,
      nomorSlot: json['nomor_slot'] as String? ?? '',
      namaZona: json['nama_zona'] as String? ?? '',
      status: json['status'] as String? ?? '',
      xCoord: (json['x_coord'] as num?)?.toDouble() ?? 0.0,
      yCoord: (json['y_coord'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_transaksi': transaksiId,
      'nomor_slot': nomorSlot,
      'nama_zona': namaZona,
      'status': status,
      'x_coord': xCoord,
      'y_coord': yCoord,
    };
  }
}
