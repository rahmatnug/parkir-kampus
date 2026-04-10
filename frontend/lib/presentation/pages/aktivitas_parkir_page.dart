import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';

const _kBlue = Color(0xFF1E3FAE);
const _kBg = Color(0xFFF4F5F7);
const _kBorder = Color(0xFFE8EAF0);
const _kText = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);
const _kGreen = Color(0xFF16A34A);
const _kRed = Color(0xFFDC2626);

// Removed dummy logs

class AktivitasParkirPage extends StatefulWidget {
  const AktivitasParkirPage({super.key});

  @override
  State<AktivitasParkirPage> createState() => _AktivitasParkirPageState();
}

class _AktivitasParkirPageState extends State<AktivitasParkirPage> {
  final _adminService = AdminService();
  bool _isLoading = true;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final act = await _adminService.getActivities();
      if (mounted) setState(() { _activities = act; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: _kBg, body: Center(child: CircularProgressIndicator()));
    
    int parkedCount = _activities.where((a) => a['status'] == 'parkir').length;
    
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('Aktivitas Parkir',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _kText)),
            const SizedBox(height: 24),

            // Stat Cards
            Row(
              children: [
                Expanded(
                  child: _OccupancyCard(
                    title: 'Total Occupancy',
                    percent: 85,
                    trend: '~2%',
                    trendUp: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SimpleStatCard(
                    title: 'Parkir Terisi',
                    value: '$parkedCount',
                    unit: 'Kendaraan',
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: _TrendStatCard(
                    title: 'Slot Tersedia',
                    value: '-', // Needs global capacity to compute
                    trend: '',
                    trendUp: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TrendStatCard(
                    title: 'Aktivitas Total',
                    value: '${_activities.length}',
                    trend: '',
                    trendUp: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Log Table Section
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
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text('Real-time Activity Log',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _kText)),
                        const Spacer(),
                        // View Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Row(
                            children: const [
                              Text('All Status',
                                  style: TextStyle(
                                      fontSize: 13, color: _kText)),
                              SizedBox(width: 8),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: _kMuted),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Search
                        SizedBox(
                          width: 200,
                          height: 36,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Cari',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: _kMuted),
                              suffixIcon: const Icon(Icons.search_rounded,
                                  size: 16, color: _kMuted),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              filled: true,
                              fillColor: _kBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: _kBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    const BorderSide(color: _kBorder),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Export
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Row(
                            children: const [
                              Text('Export',
                                  style: TextStyle(
                                      fontSize: 13, color: _kText)),
                              SizedBox(width: 8),
                              Icon(Icons.download_rounded,
                                  size: 16, color: _kMuted),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCFDFE),
                      border: Border(
                        top: BorderSide(color: _kBorder),
                        bottom: BorderSide(color: _kBorder),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: _Th('USER')),
                        Expanded(flex: 2, child: _Th('VEHICLE PLATE')),
                        Expanded(flex: 3, child: _Th('ZONE')),
                        Expanded(flex: 2, child: _Th('ENTRY TIME')),
                        Expanded(flex: 2, child: _Th('EXIT TIME')),
                        Expanded(flex: 2, child: _Th('STATUS')),
                        Expanded(flex: 1, child: _Th('ACTION')),
                      ],
                    ),
                  ),

                  // Table Rows
                  if (_activities.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Text("Belum ada aktivitas parkir")),
                  ..._activities.map((log) => _LogEntryRow(log: log)),

                  // Pagination Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Text('Showing ${_activities.length} entries',
                            style: const TextStyle(
                                fontSize: 13, color: _kMuted)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Previous',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _kText)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Next',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _kText)),
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
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  final String title;
  final int percent;
  final String trend;
  final bool trendUp;

  const _OccupancyCard(
      {required this.title,
      required this.percent,
      required this.trend,
      required this.trendUp});

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
          Text(title, style: const TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$percent%',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _kText)),
              const Spacer(),
              Row(
                children: [
                  Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: trendUp ? _kGreen : _kRed),
                  const SizedBox(width: 4),
                  Text(trend,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: trendUp ? _kGreen : _kRed)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: _kBg,
              valueColor: const AlwaysStoppedAnimation<Color>(_kBlue),
            ),
          )
        ],
      ),
    );
  }
}

class _SimpleStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;

  const _SimpleStatCard(
      {required this.title, required this.value, required this.unit});

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
          Text(title, style: const TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _kText)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit,
                    style:
                        const TextStyle(fontSize: 13, color: _kMuted)),
              ),
            ],
          ),
          const SizedBox(height: 20), // Balance height
        ],
      ),
    );
  }
}

class _TrendStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendUp;

  const _TrendStatCard(
      {required this.title,
      required this.value,
      required this.trend,
      required this.trendUp});

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
          Text(title, style: const TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _kText)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color: trendUp ? _kGreen : _kRed),
                    const SizedBox(width: 4),
                    Text(trend,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: trendUp ? _kGreen : _kRed)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
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
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _kMuted,
            letterSpacing: 0.5));
  }
}

class _LogEntryRow extends StatelessWidget {
  final dynamic log;

  const _LogEntryRow({required this.log});

  Color _statusColor(String st) {
    if (st == 'parkir') return _kGreen;
    if (st == 'selesai') return _kMuted;
    return _kText;
  }

  Color _statusBgColor(String st) {
    if (st == 'parkir') return _kGreen.withValues(alpha: 0.1);
    if (st == 'selesai') return _kMuted.withValues(alpha: 0.1);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    String st = log['status'] ?? '';
    
    final name = log['user_name'] ?? 'Unknown';
    String initial1 = name.length > 0 ? name[0].toUpperCase() : '?';
    String initial2 = name.length > 1 ? name[1].toUpperCase() : '';

    String entryTimeStr = "";
    if (log['waktu_masuk'] != null) {
      final dt = DateTime.parse(log['waktu_masuk']).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      entryTimeStr = '${dt.day}/${dt.month}/${dt.year} $h:$m';
    }
    
    String exitTimeStr = "-";
    if (log['waktu_keluar'] != null) {
      final dt = DateTime.parse(log['waktu_keluar']).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      exitTimeStr = '${dt.day}/${dt.month}/${dt.year} $h:$m';
    }

    // Plate processing (naive split)
    String rawPlate = log['nomor_polisi'] ?? 'XX 1234 YY';
    var split = rawPlate.split(' ');
    String p1 = split.length > 0 ? split[0] : '';
    String p2 = split.length > 1 ? split[1] : '';
    String p3 = split.length > 2 ? split.sublist(2).join(' ') : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
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
                  child: Text('$initial1$initial2',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _kBlue)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kText)),
                      Text(log['role'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: _kMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Plate
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(p1,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
                const SizedBox(width: 4),
                Text(p2,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
                const SizedBox(width: 4),
                Text(p3,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
              ],
            ),
          ),
          // Zone
          Expanded(
            flex: 3,
            child: Text(log['zona'] ?? '-',
                style: const TextStyle(fontSize: 13, color: _kText)),
          ),
          // Entry Time
          Expanded(
            flex: 2,
            child: Text(entryTimeStr,
                style: const TextStyle(fontSize: 13, color: _kText)),
          ),
          // Exit Time
          Expanded(
            flex: 2,
            child: Text(exitTimeStr,
                style: const TextStyle(fontSize: 13, color: _kText)),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor(st),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(st.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(st))),
              ),
            ),
          ),
          // Action
          const Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.more_horiz_rounded, size: 20, color: _kMuted),
            ),
          ),
        ],
      ),
    );
  }
}
