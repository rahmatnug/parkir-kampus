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

final List<WaitingList> dummyWaitingList = [
  WaitingList(
    namaPengguna: "Prof. Dr. Ir. Budi Santoso",
    role: "Dosen",
    waktuKedatangan: "08:45",
    estimasiTunggu: "2 Menit",
  ),
  WaitingList(
    namaPengguna: "Dr. Siti Aminah",
    role: "Dosen",
    waktuKedatangan: "08:50",
    estimasiTunggu: "5 Menit",
  ),
  WaitingList(
    namaPengguna: "Andi Wijaya",
    role: "Mahasiswa",
    waktuKedatangan: "08:30",
    estimasiTunggu: "12 Menit",
  ),
  WaitingList(
    namaPengguna: "Rina Permata",
    role: "Staff",
    waktuKedatangan: "08:55",
    estimasiTunggu: "8 Menit",
  ),
  WaitingList(
    namaPengguna: "Bagas Pratama",
    role: "Mahasiswa",
    waktuKedatangan: "08:35",
    estimasiTunggu: "15 Menit",
  ),
];
