import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF4F5F7);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kRed     = Color(0xFFDC2626);
const _kOrange  = Color(0xFFF59E0B);
const _kGreen   = Color(0xFF16A34A);

// ─── Page ───────────────────────────────────────────────────────────────────────
class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key});

  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  final _adminService = AdminService();
  bool          _isLoading = true;
  List<dynamic> _items     = [];
  String        _error     = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final data = await _adminService.getBlacklist();
      if (mounted) setState(() { _items = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _showAddRestrictionDialog() async {
    int poin = 10;
    String punishmentType = 'Full Blocked';
    final noteCtrl = TextEditingController();
    int? selectedUserId;

    // Fetch users for autocomplete
    List<dynamic> availableUsers = [];
    try {
      availableUsers = await _adminService.getUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e'), backgroundColor: _kRed),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Restriction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
                  const SizedBox(height: 8),
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (option) => '${option['name']} - ${option['email']}',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      return availableUsers.where((user) {
                        final name = (user['name'] ?? '').toString().toLowerCase();
                        final email = (user['email'] ?? '').toString().toLowerCase();
                        final query = textEditingValue.text.toLowerCase();
                        return name.contains(query) || email.contains(query);
                      }).cast<Map<String, dynamic>>();
                    },
                    onSelected: (Map<String, dynamic> selection) {
                      setLocal(() {
                        selectedUserId = selection['id'];
                      });
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F9FB),
                          hintText: 'Cari berdasarkan nama atau email...',
                          hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _kMuted),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          child: Container(
                            width: 380, // constrain width to match dialog content approximately
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.person_outline_rounded, color: _kBlue),
                                  title: Text(option['name'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
                                  subtitle: Text(option['email'] ?? '', style: const TextStyle(fontSize: 11, color: _kMuted)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (selectedUserId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: _kGreen),
                        const SizedBox(width: 4),
                        Text('User selected (ID: $selectedUserId)', style: const TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Punishment Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(border: Border.all(color: _kBorder), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Full Blocked (Cabut Akses Gerbang Utama)', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          value: 'Full Blocked',
                          groupValue: punishmentType,
                          onChanged: (v) => setLocal(() { punishmentType = v!; poin = 50; }),
                          activeColor: _kBlue,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        ),
                        RadioListTile<String>(
                          title: const Text('Suspended (Cabut Akses Zona Khusus)', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          value: 'Suspended',
                          groupValue: punishmentType,
                          onChanged: (v) => setLocal(() { punishmentType = v!; poin = 30; }),
                          activeColor: _kBlue,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8F9FB),
                      hintText: 'Reason for restriction',
                      hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: _kMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white, elevation: 0),
              onPressed: () async {
                if (selectedUserId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please select a user first!'), backgroundColor: _kOrange),
                  );
                  return;
                }
                if (noteCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Reason cannot be empty!'), backgroundColor: _kOrange),
                  );
                  return;
                }
                try {
                  await _adminService.addPenalty(selectedUserId!, poin, noteCtrl.text);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restriction added'), backgroundColor: _kGreen),
                  );
                  _fetch();
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: _kRed),
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

  Future<void> _removeBlacklist(dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove Blacklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
        content: Text(
          'Are you sure you want to remove the restriction for "${user['name']}"?\nAll penalty points will be cleared.',
          style: const TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _adminService.removePenalty(user['user_id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restriction removed for "${user['name']}"'),
          backgroundColor: _kGreen,
        ),
      );
      _fetch(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: _kRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Blacklist Management',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold, color: _kText)),
                    SizedBox(height: 4),
                    Text(
                      'Review and manage access restrictions for campus facilities.',
                      style: TextStyle(fontSize: 13, color: _kMuted),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddRestrictionDialog,
                  icon: const Icon(Icons.person_add_disabled_rounded, size: 18),
                  label: const Text('Add New Restriction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Summary Cards ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL BLACKLISTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 0.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                              child: const Text('+5.2%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kGreen)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${_items.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ACTIVE RESTRICTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 0.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Monthly', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _kBlue)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${_items.fold<int>(0, (sum, i) => sum + ((i['jumlah_kasus'] as num?)?.toInt() ?? 0))}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kText)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Table / Content ───────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    // Toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
                      child: Row(
                        children: [
                          // Tabs
                          const Text('All Records', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlue)),
                          const SizedBox(width: 16),
                          const Text('High Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kMuted)),
                          const SizedBox(width: 16),
                          const Text('Recently Added', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kMuted)),
                          const Spacer(),
                          // Search
                          SizedBox(
                            width: 250,
                            height: 36,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search blacklisted users...',
                                hintStyle: const TextStyle(fontSize: 12, color: _kMuted),
                                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _kMuted),
                                filled: true,
                                fillColor: _kBg,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dropdown
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(6)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: 'All Status',
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kMuted),
                                items: ['All Status'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCFDFE),
                        border: Border(bottom: BorderSide(color: _kBorder)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _Th('USER NAME')),
                          Expanded(flex: 2, child: _Th('PLATE NUMBER')),
                          Expanded(flex: 3, child: _Th('ALASAN')),
                          Expanded(flex: 2, child: _Th('STATUS')),
                          Expanded(flex: 2, child: _Th('ACTION')),
                        ],
                      ),
                    ),
                    
                    // Rows
                    Expanded(
                      child: _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: _kBlue))
                        : _items.isEmpty
                          ? const Center(child: Text('No restricted users.', style: TextStyle(color: _kMuted)))
                          : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (ctx, i) => _BlacklistRow(
                                item: _items[i],
                                onRemove: () => _removeBlacklist(_items[i]),
                              ),
                            ),
                    ),
                    
                    // Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: _kBorder)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Showing 1-${_items.length} of ${_items.length} entries', style: const TextStyle(fontSize: 12, color: _kMuted)),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _kBorder)),
                                child: const Text('Previous', style: TextStyle(fontSize: 12, color: _kMuted)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(6)),
                                child: const Text('Next', style: TextStyle(fontSize: 12, color: Colors.white)),
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

// ─── Blacklist Row ──────────────────────────────────────────────────────────────
class _BlacklistRow extends StatefulWidget {
  final dynamic item;
  final VoidCallback onRemove;
  const _BlacklistRow({required this.item, required this.onRemove});

  @override
  State<_BlacklistRow> createState() => _BlacklistRowState();
}

class _BlacklistRowState extends State<_BlacklistRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item       = widget.item;
    final name       = item['name']        ?? 'Unknown';
    final totalPoin  = (item['total_poin'] as num?)?.toInt() ?? 0;
    
    final initial1 = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final initial2 = name.length > 1  ? name[1].toLowerCase() : '';
    
    final plateNumber = item['nomor_polisi'] ?? 'Unknown';
    final alasan = item['alasan_terakhir'] ?? 'Unknown violation';
    
    final bool isHighPriority = totalPoin >= 50;
    final String statusLabel = item['status_hukuman'] ?? (totalPoin >= 50 ? 'Blocked' : 'Suspended');
    
    final bool isBlocked = statusLabel == 'Blocked';

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
            // Name & Avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2CBAB), // Skin-ish placeholder color
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.8), size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
                ],
              ),
            ),
            
            // Plate Number
            Expanded(
              flex: 2,
              child: Text(plateNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kText)),
            ),

            // Alasan
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(alasan, style: const TextStyle(fontSize: 12, color: _kMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (isHighPriority) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 12, color: _kRed),
                        const SizedBox(width: 4),
                        const Text('HIGH PRIORITY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _kRed)),
                      ],
                    ),
                  ]
                ],
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBlocked ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: isBlocked ? _kRed : _kOrange,
                    ),
                  ),
                ),
              ),
            ),

            // Action
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: widget.onRemove,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Remove Blacklist',
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
