import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';
import 'export_preview_page.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF6F6F8);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kGreen   = Color(0xFF16A34A);
const _kGray    = Color(0xFF64748B);
const _kOrange  = Color(0xFFF59E0B);

// ─── Status helpers ───────────────────────────────────────────────────────────
enum _ParkStatus { parked, exited, overstay, unknown }

_ParkStatus _resolveStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'parkir':   return _ParkStatus.parked;
    case 'selesai':  return _ParkStatus.exited;
    case 'overstay': return _ParkStatus.overstay;
    default:         return _ParkStatus.unknown;
  }
}

Color _statusFg(_ParkStatus s) {
  switch (s) {
    case _ParkStatus.parked:   return _kGreen;
    case _ParkStatus.exited:   return _kGray;
    case _ParkStatus.overstay: return _kOrange;
    case _ParkStatus.unknown:  return _kMuted;
  }
}

Color _statusBg(_ParkStatus s) => _statusFg(s).withValues(alpha: 0.10);

String _statusLabel(_ParkStatus s) {
  switch (s) {
    case _ParkStatus.parked:   return 'PARKED';
    case _ParkStatus.exited:   return 'EXITED';
    case _ParkStatus.overstay: return 'OVERSTAY';
    case _ParkStatus.unknown:  return 'UNKNOWN';
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class AktivitasParkirPage extends StatefulWidget {
  const AktivitasParkirPage({super.key});

  @override
  State<AktivitasParkirPage> createState() => _AktivitasParkirPageState();
}

class _AktivitasParkirPageState extends State<AktivitasParkirPage> {
  final _adminService = AdminService();
  final _searchCtrl   = TextEditingController();

  bool          _isLoading  = true;
  List<dynamic> _activities = [];
  String        _filterStatus = 'All Status';
  String        _searchQuery  = '';

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(() {
      setState(() { _searchQuery = _searchCtrl.text; _currentPage = 1; });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final act = await _adminService.getActivities();
      if (mounted) setState(() { _activities = act; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Derived data ──────────────────────────────────────────────────────────
  List<dynamic> get _filtered {
    return _activities.where((a) {
      final q  = _searchQuery.toLowerCase();
      final st = a['status'] ?? '';
      bool matchStatus = true;
      if (_filterStatus == 'PARKED')   matchStatus = st == 'parkir';
      if (_filterStatus == 'EXITED')   matchStatus = st == 'selesai';
      if (_filterStatus == 'OVERSTAY') matchStatus = st == 'overstay';

      bool matchSearch = q.isEmpty ||
          (a['user_name'] ?? '').toLowerCase().contains(q) ||
          (a['nomor_polisi'] ?? '').toLowerCase().contains(q) ||
          (a['zona'] ?? '').toLowerCase().contains(q);

      return matchStatus && matchSearch;
    }).toList();
  }

  int get _parkedCount   => _activities.where((a) => a['status'] == 'parkir').length;
  int get _overstayCount => _activities.where((a) => a['status'] == 'overstay').length;
  int get _todayCount    => _activities.where((a) {
    if (a['waktu_masuk'] == null) return false;
    final dt = DateTime.tryParse(a['waktu_masuk']);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }).length;

  // occupancy is always 85% (static per spec or can be computed)
  static const int _occupancyPercent = 85;

  // Paginated rows
  List<dynamic> get _pageRows {
    final all = _filtered;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= all.length) return [];
    return all.sublist(start, (start + _pageSize).clamp(0, all.length));
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 99999);

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kBlue)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: _kBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page header ────────────────────────────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aktivitas Parkir',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _kText)),
                      const SizedBox(height: 4),
                      Text('${_activities.length} total aktivitas tercatat',
                          style: const TextStyle(fontSize: 13, color: _kMuted)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded, color: _kMuted),
                    onPressed: _fetch,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Summary Cards ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _OccupancyCard(
                      title: 'Total Occupancy',
                      percent: _occupancyPercent,
                      trend: '+2%',
                      trendUp: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.directions_car_rounded,
                      iconColor: _kBlue,
                      title: 'Parkir Terisi',
                      value: '$_parkedCount',
                      subtitle: 'Kendaraan aktif',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: _kGreen,
                      title: 'Slot Tersedia',
                      value: '—',
                      subtitle: 'Real-time data',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today_rounded,
                      iconColor: _kOrange,
                      title: 'Terparkir Hari Ini',
                      value: '$_todayCount',
                      subtitle: 'Transaksi hari ini',
                      badge: _overstayCount > 0 ? '$_overstayCount overstay' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Activity Log Table ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toolbar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          const Text('Real-time Activity Log',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _kText)),
                          const SizedBox(width: 12),
                          // Live indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: _kGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Live',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _kGreen)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Status dropdown
                          _Dropdown(
                            value: _filterStatus,
                            items: const [
                              'All Status',
                              'PARKED',
                              'EXITED',
                              'OVERSTAY',
                            ],
                            onChanged: (v) => setState(() {
                              _filterStatus = v!;
                              _currentPage = 1;
                            }),
                          ),
                          const SizedBox(width: 10),
                          // Search bar
                          SizedBox(
                            width: 220,
                            height: 38,
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(
                                  fontSize: 13, color: _kText),
                              decoration: InputDecoration(
                                hintText: 'Cari nama, plat, zona...',
                                hintStyle: const TextStyle(
                                    fontSize: 13, color: _kMuted),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    size: 18, color: _kMuted),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded,
                                            size: 16, color: _kMuted),
                                        onPressed: () => _searchCtrl.clear(),
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                filled: true,
                                fillColor: _kBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: _kBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: _kBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: _kBlue),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Export button
                          ElevatedButton.icon(
                            onPressed: _openExportPreview,
                            icon:
                                const Icon(Icons.download_rounded, size: 15),
                            label: const Text('Export',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Column headers
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCFDFE),
                        border: Border(
                          top: BorderSide(color: _kBorder),
                          bottom: BorderSide(color: _kBorder),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _Th('USER')),
                          Expanded(flex: 2, child: _Th('VEHICLE PLATE')),
                          Expanded(flex: 3, child: _Th('ZONA')),
                          Expanded(flex: 2, child: _Th('ENTRY TIME')),
                          Expanded(flex: 2, child: _Th('EXIT TIME')),
                          Expanded(flex: 2, child: _Th('STATUS')),
                          Expanded(flex: 1, child: _Th('ACTION')),
                        ],
                      ),
                    ),

                    // Rows
                    if (_filtered.isEmpty)
                      _EmptyState(
                        hasFilter: _filterStatus != 'All Status' ||
                            _searchQuery.isNotEmpty,
                        onReset: () {
                          setState(() {
                            _filterStatus = 'All Status';
                            _searchCtrl.clear();
                          });
                        },
                      )
                    else
                      ..._pageRows.map((log) => _LogRow(log: log)),

                    // Pagination footer
                    _PaginationBar(
                      showing: _pageRows.length,
                      total: _filtered.length,
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      onPrev: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                      onNext: _currentPage < _totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                      onPage: (p) => setState(() => _currentPage = p),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openExportPreview() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExportPreviewPage(activities: _activities),
    ));
  }
}

// ─── Occupancy Card ───────────────────────────────────────────────────────────
class _OccupancyCard extends StatelessWidget {
  final String title;
  final int    percent;
  final String trend;
  final bool   trendUp;

  const _OccupancyCard({
    required this.title,
    required this.percent,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.donut_large_rounded,
                    size: 20, color: _kBlue),
              ),
              const Spacer(),
              Row(children: [
                Icon(
                  trendUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: trendUp ? _kGreen : Colors.red,
                ),
                const SizedBox(width: 3),
                Text(trend,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trendUp ? _kGreen : Colors.red)),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 4),
          Text('$percent%',
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _kText)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: _kBg,
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generic Stat Card ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   value;
  final String   subtitle;
  final String?  badge;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          fontSize: 10,
                          color: _kOrange,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _kText)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: _kMuted)),
        ],
      ),
    );
  }
}

// ─── Dropdown Filter ──────────────────────────────────────────────────────────
class _Dropdown extends StatelessWidget {
  final String         value;
  final List<String>   items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon:
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _kMuted),
          style: const TextStyle(fontSize: 13, color: _kText),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Table header cell ────────────────────────────────────────────────────────
class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kMuted,
            letterSpacing: 0.5));
  }
}

// ─── Log Row ──────────────────────────────────────────────────────────────────
class _LogRow extends StatefulWidget {
  final dynamic log;
  const _LogRow({required this.log});

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final log    = widget.log;
    final st     = _resolveStatus(log['status'] ?? '');
    final name   = log['user_name'] ?? 'Unknown';
    final i1     = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final i2     = name.length > 1 ? name[1].toUpperCase() : '';

    String fmt(String? raw) {
      if (raw == null) return '—';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return '—';
      final l = dt.toLocal();
      return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} '
          '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    }

    final rawPlate = log['nomor_polisi'] ?? '—';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF8F9FB) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            // User
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFDDEAFF),
                    child: Text('$i1$i2',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _kBlue)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kText),
                            overflow: TextOverflow.ellipsis),
                        Text(log['role'] ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: _kMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Plate
            Expanded(
              flex: 2,
              child: Text(rawPlate,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                      letterSpacing: 0.5)),
            ),
            // Zone
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: _kMuted),
                  const SizedBox(width: 4),
                  Text(log['zona'] ?? '—',
                      style: const TextStyle(
                          fontSize: 13, color: _kText)),
                ],
              ),
            ),
            // Entry
            Expanded(
              flex: 2,
              child: Text(fmt(log['waktu_masuk']),
                  style: const TextStyle(fontSize: 13, color: _kText)),
            ),
            // Exit
            Expanded(
              flex: 2,
              child: Text(fmt(log['waktu_keluar']),
                  style: const TextStyle(fontSize: 13, color: _kMuted)),
            ),
            // Status badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg(st),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_statusLabel(st),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _statusFg(st))),
                ),
              ),
            ),
            // Action
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.more_horiz_rounded, size: 20, color: _kMuted),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (value) => _handleAction(context, value, log),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: _kBlue),
                          SizedBox(width: 8),
                          Text('Lihat Detail', style: TextStyle(fontSize: 13, color: _kText)),
                        ],
                      ),
                    ),
                    if (st == _ParkStatus.parked || st == _ParkStatus.overstay)
                      const PopupMenuItem(
                        value: 'force_exit',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: _kGreen),
                            SizedBox(width: 8),
                            Text('Force Exit', style: TextStyle(fontSize: 13, color: _kText)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'penalti',
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: _kOrange),
                          SizedBox(width: 8),
                          Text('Catat Pelanggaran', style: TextStyle(fontSize: 13, color: _kText)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action, dynamic log) {
    if (action == 'detail') {
      _showDetailDialog(context, log);
    } else if (action == 'force_exit') {
      _forceExit(context, log);
    } else if (action == 'penalti') {
      _showPenaltyDialog(context, log);
    }
  }

  void _showDetailDialog(BuildContext context, dynamic log) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Detail Aktivitas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Nama', log['user_name'] ?? '-'),
            _DetailRow('Role', log['role'] ?? '-'),
            _DetailRow('Kendaraan', '${log['jenis_kendaraan'] ?? '-'} (${log['nomor_polisi'] ?? '-'})'),
            _DetailRow('Zona', log['zona'] ?? '-'),
            _DetailRow('Waktu Masuk', log['waktu_masuk'] != null ? DateTime.parse(log['waktu_masuk']).toLocal().toString() : '-'),
            _DetailRow('Waktu Keluar', log['waktu_keluar'] != null ? DateTime.parse(log['waktu_keluar']).toLocal().toString() : 'Belum keluar'),
            _DetailRow('Status', log['status'] ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: _kBlue)),
          ),
        ],
      ),
    );
  }

  Future<void> _forceExit(BuildContext context, dynamic log) async {
    try {
      final adminService = AdminService();
      await adminService.forceExitActivity(log['id_transaksi'] as int);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendaraan berhasil dikeluarkan (Force Exit)'), backgroundColor: _kGreen),
      );
      // Let the parent refresh the list
      context.findAncestorStateOfType<_AktivitasParkirPageState>()?._fetch();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPenaltyDialog(BuildContext context, dynamic log) async {
    int poin = 10;
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Catat Pelanggaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: ${log['user_name']} (${log['nomor_polisi']})', style: const TextStyle(fontSize: 13, color: _kMuted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Poin Penalti:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    dropdownColor: Colors.white,
                    value: poin,
                    items: [10, 20, 30, 50].map((e) => DropdownMenuItem(value: e, child: Text('$e poin', style: const TextStyle(color: Colors.black87)))).toList(),
                    onChanged: (v) { if (v != null) setLocal(() => poin = v); },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8F9FB),
                  hintText: 'Keterangan (misal: Overstay, Parkir sembarangan)',
                  hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: _kMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kOrange, foregroundColor: Colors.white, elevation: 0),
              onPressed: () async {
                if (noteCtrl.text.isEmpty) return;
                try {
                  final adminService = AdminService();
                  await adminService.addPenalty(log['id_user'] as int, poin, noteCtrl.text);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Penalti berhasil dicatat'), backgroundColor: _kGreen),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: _kMuted, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: _kText))),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onReset;
  const _EmptyState({required this.hasFilter, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              hasFilter
                  ? Icons.search_off_rounded
                  : Icons.inbox_rounded,
              size: 52,
              color: _kBorder,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter
                  ? 'Tidak ada data yang cocok'
                  : 'Belum ada aktivitas parkir',
              style: const TextStyle(fontSize: 14, color: _kMuted),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onReset,
                child: const Text('Reset filter',
                    style: TextStyle(color: _kBlue)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Pagination bar ───────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int          showing;
  final int          total;
  final int          currentPage;
  final int          totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onPage;

  const _PaginationBar({
    required this.showing,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text('Showing $showing of $total entries',
              style: const TextStyle(fontSize: 13, color: _kMuted)),
          const Spacer(),
          _PageBtn('Previous', enabled: onPrev != null, onTap: onPrev),
          const SizedBox(width: 6),
          // Page number chips (max 5 visible)
          ...List.generate(totalPages.clamp(0, 5), (i) {
            final p = i + 1;
            final isActive = p == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onPage(p),
                child: Container(
                  width: 30, height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? _kBlue : _kBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isActive ? _kBlue : _kBorder),
                  ),
                  child: Text('$p',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : _kText)),
                ),
              ),
            );
          }),
          const SizedBox(width: 6),
          _PageBtn('Next', enabled: onNext != null, onTap: onNext),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String        label;
  final bool          enabled;
  final VoidCallback? onTap;
  const _PageBtn(this.label, {required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: enabled ? _kText : _kMuted)),
      ),
    );
  }
}
