import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'user_edit_profile_page.dart';
import 'user/profile/change_password_user_page.dart';
// ─── Data ──────────────────────────────────────────────────────────────────
import '../providers/parking_provider.dart';
import '../../data/models/parking_zone.dart';

// Helper colors
Color _getZoneColor(String name) {
  if (name.contains('A')) return const Color(0xFF16A34A);
  if (name.contains('B')) return const Color(0xFFD97706);
  if (name.contains('C')) return const Color(0xFFDC2626);
  return const Color(0xFF2563EB); // default
}

Color _getZoneBgColor(String name) {
  if (name.contains('A')) return const Color(0xFFDCFCE7);
  if (name.contains('B')) return const Color(0xFFFEF3C7);
  if (name.contains('C')) return const Color(0xFFFFE4E6);
  return const Color(0xFFDBEAFE); // default
}

String _getZoneLabel(String name) {
  final parts = name.split(' ');
  if (parts.length > 1) return parts.last[0];
  return name.isNotEmpty ? name[0] : '?';
}

// ─── Main Page ────────────────────────────────────────────────────────────────
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<ParkingProvider>();
      final token = await context.read<AuthProvider>().getToken();
      provider.fetchParkingStatus();
      if (token != null) {
        provider.initializeWebSocket(token);
      }
    });
  }

  @override
  void dispose() {
    // Dipanggil saat logout / app ditutup
    final provider = context.read<ParkingProvider>();
    provider.disconnectWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _HomeTab(),
      _ParkingTab(onBack: () => setState(() => _selectedTab = 0)),
      const _ScanTab(),
      _AlertsTab(onBack: () => setState(() => _selectedTab = 0)),
      _ProfileTab(onBack: () => setState(() => _selectedTab = 0)),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedTab,
        children: tabs,
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
    final parkingProvider = context.watch<ParkingProvider>();
    final zones = parkingProvider.zones;
    final isLoading = parkingProvider.isLoading && zones.isEmpty;

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
                      Text(
                        'Welcome, ${context.watch<AuthProvider>().nama?.split(' ').first ?? 'Student'}',
                        style: const TextStyle(
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
                  if (zones.isNotEmpty)
                    Positioned(
                      top: 55,
                      left: 55,
                      child: _ZoneMarker(zone: zones[0]),
                    ),
                  if (zones.length > 1)
                    Positioned(
                      top: 85,
                      right: 90,
                      child: _ZoneMarker(zone: zones[1]),
                    ),
                  if (zones.length > 2)
                    Positioned(
                      top: 115,
                      right: 115,
                      child: _ZoneMarker(zone: zones[2]),
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

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (zones.isEmpty)
              const Center(child: Text("Tidak ada zona yang tersedia."))
            else
              // Zone Cards
              for (final zone in zones)
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
  final ParkingZone zone;
  const _ZoneMarker({required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = _getZoneColor(zone.nama);
    final label = _getZoneLabel(zone.nama);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatefulWidget {
  final ParkingZone zone;
  const _ZoneCard({required this.zone});

  @override
  State<_ZoneCard> createState() => _ZoneCardState();
}

class _ZoneCardState extends State<_ZoneCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Color?> _colorAnimation;
  int _lastAvailable = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _colorAnimation = ColorTween(
      begin: const Color(0xFF64748B),
      end: const Color(0xFF16A34A), // Highlight color
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _ZoneCard widget) {
    super.didUpdateWidget(widget);
    final currentAvailable = widget.zone.kapasitasMaksimal - widget.zone.terisiSaatIni;
    if (_lastAvailable != -1 && currentAvailable != _lastAvailable) {
      // Trigger animation
      _animController.forward().then((_) => _animController.reverse());
    }
    _lastAvailable = currentAvailable;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final available = zone.kapasitasMaksimal - zone.terisiSaatIni;
    final total = zone.kapasitasMaksimal;
    final label = _getZoneLabel(zone.nama);
    final color = _getZoneColor(zone.nama);
    final bgColor = _getZoneBgColor(zone.nama);

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
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.nama,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, child) {
                    return Text(
                      available <= 0
                          ? 'Penuh'
                          : '$available slot tersedia',
                      style: TextStyle(
                          fontSize: 12,
                          color: available <= 0
                              ? const Color(0xFFDC2626)
                              : _colorAnimation.value),
                    );
                  }
                ),
              ],
            ),
          ),
          // Availability indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  return Text(
                    '$available/$total',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _animController.isAnimating ? _colorAnimation.value : color),
                  );
                }
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: LinearProgressIndicator(
                      value: total > 0 ? (available / total) : 0,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
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

// ─── PARKING TAB ──────────────────────────────────────────────────────────────
class _ParkingTab extends StatelessWidget {
  final VoidCallback? onBack;

  const _ParkingTab({this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Parkir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24), // Balance the arrow
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Map area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/maps.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Marker
                  Align(
                    alignment: const Alignment(-0.2, -0.7),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF60A5FA),
                          size: 54,
                        ),
                        Positioned(
                          top: 12,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF), // Bright blue
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33007AFF),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Motor Anda ada di Zona B',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '#12',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Scan QR Code ulang untuk keluar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
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

// ─── ALERTS TAB ──────────────────────────────────────────────────────────────
class _AlertsTab extends StatelessWidget {
  final VoidCallback? onBack;

  const _AlertsTab({this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Notification 1
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Baru saja',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Slot tersedia di Zone B',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/maps.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),

                // Notification 2
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706), size: 16),
                                const SizedBox(width: 4),
                                const Text(
                                  '2h ago',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Warning: cek Kunci Motor anda',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Satpam Telah menemukan kunci motor anda belum tercabut',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.warning_rounded,
                              color: Color(0xFFD97706), size: 40),
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
    );
  }
}

// ─── PROFILE TAB ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final VoidCallback? onBack;

  const _ProfileTab({this.onBack});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar with Edit Button
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDCDB3), // Skin-ish color
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserEditProfilePage(),
                              ),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0052CC),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    auth.nama ?? 'Guest',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: ${auth.nim ?? '-'}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),

                  // Informasi Kendaraan Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INFORMASI KENDARAAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'NOMOR PLAT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      auth.platNomor ?? '-',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'JENIS KENDARAAN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      auth.jenisKendaraan ?? '-',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu List
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: Color(0xFF2563EB)),
                    ),
                    title: const Text(
                      'Ganti Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF64748B)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordUserPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.help_outline_rounded,
                          color: Color(0xFF2563EB)),
                    ),
                    title: const Text(
                      'Help Center',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF64748B)),
                    onTap: () {},
                  ),
                  
                  // Keep logout button at the bottom
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<AuthProvider>().logout(),
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
          ),
        ],
      ),
    );
  }
}
