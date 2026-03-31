enum VehicleState {
  belumParkir,
  dalamAntrean,
  sedangParkir,
}

class VehicleStatus {
  final VehicleState state;
  final int? posisiAntrean;
  final String? zona;
  final String? slot;

  VehicleStatus({
    required this.state,
    this.posisiAntrean,
    this.zona,
    this.slot,
  });

  String get statusText {
    switch (state) {
      case VehicleState.belumParkir:
        return "Belum Parkir";
      case VehicleState.dalamAntrean:
        return "Dalam Antrean";
      case VehicleState.sedangParkir:
        return "Sedang Parkir";
    }
  }
}

/// Simulasi perubahan status kendaraan user secara otomatis
Stream<VehicleStatus> getVehicleStatusUpdates() async* {
  // 1. Awal: Belum Parkir
  yield VehicleStatus(state: VehicleState.belumParkir);
  await Future.delayed(const Duration(seconds: 4));

  // 2. Masuk Antrean (Posisi 3 -> 2 -> 1)
  for (int i = 3; i >= 1; i--) {
    yield VehicleStatus(state: VehicleState.dalamAntrean, posisiAntrean: i);
    await Future.delayed(const Duration(seconds: 3));
  }

  // 3. Sedang Parkir
  yield VehicleStatus(
    state: VehicleState.sedangParkir,
    zona: "Zona A",
    slot: "A-12",
  );
  
  // Tetap di status parkir selama simulasi berjalan
  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    yield VehicleStatus(
      state: VehicleState.sedangParkir,
      zona: "Zona A",
      slot: "A-12",
    );
  }
}
