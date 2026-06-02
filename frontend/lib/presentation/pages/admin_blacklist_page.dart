import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';
import 'admin_review_laporan_page.dart'; // Just in case they want detail action to open this? Wait, action detail is not fully specified, I'll just print it or do something placeholder, or actually they might want a simple dialog.

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF4F5F7);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kRed     = Color(0xFFDC2626);
const _kOrange  = Color(0xFFF59E0B);
const _kYellow  = Color(0xFFEAB308);
const _kGreen   = Color(0xFF16A34A);

class AdminBlacklistPage extends StatefulWidget {
  const AdminBlacklistPage({super.key});

  @override
  State<AdminBlacklistPage> createState() => _AdminBlacklistPageState();
}

class _AdminBlacklistPageState extends State<AdminBlacklistPage> {
  final _adminService = AdminService();
  bool _isLoading = true;
  List<dynamic> _items = [];
  List<dynamic> _pendingLaporan = [];
  Map<String, dynamic> _stats = {};
  String _error = '';
  
  String _activeFilter = 'Semua';
  final List<String> _filters = ['Semua', 'CRITICAL', 'WARNING', 'SAFE'];

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _startSilentPolling();
  }

  void _startSilentPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _silentFetch();
    });
  }

  Future<void> _silentFetch() async {
    try {
      final data = await _adminService.getBlacklist();
      final stats = await _adminService.getBlacklistStats();
      final pending = await _adminService.getPendingLaporan();
      if (mounted) {
        setState(() {
          _items = data;
          _stats = stats;
          _pendingLaporan = pending;
        });
      }
    } catch (_) {
      // ignore silently
    }
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final data = await _adminService.getBlacklist();
      final stats = await _adminService.getBlacklistStats();
      final pending = await _adminService.getPendingLaporan();
      if (mounted) {
        setState(() {
          _items = data;
          _stats = stats;
          _pendingLaporan = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<dynamic> get _filteredItems {
    if (_activeFilter == 'Semua') return _items;
    return _items.where((item) => item['status_peringatan'] == _activeFilter).toList();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: _kBlue,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              const Text('Blacklist Management', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _kText)),
              const SizedBox(height: 4),
              const Text('Review and manage user penalty points and restrictions.', style: TextStyle(fontSize: 13, color: _kMuted)),
              const SizedBox(height: 24),

              // ── Summary Cards ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL BLACKLISTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Text('${_stats['total_blacklisted'] ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kText)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACTIVE RESTRICTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Text('${_stats['active_restrictions'] ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kText)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Main Content Container ───────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filter Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
                      child: Row(
                        children: _filters.map((f) {
                          final isSelected = _activeFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: InkWell(
                              onTap: () => setState(() => _activeFilter = f),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? _kBlue.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? _kBlue : _kBorder),
                                ),
                                child: Text(f, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? _kBlue : _kMuted)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    // Table Header
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1100, // Minimum width for the table
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFCFDFE),
                                border: Border(bottom: BorderSide(color: _kBorder)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(flex: 3, child: _Th('USER')),
                                  Expanded(flex: 2, child: _Th('ROLE')),
                                  Expanded(flex: 2, child: _Th('PLAT NOMOR')),
                                  Expanded(flex: 2, child: _Th('TOTAL POIN')),
                                  Expanded(flex: 1, child: _Th('KASUS')),
                                  Expanded(flex: 3, child: _Th('PELANGGARAN TERAKHIR')),
                                  Expanded(flex: 2, child: _Th('STATUS')),
                                  Expanded(flex: 2, child: _Th('ACTION')),
                                ],
                              ),
                            ),
                            
                            // Rows
                            if (_isLoading)
                              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: _kBlue)))
                            else if (_filteredItems.isEmpty)
                              const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Tidak ada data.', style: TextStyle(color: _kMuted))))
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredItems.length,
                                itemBuilder: (ctx, i) => _BlacklistRow(item: _filteredItems[i]),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ── Kotak Masuk Laporan ────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.inbox_rounded, color: _kBlue),
                  const SizedBox(width: 8),
                  const Text('Kotak Masuk Laporan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kText)),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: _kBlue))
              else if (_pendingLaporan.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('Tidak ada laporan masuk', style: TextStyle(color: _kMuted))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingLaporan.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final laporan = _pendingLaporan[i];
                    final String tipe = laporan['tipe_pelanggaran'] ?? 'Tidak diketahui';
                    final String plat = laporan['nomor_polisi'] ?? '-';
                    final String petugas = laporan['nama_petugas'] ?? 'Unknown';
                    final String createdAt = laporan['created_at'] ?? '';
                    
                    // Simple time ago
                    String timeAgo = '';
                    if (createdAt.isNotEmpty) {
                      try {
                        final diff = DateTime.now().difference(DateTime.parse(createdAt));
                        if (diff.inDays > 0) {
                          timeAgo = '${diff.inDays}d ago';
                        } else if (diff.inHours > 0) {
                          timeAgo = '${diff.inHours}h ago';
                        } else if (diff.inMinutes > 0) {
                          timeAgo = '${diff.inMinutes}m ago';
                        } else {
                          timeAgo = 'Just now';
                        }
                      } catch (_) {
                        timeAgo = createdAt;
                      }
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: const Border(
                          left: BorderSide(color: Colors.red, width: 4),
                          top: BorderSide(color: _kBorder),
                          right: BorderSide(color: _kBorder),
                          bottom: BorderSide(color: _kBorder),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          // BLOK 1: TIPE PELANGGARAN
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TIPE PELANGGARAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kMuted)),
                                const SizedBox(height: 4),
                                Text(tipe, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kText)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // BLOK 2: PLAT NOMOR
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Plat Nomor', style: TextStyle(fontSize: 10, color: _kMuted)),
                                  const SizedBox(height: 2),
                                  Text(plat, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: _kText)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // BLOK 3: PETUGAS & WAKTU
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(timeAgo, style: const TextStyle(fontSize: 11, color: _kMuted)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.assignment_ind_rounded, size: 14, color: _kMuted),
                                    const SizedBox(width: 4),
                                    Text('Petugas: $petugas', style: const TextStyle(fontSize: 12, color: _kMuted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          
                          // BLOK 4: AKSI
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminReviewLaporanPage(laporanId: laporan['id_laporan']),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kText,
                              side: const BorderSide(color: _kBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: _kMuted, letterSpacing: 0.5));
  }
}

class _BlacklistRow extends StatefulWidget {
  final dynamic item;
  const _BlacklistRow({required this.item});

  @override
  State<_BlacklistRow> createState() => _BlacklistRowState();
}

class _BlacklistRowState extends State<_BlacklistRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    
    final String namaUser = item['nama_user'] ?? 'Unknown';
    final String nim = item['nim'] ?? '-';
    final String avatarUrl = item['avatar_url'] ?? '';
    final String role = item['nama_role'] ?? 'Unassigned';
    final String platNomor = item['nomor_polisi'] ?? '-';
    final int totalPoin = (item['total_poin'] as num?)?.toInt() ?? 0;
    final int kasus = (item['jumlah_kasus'] as num?)?.toInt() ?? 0;
    final String pelanggaran = item['pelanggaran_terakhir'] ?? '-';
    final String status = item['status_peringatan'] ?? 'Warning';

    // Status styling
    Color statusColor;
    Color statusBg;
    if (status == 'CRITICAL') {
      statusColor = _kRed;
      statusBg = _kRed.withOpacity(0.1);
    } else if (status == 'WARNING') {
      statusColor = _kOrange;
      statusBg = _kOrange.withOpacity(0.1);
    } else {
      statusColor = _kGreen;
      statusBg = _kGreen.withOpacity(0.1);
    }

    // Poin color
    Color poinColor = totalPoin >= 100 ? _kRed : (totalPoin >= 60 ? _kOrange : _kYellow);
    double progress = totalPoin / 100.0;
    if (progress > 1.0) progress = 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF8F9FB) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            // USER
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _kBlue.withOpacity(0.1),
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 20, color: _kBlue) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(namaUser, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText), overflow: TextOverflow.ellipsis),
                        if (nim != '-') Text(nim, style: const TextStyle(fontSize: 11, color: _kMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // ROLE
            Expanded(
              flex: 2,
              child: Text(role, style: const TextStyle(fontSize: 12, color: _kText, fontWeight: FontWeight.w500)),
            ),

            // PLAT NOMOR
            Expanded(
              flex: 2,
              child: Text(platNomor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
            ),

            // TOTAL POIN
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$totalPoin pts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: poinColor)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: _kBorder,
                      color: poinColor,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // KASUS
            Expanded(
              flex: 1,
              child: Text('$kasus', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
            ),

            // PELANGGARAN TERAKHIR
            Expanded(
              flex: 3,
              child: Text(pelanggaran, style: const TextStyle(fontSize: 12, color: _kMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),

            // STATUS
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),

            // ACTION
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Detail for $namaUser selected')),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Detail >',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kBlue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
