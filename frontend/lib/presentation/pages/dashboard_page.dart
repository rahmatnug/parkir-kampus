import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_dashboard_home.dart';
import 'user_management_page.dart';
import 'aktivitas_parkir_page.dart';
import 'change_password_page.dart';
import 'blacklist_page.dart';

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
    BlacklistPage(),
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
      width: 170,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), kBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: kBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: const Center(
                      child: Text('P',
                          style: TextStyle(color: Colors.white,
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ParkirKampus',
                            style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.bold, color: kText),
                            overflow: TextOverflow.ellipsis),
                        Text('ADMIN PORTAL',
                            style: TextStyle(fontSize: 9, color: kMuted,
                                letterSpacing: 0.8, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            const SizedBox(height: 16),
            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _items.length,
                itemBuilder: (context, i) => _SidebarItem(
                  item: _items[i],
                  selected: selectedIndex == i,
                  onTap: () => onTap(i),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            // User info at bottom
            Consumer<AuthProvider>(
              builder: (_, auth, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: kBlue.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 20, color: kBlue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.nama ?? 'Admin Parkir',
                              style: const TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700, color: kText),
                              overflow: TextOverflow.ellipsis),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordPage(),
                              ),
                            ),
                            child: const Text('Ganti Password?',
                                style: TextStyle(fontSize: 10, color: kBlue, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.logout_rounded,
                          size: 18, color: kMuted),
                      onPressed: () => auth.logout(),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kBlue.withValues(alpha: 0.2) : Colors.transparent,
          )
        ),
        child: Row(
          children: [
            Icon(item.icon,
                size: 20,
                color: selected ? kBlue : kMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected ? kBlue : kMuted),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
