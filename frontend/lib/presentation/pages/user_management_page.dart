import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';

const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF4F5F7);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kGreen   = Color(0xFF16A34A);
const _kRed     = Color(0xFFDC2626);
const _kOrange  = Color(0xFFF59E0B);

const _kRoles = ['mahasiswa', 'dosen', 'staff', 'tamu'];

// ─── Page ──────────────────────────────────────────────────────────────────────
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _searchCtrl   = TextEditingController();
  final _adminService = AdminService();
  String        _query       = '';
  bool          _isLoading   = true;
  List<dynamic> _users       = [];

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final u = await _adminService.getUsers();
      if (mounted) setState(() { _users = u; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filtered {
    return _users.where((u) {
      final n = (u['name']  ?? '').toString().toLowerCase();
      final e = (u['email'] ?? '').toString().toLowerCase();
      final q = _query.toLowerCase();
      return n.contains(q) || e.contains(q);
    }).toList();
  }

  // Pagination logic
  List<dynamic> get _paginatedFiltered {
    final filtered = _filtered;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + _itemsPerPage < filtered.length) ? startIndex + _itemsPerPage : filtered.length;
    return filtered.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    final filteredCount = _filtered.length;
    return (filteredCount / _itemsPerPage).ceil();
  }

  // ─── Delete dialog ───────────────────────────────────────────────────────
  Future<void> _confirmDelete(dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _kRed, size: 22),
            SizedBox(width: 8),
            Text('Hapus User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus\n"${user['name']}"?\n\nTindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.deleteUser(user['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User "${user['name']}" berhasil dihapus'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchUsers(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Edit Role dialog ─────────────────────────────────────────────────────
  Future<void> _showEditDialog(dynamic user) async {
    String selectedRole = (user['role'] ?? 'mahasiswa').toString().toLowerCase();
    // Sanitize if not in list
    if (!_kRoles.contains(selectedRole)) selectedRole = 'mahasiswa';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String localRole = selectedRole;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_rounded, size: 20, color: _kBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit User Role', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kText)),
                      Text(user['name'] ?? '', style: const TextStyle(fontSize: 11, color: _kMuted)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Role / Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(8),
                      color: _kBg,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.white,
                        value: localRole,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted),
                        items: _kRoles.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r[0].toUpperCase() + r.substring(1),
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        )).toList(),
                        onChanged: (v) { if (v != null) setLocal(() => localRole = v); },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: _kMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, localRole),
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result == selectedRole) return;

    try {
      await _adminService.updateUserRole(user['id'] as int, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role "${user['name']}" diubah ke ${result[0].toUpperCase()}${result.substring(1)}'),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah role: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kBlue)),
      );
    }

    final activeCount      = _users.where((u) => u['status'] == 'active').length;
    final blacklistedCount = _users.where((u) => u['status'] == 'blacklisted').length;

    return Scaffold(
      backgroundColor: _kBg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            const Text('User Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _kText)),
            const SizedBox(height: 24),

            // ── KPI Cards ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _StatCard(
                    label: 'Total Users', value: '${_users.length}',
                    valueColor: _kText)),
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
            const SizedBox(height: 20),

            // ── Search bar ───────────────────────────────────────────────────
            SizedBox(
              width: 350,
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() { _query = v; _currentPage = 1; }),
                style: const TextStyle(fontSize: 13, color: _kText),
                decoration: InputDecoration(
                  hintText: 'Search by name, student ID, or vehicle number...',
                  hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Table ────────────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    // Column headers
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCFDFE),
                        border: Border(bottom: BorderSide(color: _kBorder)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _Th('NAME')),
                          Expanded(flex: 2, child: _Th('CATEGORY')),
                          Expanded(flex: 2, child: _Th('BLACKLIST STATUS')),
                          Expanded(flex: 2, child: _Th('PARKING HISTORY')),
                          Expanded(flex: 1, child: _Th('ACTIONS')),
                        ],
                      ),
                    ),
                    // Data rows
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 48, color: _kBorder),
                                  const SizedBox(height: 12),
                                  Text(
                                    _query.isNotEmpty ? 'Tidak ada user yang cocok' : 'Belum ada user',
                                    style: const TextStyle(fontSize: 14, color: _kMuted),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _paginatedFiltered.length,
                              itemBuilder: (ctx, i) => _UserRow(
                                user: _paginatedFiltered[i],
                                onEdit:   () => _showEditDialog(_paginatedFiltered[i]),
                                onDelete: () => _confirmDelete(_paginatedFiltered[i]),
                              ),
                            ),
                    ),
                    // Footer (Pagination)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: _kBorder)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _filtered.isEmpty
                              ? 'Showing 0 of ${_users.length} users'
                              : 'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(1, _filtered.length)} of ${_users.length} users',
                            style: const TextStyle(fontSize: 12, color: _kMuted),
                          ),
                          Row(
                            children: [
                              // Previous
                              InkWell(
                                onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(border: Border.all(color: _kBorder), borderRadius: BorderRadius.circular(6)),
                                  child: Icon(Icons.chevron_left_rounded, size: 16, color: _currentPage > 1 ? _kText : _kBorder),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Page Numbers (Simplified logic to show current, next etc)
                              ...List.generate(
                                _totalPages > 5 ? 5 : _totalPages, 
                                (index) {
                                  // Very simplified numbering for UI exactly as requested
                                  int displayPage = index + 1;
                                  if (_totalPages > 5 && index == 4) {
                                    return Row(
                                      children: [
                                        const Text('...', style: TextStyle(color: _kMuted)),
                                        const SizedBox(width: 8),
                                        _PageBtn(
                                          page: _totalPages, 
                                          isActive: _currentPage == _totalPages, 
                                          onTap: () => setState(() => _currentPage = _totalPages),
                                        ),
                                      ],
                                    );
                                  } else if (_totalPages > 5 && index == 3) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: _PageBtn(
                                      page: displayPage, 
                                      isActive: _currentPage == displayPage, 
                                      onTap: () => setState(() => _currentPage = displayPage),
                                    ),
                                  );
                                }
                              ),
                              // Next
                              InkWell(
                                onTap: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(border: Border.all(color: _kBorder), borderRadius: BorderRadius.circular(6)),
                                  child: Icon(Icons.chevron_right_rounded, size: 16, color: _currentPage < _totalPages ? _kText : _kBorder),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onTap;
  
  const _PageBtn({required this.page, required this.isActive, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _kBlue : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? _kBlue : _kBorder),
        ),
        child: Text(
          '$page',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : _kText),
        ),
      ),
    );
  }
}


// ─── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String   label;
  final String   value;
  final Color    valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

// ─── Table Header Cell ──────────────────────────────────────────────────────────
class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
            color: _kMuted, letterSpacing: 0.5));
  }
}

// ─── User Row ───────────────────────────────────────────────────────────────────
class _UserRow extends StatefulWidget {
  final dynamic      user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserRow({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'mahasiswa': return const Color(0xFF2563EB); // Blue
      case 'dosen':     return const Color(0xFF9333EA); // Purple
      case 'staff':     return _kText;
      default:          return _kGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user         = widget.user;
    final name         = user['name']   ?? 'Unknown';
    final nimRaw       = user['nim']?.toString() ?? '';
    final String nim   = nimRaw.isNotEmpty ? nimRaw : 'No NIM'; 
    String role        = user['role']   ?? 'mahasiswa';
    if (role.isNotEmpty) role = role[0].toUpperCase() + role.substring(1);

    final isBlacklisted = user['status'] == 'blacklisted';

    final initial1 = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final initial2 = name.length > 1 && name.split(' ').length > 1 
        ? name.split(' ')[1][0].toUpperCase() 
        : (name.length > 1 ? name[1].toUpperCase() : '');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF8F9FB) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            // Name + Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Color(0xFFE0E7FF), shape: BoxShape.circle),
                    child: Center(
                      child: Text('$initial1$initial2', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kBlue)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
                      const SizedBox(height: 2),
                      Text(nim, style: const TextStyle(fontSize: 11, color: _kMuted)),
                    ],
                  ),
                ],
              ),
            ),

            // Category badge
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor(role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor(role))),
                ),
              ),
            ),

            // Blacklist Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBlacklisted ? const Color(0xFFFFE4E6) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: isBlacklisted ? _kRed : _kGreen, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isBlacklisted ? 'Blacklisted' : 'Active',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isBlacklisted ? _kRed : _kGreen),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Parking History
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Riwayat parkir ${user['name']} — fitur detail log sedang dikembangkan'),
                        backgroundColor: _kBlue,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 16, color: _kBlue),
                  label: const Text('View Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kBlue)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),

            // Actions
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: _kMuted),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (val) {
                    if (val == 'edit') widget.onEdit();
                    if (val == 'delete') widget.onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: _kBlue),
                          SizedBox(width: 8),
                          Text('Edit Role', style: TextStyle(fontSize: 13, color: _kText)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: _kRed),
                          SizedBox(width: 8),
                          Text('Delete User', style: TextStyle(fontSize: 13, color: _kRed)),
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
