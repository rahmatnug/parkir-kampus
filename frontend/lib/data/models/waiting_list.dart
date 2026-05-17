class WaitingList {
  final String namaPengguna;
  final String role; // Dosen, Staff, Mahasiswa
  final String waktuKedatangan;
  final String estimasiTunggu;

  WaitingList({
    required this.namaPengguna,
    required this.role,
    required this.waktuKedatangan,
    required this.estimasiTunggu,
  });
}
