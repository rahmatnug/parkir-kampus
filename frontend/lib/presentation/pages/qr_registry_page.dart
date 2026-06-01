import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/services/admin_service.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF4F5F7);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kGreen   = Color(0xFF15803D); // Hijau gelap
const _kLightGray = Color(0xFFF1F5F9);

class QrRegistryPage extends StatefulWidget {
  const QrRegistryPage({super.key});

  @override
  State<QrRegistryPage> createState() => _QrRegistryPageState();
}

class _QrRegistryPageState extends State<QrRegistryPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, String>> _zones = [];
  bool _isLoading = true;

  String _selectedZone = 'All Zones';
  String _selectedStatus = 'Status: All';

  @override
  void initState() {
    super.initState();
    _fetchQRs();
  }

  Future<void> _fetchQRs() async {
    setState(() => _isLoading = true);
    try {
      final qrs = await _adminService.getQrCodes();
      if (mounted) {
        setState(() {
          _zones = qrs.map<Map<String, String>>((qr) => {
            'name': qr['nama_zona'].toString(),
            'id': qr['id_zona'].toString(),
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat QR Code: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitNewQr(String name, String location) async {
    setState(() => _isLoading = true);
    try {
      await _adminService.generateQrCode(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil membuat QR Code baru.'),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchQRs();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showGenerateModal() {
    final nameController = TextEditingController();
    final locController = TextEditingController();
    
    showDialog(
      context: context,
      barrierColor: Colors.black54, // Latar belakang diredupkan
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Dialog
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Generate New QR Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                          SizedBox(height: 6),
                          Text('Configure parameters for the new access zone.', style: TextStyle(fontSize: 13, color: _kMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54, size: 24, weight: 300), // Ikon silang (X) tipis
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Form Fields
                const Text('Zone Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Zona D',
                    hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
                    filled: true,
                    fillColor: _kLightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text('Detail Lokasi / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
                const SizedBox(height: 8),
                TextField(
                  controller: locController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g., Gedung Rektorat Lt. 1',
                    hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
                    filled: true,
                    fillColor: _kLightGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black, // Teks hitam "Batal"
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _submitNewQr(nameController.text.trim(), locController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue, // Biru tua
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Generate & Simpan', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QR Registry', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _kText)),
                    SizedBox(height: 4),
                    Text('Manage access points and payment routing codes.', style: TextStyle(fontSize: 13, color: _kMuted)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _showGenerateModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+ Generate New QR Code', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Filter Row ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _kLightGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: _kMuted, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by zone name or ID...',
                              hintStyle: TextStyle(color: _kMuted, fontSize: 13, fontWeight: FontWeight.w400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(fontSize: 13, color: _kText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildDropdownFilter(
                  value: _selectedZone,
                  items: ['All Zones', 'Zona A', 'Zona B', 'Zona C', 'Zona D'],
                  onChanged: (val) => setState(() => _selectedZone = val!),
                ),
                const SizedBox(width: 12),
                _buildDropdownFilter(
                  value: _selectedStatus,
                  items: ['Status: All', 'Active', 'Inactive'],
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Content Grid ──────────────────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator(color: _kBlue));
                }

                if (_zones.isEmpty) {
                  return const Center(child: Text('Belum ada QR Code.', style: TextStyle(color: _kMuted)));
                }

                // Grid 3 Kolom
                final isMobile = constraints.maxWidth <= 600;
                final crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 3 : 2);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.9, 
                  ),
                  itemCount: _zones.length,
                  itemBuilder: (context, index) {
                    return _buildQrCard(_zones[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _kLightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted, size: 18),
          style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w500),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(item),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQrCard(Map<String, String> zone) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 2), // Kotak kartu putih tebal
      ),
      child: Column(
        children: [
          // Status Badge (Top Left)
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kGreen, // Hijau gelap
                borderRadius: BorderRadius.circular(999), // Pil bundar
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ACTIVE', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // QR Image (Dynamic)
          Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: zone['id']!,
              version: QrVersions.auto,
              size: 120.0,
              backgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 16),
          // Zone info
          Text(zone['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)), // Teks sentral tebal
          const SizedBox(height: 4),
          Text('ID: ${zone['id']}', style: const TextStyle(fontSize: 13, color: _kMuted, fontWeight: FontWeight.w500)), // teks ID abu-abu kecil
          const Spacer(),
          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kLightGray, // Abu-abu
                      foregroundColor: _kText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                width: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: _kLightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: _kText, size: 18), // Ikon pensil edit
                    padding: EdgeInsets.zero,
                    onPressed: () {},
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
