import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// ─── Data ──────────────────────────────────────────────────────────────────
class _ParkingZone {
  final String name;
  final String label;
  final Color color;
  final Color bgColor;
  final int available;
  final int total;

  const _ParkingZone({
    required this.name,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.available,
    required this.total,
  });
}

const _zones = [
  _ParkingZone(
    name: 'Zone A',
    label: 'A',
    color: Color(0xFF16A34A),
    bgColor: Color(0xFFDCFCE7),
    available: 24,
    total: 50,
  ),
  _ParkingZone(
    name: 'Zone B',
    label: 'B',
    color: Color(0xFFD97706),
    bgColor: Color(0xFFFEF3C7),
    available: 8,
    total: 40,
  ),
  _ParkingZone(
    name: 'Zone C',
    label: 'C',
    color: Color(0xFFDC2626),
    bgColor: Color(0xFFFFE4E6),
    available: 0,
    total: 30,
  ),
];

// ─── Main Page ────────────────────────────────────────────────────────────────
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedTab = 0;

  final _tabs = const [
    _HomeTab(),
    _ParkingTab(),
    _ScanTab(),
    _AlertsTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedTab,
        children: _tabs,
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.local_parking_rounded,
                label: 'Parking',
                selected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              // Center Scan button
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF2563EB).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selectedIndex == 2
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                label: 'Alerts',
                selected: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: selectedIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF2563EB);
    const inactive = Color(0xFF94A3B8);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: selected ? active : inactive),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? active : inactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOME TAB ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFDBEAFE),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/admin_splash.png',
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF2563EB),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const Text(
                        'Welcome, Student',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 210,
                      child: Image.asset(
                        'assets/images/maps.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF86EFAC),
                          child: const Center(
                            child: Icon(Icons.map_rounded,
                                size: 80, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Zone markers
                  Positioned(
                    top: 55,
                    left: 55,
                    child: _ZoneMarker(zone: _zones[0]),
                  ),
                  Positioned(
                    top: 85,
                    right: 90,
                    child: _ZoneMarker(zone: _zones[1]),
                  ),
                  Positioned(
                    top: 115,
                    right: 115,
                    child: _ZoneMarker(zone: _zones[2]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Parking Zones header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Parking Zones',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A)),
                  ),
                  const Spacer(),
                  const Icon(Icons.tune_rounded,
                      size: 22, color: Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Zone Cards
            for (final zone in _zones)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _ZoneCard(zone: zone),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ZoneMarker extends StatelessWidget {
  final _ParkingZone zone;
  const _ZoneMarker({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: zone.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: zone.color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          zone.label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final _ParkingZone zone;
  const _ZoneCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Zone letter badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: zone.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                zone.label,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: zone.color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(
                  zone.available == 0
                      ? 'Penuh'
                      : '${zone.available} slot tersedia',
                  style: TextStyle(
                      fontSize: 12,
                      color: zone.available == 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          // Availability indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${zone.available}/${zone.total}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: zone.color),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: zone.available / zone.total,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(zone.color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PARKING TAB (placeholder) ────────────────────────────────────────────────
class _ParkingTab extends StatelessWidget {
  const _ParkingTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_parking_rounded,
                size: 64, color: Color(0xFFDBEAFE)),
            SizedBox(height: 16),
            Text('Parking History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            SizedBox(height: 8),
            Text('Riwayat parkir Anda akan muncul di sini.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

// ─── SCAN TAB ─────────────────────────────────────────────────────────────────
class _ScanTab extends StatelessWidget {
  const _ScanTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded,
                  size: 80, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            const Text('Scan QR Code',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text('Arahkan kamera ke QR code parkir',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

// ─── ALERTS TAB (placeholder) ──────────────────────────────────────────────────
class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: Color(0xFFDBEAFE)),
            SizedBox(height: 16),
            Text('Notifikasi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            SizedBox(height: 8),
            Text('Belum ada notifikasi.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE TAB ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(Icons.person_rounded,
                  size: 52, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Student User',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text('student@univ.ac.id',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 32),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFFDC2626)),
                label: const Text('Keluar',
                    style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFE4E6)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
