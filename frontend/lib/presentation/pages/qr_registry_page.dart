import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/services/admin_service.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF4F5F7);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kGreen   = Color(0xFF16A34A);

class QrRegistryPage extends StatefulWidget {
  const QrRegistryPage({super.key});

  @override
  State<QrRegistryPage> createState() => _QrRegistryPageState();
}

class _QrRegistryPageState extends State<QrRegistryPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, String>> _zones = [];
  bool _isLoading = true;

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

  Future<void> _submitNewQr(String name) async {
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate New QR Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kText)),
                        SizedBox(height: 6),
                        Text('Configure parameters for the new access zone.', style: TextStyle(fontSize: 13, color: _kMuted)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _kMuted, size: 20),
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
                    fillColor: const Color(0xFFF1F5F9),
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
                    fillColor: const Color(0xFFF1F5F9),
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
                        foregroundColor: _kText,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _submitNewQr(nameController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
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
                ElevatedButton.icon(
                  onPressed: _showGenerateModal,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Generate New QR Code'),
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

            // ── Filter Row ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // very light gray
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
                _buildDropdown('All Zones'),
                const SizedBox(width: 12),
                _buildDropdown('Status: All'),
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

                final isMobile = constraints.maxWidth <= 600;
                final crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 3 : 2);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.95, // adjusted to fit content nicely
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

  Widget _buildDropdown(String text) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildQrCard(Map<String, String> zone) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Use a very subtle shadow or pure flat border based on design
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Status Badge (Top Left)
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGreen, // Solid green
                borderRadius: BorderRadius.circular(12),
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
                  const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          const Spacer(),
          // QR Image (Dynamic)
          Container(
            width: 130,
            height: 130,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: zone['id']!,
              version: QrVersions.auto,
              size: 110.0,
              backgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 16),
          // Zone info
          Text(zone['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kText)),
          const SizedBox(height: 4),
          Text('ID: ${zone['id']}', style: const TextStyle(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
          const Spacer(),
          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9), // Light Grey
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
                height: 40,
                width: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: _kText, size: 16),
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
