import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';
import 'aktivitas_parkir_page.dart';
import 'export_preview_page.dart';
// Colors shared
const _kBlue = Color(0xFF1E3FAE);
const _kBg = Color(0xFFF4F5F7);
const _kBorder = Color(0xFFE8EAF0);
const _kText = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);
const _kGreen = Color(0xFF16A34A);

class AdminDashboardHome extends StatefulWidget {
  const AdminDashboardHome({super.key});

  @override
  State<AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends State<AdminDashboardHome> {
  final _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      final acts  = await _adminService.getActivities();
      if (mounted) {
        setState(() {
        _stats      = stats;
        _activities = acts;
        _isLoading  = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Default 0 if err
    final cap = _stats['total_capacity'] ?? 0;
    final active = _stats['active_vehicles'] ?? 0;
    final avail = _stats['available_slots'] ?? 0;
    final userCount = _stats['registered_users'] ?? 0;

    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard',
                          style: TextStyle(fontSize: 26,
                              fontWeight: FontWeight.bold, color: _kText)),
                      SizedBox(height: 4),
                      Text('Real-time parking monitoring and statistics',
                          style: TextStyle(fontSize: 13, color: _kMuted)),
                    ],
                  ),
                ),
                _OutlineBtn(
                  icon: Icons.calendar_today_outlined,
                  label: 'Last 24 Hours',
                  onTap: () {
                    // Filter waktu — tampilkan snackbar info (data real sudah dari API)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menampilkan data 24 jam terakhir'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ExportPreviewPage(activities: _activities),
                    ));
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export Data',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // KPI Cards
            Row(
              children: [
                Expanded(child: _KpiCard(
                  icon: Icons.local_parking_rounded,
                  iconColor: _kBlue,
                  label: 'Total Capacity',
                  value: '$cap',
                  badge: '0%',
                  badgeColor: _kMuted,
                )),
                const SizedBox(width: 16),
                Expanded(child: _KpiCard(
                  icon: Icons.directions_car_rounded,
                  iconColor: _kBlue,
                  label: 'Vehicles Parked',
                  value: '$active',
                  badge: '$userCount Reg Users', // reused badge slot
                  badgeColor: _kGreen,
                )),
                const SizedBox(width: 16),
                Expanded(child: _KpiCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: _kGreen,
                  label: 'Available Slots',
                  value: '$avail',
                  badge: 'Real-time',
                  badgeColor: _kMuted,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _ChartCard(
                    title: 'Occupancy per Zone',
                    badge: '+2.4% vs last day',
                    badgeColor: _kGreen,
                    child: _BarChartWidget(activities: _activities),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _ChartCard(
                    title: 'Activity Timeline (Today)',
                    badge: 'Real-time',
                    badgeColor: _kBlue,
                    child: _LineChartWidget(activities: _activities),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            _RecentActivityTable(),
          ],
        ),
      ),
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;
  const _KpiCard({
    required this.icon, required this.iconColor, required this.label,
    required this.value, required this.badge, required this.badgeColor,
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
              Text(badge,
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: badgeColor)),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 28,
              fontWeight: FontWeight.bold, color: _kText)),
        ],
      ),
    );
  }
}

// ─── Chart Card Wrapper ───────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final Widget child;
  const _ChartCard({
    required this.title, required this.badge,
    required this.badgeColor, required this.child,
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
              Text(title, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: _kText)),
              const Spacer(),
              Text(badge, style: TextStyle(fontSize: 11,
                  color: badgeColor, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─── Simple Bar Chart ─────────────────────────────────────────────────────────
class _BarChartWidget extends StatelessWidget {
  final List<dynamic> activities;
  const _BarChartWidget({this.activities = const []});

  @override
  Widget build(BuildContext context) {
    // Build zone data dynamically from real activities
    final Map<String, double> motorMap = {};
    final Map<String, double> mobilMap = {};
    for (final a in activities) {
      final zona = (a['zona'] ?? 'Lainnya') as String;
      final role = (a['role'] ?? '') as String;
      if (role == 'mahasiswa') {
        motorMap[zona] = (motorMap[zona] ?? 0) + 1;
      } else {
        mobilMap[zona] = (mobilMap[zona] ?? 0) + 1;
      }
    }
    final allZones = {...motorMap.keys, ...mobilMap.keys}.toList()..sort();
    // Fallback if no data yet
    final zones = allZones.isEmpty
        ? [_ZoneData('ZONA A', 0, 0), _ZoneData('ZONA B', 0, 0), _ZoneData('ZONA C', 0, 0)]
        : allZones.map((z) => _ZoneData(z, motorMap[z] ?? 0, mobilMap[z] ?? 0)).toList();
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          // Legend
          Row(
            children: [
              _Legend(color: _kBlue, label: 'Motor'),
              const SizedBox(width: 12),
              _Legend(color: const Color(0xFFBBC4F5), label: 'Mobil'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final z in zones)
                  _BarGroup(zone: z),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Y-axis labels at bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final z in zones)
                Text(z.name,
                    style: const TextStyle(fontSize: 9, color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneData {
  final String name;
  final double motor;
  final double mobil;
  const _ZoneData(this.name, this.motor, this.mobil);
}

class _BarGroup extends StatelessWidget {
  final _ZoneData zone;
  const _BarGroup({required this.zone});

  @override
  Widget build(BuildContext context) {
    final max = 50.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 18,
          height: (zone.motor / max) * 120,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 18,
          height: (zone.mobil / max) * 120,
          decoration: BoxDecoration(
            color: const Color(0xFFBBC4F5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: _kMuted)),
      ],
    );
  }
}

// ─── Simple Line Chart ────────────────────────────────────────────────────────
class _LineChartWidget extends StatelessWidget {
  final List<dynamic> activities;
  const _LineChartWidget({this.activities = const []});

  @override
  Widget build(BuildContext context) {
    // Group by hour
    final now = DateTime.now();
    final counts = List.filled(24, 0);
    int maxCount = 1;
    
    for (final a in activities) {
      if (a['waktu_masuk'] != null) {
        final t = DateTime.parse(a['waktu_masuk']).toLocal();
        // Only today
        if (t.year == now.year && t.month == now.month && t.day == now.day) {
          counts[t.hour]++;
          if (counts[t.hour] > maxCount) maxCount = counts[t.hour];
        }
      }
    }

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(child: CustomPaint(painter: _LinePainter(counts, maxCount))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00']
                .map((t) => Text(t,
                style: const TextStyle(fontSize: 9, color: _kMuted)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<int> counts;
  final int maxCount;
  
  _LinePainter(this.counts, this.maxCount);

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (int i = 0; i < 24; i++) {
      double x = (i / 23) * size.width;
      double y = size.height - ((counts[i] / maxCount) * size.height * 0.85); // max 85% height
      points.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()..moveTo(0, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3FAE).withValues(alpha: 0.25),
            const Color(0xFF1E3FAE).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF1E3FAE)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);
    
    // Draw dots
    final dotPaint = Paint()..color = const Color(0xFF1E3FAE)..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (int i = 0; i < 24; i++) {
      if (counts[i] > 0) {
        canvas.drawCircle(points[i], 4, dotPaint);
        canvas.drawCircle(points[i], 2, whitePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => true;
}

// ─── Recent Activity Table ────────────────────────────────────────────────────
class _RecentActivityTable extends StatefulWidget {
  const _RecentActivityTable();

  @override
  State<_RecentActivityTable> createState() => _RecentActivityTableState();
}

class _RecentActivityTableState extends State<_RecentActivityTable> {
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
      // Only keep top 5 for dashboard
      if (mounted) setState(() { _activities = act.take(5).toList(); _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('Aktivitas Terbaru',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600, color: _kText)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AktivitasParkirPage(),
                    ));
                  },
                  child: const Text('View All',
                      style: TextStyle(fontSize: 13, color: _kBlue)),
                ),
              ],
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            color: const Color(0xFFF8F9FB),
            child: const Row(
              children: [
                Expanded(flex: 3,
                    child: _TableHeader('KENDARAAN DAN PLAT NOMOR')),
                Expanded(flex: 2, child: _TableHeader('USER TYPE')),
                Expanded(flex: 2, child: _TableHeader('ZONA')),
                Expanded(flex: 2, child: _TableHeader('WAKTU')),
                Expanded(flex: 2, child: _TableHeader('STATUS')),
              ],
            ),
          ),
          // Rows
          if (_activities.isEmpty)
             const Padding(padding: EdgeInsets.all(20), child: Text('Belum ada aktivitas parkir')),
          for (final row in _activities)
            _ActivityRowWidget(row: row),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: _kMuted, letterSpacing: 0.5));
  }
}

class _ActivityRowWidget extends StatelessWidget {
  final dynamic row;
  const _ActivityRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    bool isParked = row['status'] == 'parkir';
    String timeStr = "";
    if (row['waktu_masuk'] != null) {
      final dt = DateTime.parse(row['waktu_masuk']).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      timeStr = '$h:$m';
    }
    String plateStr = row['nomor_polisi'] ?? '-';
    String userTypeStr = row['role'] ?? '-';
    // Capitalize role
    if (userTypeStr.isNotEmpty) userTypeStr = userTypeStr[0].toUpperCase() + userTypeStr.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  userTypeStr == 'Mahasiswa'
                      ? Icons.motorcycle_rounded
                      : Icons.directions_car_rounded,
                  size: 18,
                  color: _kMuted,
                ),
                const SizedBox(width: 8),
                Text(plateStr,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
              ],
            ),
          ),
          Expanded(flex: 2,
              child: Text(userTypeStr,
                  style: const TextStyle(fontSize: 13, color: _kText))),
          Expanded(flex: 2,
              child: Text(row['zona'] ?? '-',
                  style: const TextStyle(fontSize: 13, color: _kText))),
          Expanded(flex: 2,
              child: Text(timeStr,
                  style: const TextStyle(fontSize: 13, color: _kText))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isParked
                      ? _kGreen.withValues(alpha: 0.1)
                      : _kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isParked ? 'PARKED' : 'EXITED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isParked ? _kGreen : _kBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Outline Button helper ────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kMuted,
        side: const BorderSide(color: _kBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
