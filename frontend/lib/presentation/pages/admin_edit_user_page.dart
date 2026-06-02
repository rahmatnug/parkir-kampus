import 'package:flutter/material.dart';
import '../../data/services/admin_service.dart';

const _kBlue   = Color(0xFF1E3FAE);
const _kBg     = Color(0xFFF4F5F7);
const _kBorder = Color(0xFFE8EAF0);
const _kText   = Color(0xFF0F172A);
const _kMuted  = Color(0xFF64748B);
const _kGreen  = Color(0xFF16A34A);
const _kRed    = Color(0xFFDC2626);

const _kRoles = ['mahasiswa', 'dosen', 'staff', 'tamu'];

class AdminEditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminEditUserPage({super.key, required this.user});

  @override
  State<AdminEditUserPage> createState() => _AdminEditUserPageState();
}

class _AdminEditUserPageState extends State<AdminEditUserPage> {
  final _adminService = AdminService();
  bool _isLoading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _nimCtrl;
  late TextEditingController _platCtrl;
  
  String _selectedRole = 'mahasiswa';
  String _selectedJenisKendaraan = 'Motor';
  bool _isBlacklisted = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user['name'] ?? '');
    _nimCtrl = TextEditingController(text: widget.user['nim'] ?? '');
    // Initial plat from the user map (may be empty if list API doesn't include it)
    _platCtrl = TextEditingController(text: widget.user['nomor_polisi'] ?? '');

    String role = (widget.user['role'] ?? 'mahasiswa').toString().toLowerCase();
    if (_kRoles.contains(role)) {
      _selectedRole = role;
    }

    String jenis = (widget.user['jenis_kendaraan'] ?? 'Motor').toString();
    if (jenis == 'Mobil' || jenis == 'Motor') {
      _selectedJenisKendaraan = jenis;
    }

    _isBlacklisted = widget.user['status'] == 'blocked' || widget.user['status'] == 'blacklisted';

    // Fetch full user details (including kendaraans) from API
    _fetchUserDetail();
  }

  Future<void> _fetchUserDetail() async {
    try {
      final userId = widget.user['id'] as int?;
      if (userId == null) return;
      final userData = await _adminService.getUserById(userId);
      if (!mounted) return;
      final kendaraans = userData['kendaraans'] as List<dynamic>?;
      if (kendaraans != null && kendaraans.isNotEmpty) {
        final k = kendaraans.first as Map<String, dynamic>;
        setState(() {
          _platCtrl.text = k['nomor_polisi']?.toString() ?? '';
          final jenis = k['jenis_kendaraan']?.toString() ?? 'motor';
          _selectedJenisKendaraan = jenis[0].toUpperCase() + jenis.substring(1).toLowerCase();
          if (_selectedJenisKendaraan != 'Motor' && _selectedJenisKendaraan != 'Mobil') {
            _selectedJenisKendaraan = 'Motor';
          }
        });
      }
    } catch (_) {
      // Silently ignore; use whatever was in widget.user
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nimCtrl.dispose();
    _platCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Nama lengkap wajib diisi', _kRed);
      return;
    }

    setState(() => _isLoading = true);

    int roleId = 3; // mahasiswa default
    switch (_selectedRole) {
      case 'dosen': roleId = 2; break;
      case 'staff': roleId = 4; break;
      case 'tamu': roleId = 5; break;
    }

    final data = {
      'nama': name,
      'nim': _nimCtrl.text.trim(),
      'id_role': roleId,
      'nomor_polisi': _platCtrl.text.trim(),
      'jenis_kendaraan': _selectedJenisKendaraan.toLowerCase(),
      'status': _isBlacklisted ? 'blocked' : 'active',
    };

    try {
      await _adminService.updateUserAdmin(widget.user['id'] as int, data);
      if (!mounted) return;
      _showSnack('Profil berhasil diperbarui', _kGreen);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), _kRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(fontSize: 14, color: readOnly ? _kMuted : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? _kBorder : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: readOnly ? _kBorder : _kBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted),
              items: items.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e[0].toUpperCase() + e.substring(1), style: const TextStyle(fontSize: 14, color: Colors.black)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _kText),
        title: const Text('Edit Profile User', style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.bold)),
        shape: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seksi 1
                const Text('Informasi Dasar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Full Name', _nameCtrl, readOnly: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Student ID / NIDN', _nimCtrl)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown('User Category', _selectedRole, _kRoles, (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seksi 2
                const Text('Identitas Kendaraan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                  child: Row(
                    children: [
                      Expanded(child: _buildTextField('License Plate Number', _platCtrl)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown('Vehicle Type', _selectedJenisKendaraan, ['Motor', 'Mobil'], (v) {
                        if (v != null) setState(() => _selectedJenisKendaraan = v);
                      })),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Seksi 3
                const Text('Status Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: _isBlacklisted ? const Color(0xFFFEF2F2) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isBlacklisted ? const Color(0xFFFECACA) : _kBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Account Access Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isBlacklisted ? _kRed : _kText)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isBlacklisted ? _kRed.withValues(alpha: 0.1) : _kGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isBlacklisted ? 'Blacklisted' : 'Active',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _isBlacklisted ? _kRed : _kGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isBlacklisted ? 'Akses parkir pengguna ini sedang diblokir.' : 'Pengguna dapat menggunakan fasilitas parkir.',
                            style: TextStyle(fontSize: 12, color: _isBlacklisted ? _kRed.withValues(alpha: 0.8) : _kMuted),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isBlacklisted,
                        activeColor: _kRed,
                        activeTrackColor: _kRed.withValues(alpha: 0.2),
                        onChanged: (val) => setState(() => _isBlacklisted = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          // Tombol Simpan Perubahan di bagian bawah
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _kBorder)),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Simpan Perubahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
