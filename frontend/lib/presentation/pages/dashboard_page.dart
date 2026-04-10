import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_dashboard_home.dart';
import 'user_management_page.dart';
import 'aktivitas_parkir_page.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const kBlue = Color(0xFF1E3FAE);
const kBg = Color(0xFFF4F5F7);
const kSidebar = Color(0xFFFFFFFF);
const kBorder = Color(0xFFE8EAF0);
const kText = Color(0xFF0F172A);
const kMuted = Color(0xFF64748B);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final _pages = const [
    AdminDashboardHome(),
    UserManagementPage(),
    AktivitasParkirPage(),
    _BlacklistPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _Sidebar({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.people_alt_outlined, label: 'Users'),
    _NavItem(icon: Icons.local_parking_rounded, label: 'Aktvitas Parkir'),
    _NavItem(icon: Icons.block_rounded, label: 'Blacklist'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      decoration: const BoxDecoration(
        color: kSidebar,
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: kBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('P',
                        style: TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ParkirKampus',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.bold, color: kText),
                          overflow: TextOverflow.ellipsis),
                      Text('ADMIN MANAGEMENT',
                          style: TextStyle(fontSize: 8, color: kMuted,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),
          const SizedBox(height: 8),
          // Nav items
          for (int i = 0; i < _items.length; i++)
            _SidebarItem(
              item: _items[i],
              selected: selectedIndex == i,
              onTap: () => onTap(i),
            ),
          const Spacer(),
          const Divider(height: 1, color: kBorder),
          // User info at bottom
          Consumer<AuthProvider>(
            builder: (_, auth, __) => Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: kBlue.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, size: 18, color: kBlue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Admin Parkir',
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w600, color: kText),
                            overflow: TextOverflow.ellipsis),
                        GestureDetector(
                          onTap: () {},
                          child: const Text('Ganti Password?',
                              style: TextStyle(fontSize: 10, color: kBlue)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.logout_rounded,
                        size: 16, color: kMuted),
                    onPressed: () => auth.logout(),
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(item.icon,
                size: 18,
                color: selected ? kBlue : kMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected ? kBlue : kMuted),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Blacklist placeholder ────────────────────────────────────────────────────
class _BlacklistPage extends StatelessWidget {
  const _BlacklistPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Blacklist',
                style: TextStyle(fontSize: 28,
                    fontWeight: FontWeight.bold, color: kText)),
            const SizedBox(height: 8),
            const Text('Kelola daftar pengguna yang diblokir.',
                style: TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block_rounded, size: 64,
                          color: Color(0xFFCBD5E1)),
                      SizedBox(height: 16),
                      Text('Tidak ada pengguna yang diblokir',
                          style: TextStyle(color: kMuted, fontSize: 15)),
                    ],
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
