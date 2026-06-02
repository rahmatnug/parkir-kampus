import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';
import 'package:intl/intl.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF4F5F7);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kRed     = Color(0xFFDC2626);
const _kRedLight= Color(0xFFFEE2E2);
const _kGreen   = Color(0xFF16A34A);
const _kOrange  = Color(0xFFF59E0B);
const _kYellow  = Color(0xFFEAB308);
const _kYellowLight = Color(0xFFFEF9C3);
const _kLightGray = Color(0xFFF8FAFC);
const _kPurpleLight = Color(0xFFF3F4F6);

class AdminReviewLaporanPage extends StatefulWidget {
  final int laporanId;
  const AdminReviewLaporanPage({super.key, required this.laporanId});

  @override
  State<AdminReviewLaporanPage> createState() => _AdminReviewLaporanPageState();
}

class _AdminReviewLaporanPageState extends State<AdminReviewLaporanPage> {
  final _adminService = AdminService();
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _laporanDetail;
  Map<String, dynamic>? _targetInfo;

  int _selectedPoin = 20;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final res = await _adminService.getLaporanDetail(widget.laporanId);
      if (mounted) {
        setState(() {
          _laporanDetail = res['laporan_detail']['laporan'];
          _targetInfo = res['laporan_detail']['target'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveLaporan() async {
    try {
      final pelanggaranStr = _laporanDetail?['deskripsi_pelanggaran'] ?? 'Parkir Sembarangan';
      await _adminService.approveLaporan(
        widget.laporanId,
        _selectedPoin,
        pelanggaranStr,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan disetujui & penalti ditambahkan!'), backgroundColor: _kGreen),
      );
      Navigator.pop(context, true); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: _kRed),
      );
    }
  }

  Future<void> _rejectLaporan() async {
    try {
      await _adminService.rejectLaporan(widget.laporanId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan ditolak dan dihapus dari antrean!'), backgroundColor: _kGreen),
      );
      Navigator.pop(context, true); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak laporan: $e'), backgroundColor: _kRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: _kBg,
          body: Row(
            children: [
              // A. Panel Kiri (Sidebar Navigasi)
              if (constraints.maxWidth > 800) const _MockSidebar(),
              
              // B. Panel Kanan (Area Konten Utama)
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error, style: const TextStyle(color: _kRed)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchDetail, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final laporan = _laporanDetail ?? {};
    final target = _targetInfo;
    final reporter = laporan['petugas'] ?? {};

    // Helper vars
    final String repName = reporter['nama'] ?? 'Tidak diketahui';
    final String repId = reporter['id'] != null ? 'ID: ATT-${reporter['id']}' : 'ID: -';
    
    String timeStr = '-';
    if (laporan['created_at'] != null) {
      try {
        final date = DateTime.parse(laporan['created_at'].toString()).toLocal();
        timeStr = DateFormat("dd MMM yyyy, HH:mm 'WIB'").format(date);
      } catch (_) {}
    }

    final String platNum = laporan['target_identifier'] ?? '-';
    
    String jenisKendaraan = '-';
    if (target != null && target['kendaraans'] != null && (target['kendaraans'] as List).isNotEmpty) {
      final k = target['kendaraans'][0];
      jenisKendaraan = '${k['jenis_kendaraan'] ?? '-'} - ${k['warna'] ?? '-'}';
    }

    final String targetName = target?['nama'] ?? 'Tidak diketahui';
    
    String targetRole = 'Tidak diketahui';
    if (target?['role']?['nama_role'] != null) {
      final String rawRole = target!['role']['nama_role'].toString();
      targetRole = rawRole.isNotEmpty 
          ? '${rawRole[0].toUpperCase()}${rawRole.substring(1)}' 
          : rawRole;
    }

    final String desc = laporan['deskripsi_pelanggaran'] ?? '-';
    final String fotoUrl = laporan['bukti_foto'] ?? '';
    final int currentPoin = target?['total_poin'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Posisi Atas (Header)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: _kText),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Review Laporan Pelanggaran',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _kText, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 2. Posisi Tengah (Layout Dua Kolom Asimetris)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Kiri: Kartu Detail Laporan
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Kotak
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Detail Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kText)),
                      ),
                      const Divider(height: 1, color: _kBorder),

                      // Baris 1: Informasi Dasar
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PELAPOR (ATTENDANT)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _kBorder,
                                      child: Icon(Icons.person, color: _kMuted),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(repName, style: const TextStyle(fontWeight: FontWeight.bold, color: _kText, fontSize: 15)),
                                        Text(repId, style: const TextStyle(color: _kMuted, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('WAKTU KEJADIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                                const SizedBox(height: 12),
                                Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, color: _kText, fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),

                      // Baris 2: INFORMASI KENDARAAN
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: _kLightGray, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Plat Nomor', style: TextStyle(fontSize: 12, color: _kMuted)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                                      child: Text(platNum, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Jenis Kendaraan', style: TextStyle(fontSize: 12, color: _kMuted)),
                                    const SizedBox(height: 8),
                                    Text(jenisKendaraan, style: const TextStyle(fontWeight: FontWeight.w600, color: _kText, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Pemilik Terdaftar:', style: TextStyle(fontSize: 12, color: _kMuted)),
                                    const SizedBox(height: 8),
                                    Text(targetName, style: const TextStyle(color: _kBlue, fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(targetRole, style: const TextStyle(color: _kMuted, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),

                      // Baris 3: KATEGORI PELANGGARAN
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('KATEGORI PELANGGARAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: _kRedLight, borderRadius: BorderRadius.circular(20)),
                              child: const Text('Parkir Sembarangan', style: TextStyle(color: _kRed, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),

                      // Baris 4: DESKRIPSI KEJADIAN
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DESKRIPSI KEJADIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: _kPurpleLight, borderRadius: BorderRadius.circular(8)),
                              child: Text(desc, style: const TextStyle(color: _kText, fontSize: 14, height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),

                      // Baris 5: ZONA / AREA
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ZONA / AREA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: _kMuted, size: 18),
                                SizedBox(width: 8),
                                Text('Zona A,', style: TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Kolom Kanan: Dua Kartu Bertumpuk
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Kartu 1: Bukti Foto
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kBorder),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Bukti Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kText)),
                          ),
                          const Divider(height: 1, color: _kBorder),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    fotoUrl.isNotEmpty ? fotoUrl : 'https://placehold.co/600x400/png',
                                    height: 260,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 260,
                                      width: double.infinity,
                                      color: _kBg,
                                      child: const Center(child: Icon(Icons.broken_image, color: _kMuted, size: 48)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      timeStr.replaceAll(' WIB', ''),
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kartu 2: Tindakan Administrator
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kBorder),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 6,
                            decoration: const BoxDecoration(color: _kBlue, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Tindakan Administrator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kText)),
                          ),
                          const Divider(height: 1, color: _kBorder),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Saat Ini
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(color: _kLightGray, borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Status Saat Ini:', style: TextStyle(color: _kMuted, fontSize: 14)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: _kYellowLight, borderRadius: BorderRadius.circular(20)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.warning_amber_rounded, color: _kYellow, size: 16),
                                            const SizedBox(width: 4),
                                            Text('Warning: $currentPoin/100 Poin', style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Poin Penalti
                                const Text('POIN PENALTI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Stepper
                                    Container(
                                      decoration: BoxDecoration(border: Border.all(color: _kBorder), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              if (_selectedPoin > 0) setState(() => _selectedPoin -= 5);
                                            },
                                            child: const Padding(padding: EdgeInsets.all(12), child: Text('–', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 40,
                                            color: _kBorder,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text('$_selectedPoin', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 40,
                                            color: _kBorder,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() => _selectedPoin += 5);
                                            },
                                            child: const Padding(padding: EdgeInsets.all(12), child: Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Formula
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(color: _kLightGray, borderRadius: BorderRadius.circular(8)),
                                        alignment: Alignment.center,
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 14, color: _kText),
                                            children: [
                                              TextSpan(text: '$currentPoin '),
                                              TextSpan(text: '+ $_selectedPoin', style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold)),
                                              TextSpan(text: ' = ${currentPoin + _selectedPoin} poin'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                
                                // Buttons
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _rejectLaporan,
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _kText,
                                        side: const BorderSide(color: _kBorder),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: target == null ? null : _approveLaporan,
                                        icon: const Icon(Icons.security, size: 18),
                                        label: const Text('Setujui & Tambah Poin Penalti', style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E3A8A), // Navy solid
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          disabledBackgroundColor: _kBorder,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar Mock (Mirip DashboardPage) ───────────────────────────────────────
class _MockSidebar extends StatelessWidget {
  const _MockSidebar();

  static const _items = [
    {'icon': Icons.grid_view_rounded, 'label': 'Dashboard'},
    {'icon': Icons.people_alt_outlined, 'label': 'Users'},
    {'icon': Icons.directions_car, 'label': 'Users'}, 
    {'icon': Icons.block_rounded, 'label': 'Blacklist'},
    {'icon': Icons.qr_code_rounded, 'label': 'QR Registry'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Header Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('P', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ParkirKampus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
                      SizedBox(height: 2),
                      Text('ADMIN MANAGEMENT', style: TextStyle(fontSize: 10, color: _kMuted, letterSpacing: 1.0, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final isSelected = i == 3; // "Blacklist" is active
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? _kBlue.withOpacity(0.05) : Colors.transparent,
                    border: Border(
                      right: BorderSide(
                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
                        width: 4.0,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(item['icon'] as IconData, color: isSelected ? _kText : _kMuted),
                    title: Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _kText : _kMuted,
                      ),
                    ),
                    onTap: () {
                      if (!isSelected) Navigator.pop(context); // Go back if clicked other menu
                    },
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1, color: _kBorder),
          // User Info Bottom
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _kOrange.withOpacity(0.2),
                  child: const Icon(Icons.person, color: _kOrange), 
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Parkir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
                      Text('Ganti Password?', style: TextStyle(fontSize: 12, color: _kBlue, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.logout, size: 20, color: _kMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

