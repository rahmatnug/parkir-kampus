import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';

const _kBlue = Color(0xFF1E3FAE);
const _kBg = Color(0xFFF4F5F7);
const _kBorder = Color(0xFFE8EAF0);
const _kText = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);
const _kGreen = Color(0xFF16A34A);
const _kRed = Color(0xFFDC2626);

// Removed dummy users

// ─── Page ─────────────────────────────────────────────────────────────────
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _searchCtrl = TextEditingController();
  final _adminService = AdminService();
  String _query = '';
  int _currentPage = 1;
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final u = await _adminService.getUsers();
      if (mounted) setState(() { _users = u; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get _filtered {
    return _users.where((u) {
      final n = (u['name'] ?? '').toString().toLowerCase();
      final e = (u['email'] ?? '').toString().toLowerCase();
      final q = _query.toLowerCase();
      return n.contains(q) || e.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: _kBg, body: Center(child: CircularProgressIndicator()));
    
    int activeCount = _users.where((u) => u['status'] == 'active').length;
    int blacklistedCount = _users.where((u) => u['status'] == 'blacklisted').length;

    return Scaffold(
      backgroundColor: _kBg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('User Management',
                style: TextStyle(fontSize: 26,
                    fontWeight: FontWeight.bold, color: _kText)),
            const SizedBox(height: 24),

            // KPI Cards
            Row(
              children: [
                Expanded(child: _StatCard(
                    label: 'Total Users', value: '${_users.length}', valueColor: _kText)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(
                    label: 'Active Today', value: '$activeCount',
                    valueColor: _kText)),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(
                    label: 'Blacklisted', value: '$blacklistedCount',
                    valueColor: _kRed)),
              ],
            ),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 13, color: _kText),
              decoration: InputDecoration(
                hintText: 'Search by name, student ID, or vehicle number...',
                hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: _kMuted),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBlue),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: _kBorder)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 48),
                          Expanded(flex: 4,
                              child: _Th('NAME')),
                          Expanded(flex: 2,
                              child: _Th('CATEGORY')),
                          Expanded(flex: 2,
                              child: _Th('BLACKLIST STATUS')),
                          Expanded(flex: 2,
                              child: _Th('PARKING HISTORY')),
                          Expanded(flex: 1,
                              child: _Th('ACTIONS')),
                        ],
                      ),
                    ),
                    // Rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) =>
                            _UserRow(user: _filtered[i]),
                      ),
                    ),
                    // Footer pagination
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: _kBorder)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Showing ${_filtered.length} users',
                            style: const TextStyle(
                                fontSize: 12, color: _kMuted),
                          ),
                          const Spacer(),
                          _PaginationBtn(
                              icon: Icons.chevron_left_rounded,
                              onTap: () {}),
                          const SizedBox(width: 4),
                          for (int p = 1; p <= 3; p++)
                            _PageNumBtn(
                              page: p,
                              selected: _currentPage == p,
                              onTap: () =>
                                  setState(() => _currentPage = p),
                            ),
                          const Text('...',
                              style: TextStyle(
                                  color: _kMuted, fontSize: 13)),
                          const SizedBox(width: 4),
                          _PageNumBtn(
                              page: 248,
                              selected: _currentPage == 248,
                              onTap: () =>
                                  setState(() => _currentPage = 248)),
                          const SizedBox(width: 4),
                          _PaginationBtn(
                              icon: Icons.chevron_right_rounded,
                              onTap: () {}),
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
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatCard({required this.label, required this.value,
    required this.valueColor});

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
          Text(label,
              style: const TextStyle(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 28,
                  fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

// ─── Table Header Cell ────────────────────────────────────────────────────────
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

// ─── User Row ─────────────────────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final dynamic user;
  const _UserRow({required this.user});

  Color _catColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'mahasiswa': return const Color(0xFF7C3AED);
      case 'dosen': return const Color(0xFF2563EB);
      default: return _kGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? '-';
    // Capitalize role
    String category = user['role'] ?? 'User';
    if (category.isNotEmpty) category = category[0].toUpperCase() + category.substring(1);
    
    final isBlacklisted = user['status'] == 'blacklisted';

    String initial1 = name.length > 0 ? name[0].toUpperCase() : '?';
    String initial2 = name.length > 1 ? name[1].toUpperCase() : '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38, height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFDDEAFF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$initial1$initial2',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3FAE)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + ID
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: _kText)),
                Text(email,
                    style: const TextStyle(
                        fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          // Category badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _catColor(category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(category,
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _catColor(category))),
              ),
            ),
          ),
          // Blacklist status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: isBlacklisted ? _kRed : _kGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                    isBlacklisted ? 'Blacklisted' : 'Active',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isBlacklisted ? _kRed : _kGreen)),
              ],
            ),
          ),
          // Parking history
          Expanded(
            flex: 2,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.history_rounded,
                  size: 14, color: _kBlue),
              label: const Text('View Logs',
                  style: TextStyle(
                      fontSize: 12, color: _kBlue)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded,
                  size: 18, color: _kMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pagination ───────────────────────────────────────────────────────────────
class _PaginationBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PaginationBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: _kMuted),
      ),
    );
  }
}

class _PageNumBtn extends StatelessWidget {
  final int page;
  final bool selected;
  final VoidCallback onTap;
  const _PageNumBtn(
      {required this.page, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? _kBlue : Colors.transparent,
          border: Border.all(
              color: selected ? _kBlue : _kBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text('$page',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kMuted)),
        ),
      ),
    );
  }
}
