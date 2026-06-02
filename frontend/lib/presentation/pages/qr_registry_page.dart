import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:universal_html/html.dart' as html;
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
  String _searchQuery = '';
  String _sortBy = 'Name A-Z';

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
          _zones = qrs.map<Map<String, String>>((qr) {
            final idValue = qr['id_zona'] ?? qr['id'] ?? qr['ID'] ?? '';
            return {
              'name': (qr['nama_zona'] ?? qr['NamaZona'] ?? 'Unnamed').toString(),
              'id': idValue.toString(),
              'deskripsi': (qr['deskripsi'] ?? qr['Deskripsi'] ?? '').toString(),
              'kapasitas': (qr['kapasitas'] ?? qr['Kapasitas'] ?? '0').toString(),
              'jenis_kendaraan': (qr['jenis_kendaraan'] ?? qr['JenisKendaraan'] ?? 'motor').toString(),
              'status': (qr['status'] ?? qr['Status'] ?? 'active').toString(),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Gagal memuat QR Code: ${e.toString().replaceFirst("Exception: ", "")}', style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitNewQr(String name, String deskripsi, int kapasitas, String jenisKendaraan) async {
    setState(() => _isLoading = true);
    try {
      await _adminService.generateQrCode(
        name,
        deskripsi: deskripsi,
        kapasitas: kapasitas,
        jenisKendaraan: jenisKendaraan,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Berhasil membuat QR Code baru.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Auto-reload list after successful creation (ISSUE 2 compliance)
        await _fetchQRs();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Gagal: ${e.toString().replaceFirst("Exception: ", "")}', style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showGenerateModal() {
    final nameController = TextEditingController();
    final locController = TextEditingController();
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
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
                          icon: const Icon(Icons.close, color: Colors.black54, size: 24, weight: 300),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Zone Name
                    const Text('Zone Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
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
                    const SizedBox(height: 20),

                    // Detail Lokasi / Area
                    const Text('Detail Lokasi / Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locController,
                      maxLines: 3,
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
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            // Hardcode default values since fields are removed per UI visual
                            final kap = 50; 
                            if (name.isNotEmpty) {
                              Navigator.pop(context);
                              _submitNewQr(name, locController.text.trim(), kap, 'motor');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nama zona wajib diisi!'),
                                  backgroundColor: Color(0xFFDC2626),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
            ),
          ),
        );
      },
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
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: _kMuted, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
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
                  items: ['All Zones', ..._zones.map((z) => z['name']!).toSet()],
                  onChanged: (val) => setState(() => _selectedZone = val!),
                ),
                const SizedBox(width: 12),
                _buildDropdownFilter(
                  value: _selectedStatus,
                  items: ['Status: All', 'Active', 'Inactive'],
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
                const SizedBox(width: 12),
                _buildDropdownFilter(
                  value: _sortBy,
                  items: ['Name A-Z', 'Name Z-A'],
                  onChanged: (val) => setState(() => _sortBy = val!),
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

                final filteredList = _zones.where((zone) {
                  final nameMatch = zone['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
                  final idMatch = zone['id']!.toLowerCase().contains(_searchQuery.toLowerCase());
                  final searchMatch = nameMatch || idMatch;

                  final zoneMatch = _selectedZone == 'All Zones' || zone['name'] == _selectedZone;
                  
                  final statusStr = (zone['status'] ?? 'active').toLowerCase();
                  final statusMatch = _selectedStatus == 'Status: All' || 
                      (_selectedStatus == 'Active' && statusStr == 'active') || 
                      (_selectedStatus == 'Inactive' && statusStr == 'inactive');
                      
                  return searchMatch && zoneMatch && statusMatch;
                }).toList();

                if (_sortBy == 'Name A-Z') {
                  filteredList.sort((a, b) => a['name']!.compareTo(b['name']!));
                } else if (_sortBy == 'Name Z-A') {
                  filteredList.sort((a, b) => b['name']!.compareTo(a['name']!));
                }

                if (filteredList.isEmpty) {
                  return const Center(child: Text('Tidak ada QR Code yang sesuai filter.', style: TextStyle(color: _kMuted)));
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.85, 
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return _buildQrCard(filteredList[index]);
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
    required Iterable<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final itemList = items.toList();
    // Ensure the current value exists in the list
    final safeValue = itemList.contains(value) ? value : itemList.first;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _kLightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted, size: 18),
          style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w500),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          onChanged: onChanged,
          items: itemList.map<DropdownMenuItem<String>>((String item) {
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
    final screenshotController = ScreenshotController();
    // Build QR data string — use zone id for real QR scanning integration
    final String safeZoneId = zone['id']?.trim() ?? '';
    final qrData = 'PK-ZONE-$safeZoneId';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 2),
      ),
      child: Column(
        children: [
          // Status Badge (Top Row)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(999),
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
            ],
          ),
          const Spacer(),
          // QR Image (Dynamic — uses real zone ID)
          Screenshot(
            controller: screenshotController,
            child: Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 120.0,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Zone info
          Text(zone['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kText)),
          const SizedBox(height: 4),
          Text('ID: ${zone['id']}', style: const TextStyle(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
          const Spacer(),
          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final Uint8List? image = await screenshotController.capture();
                        if (image != null) {
                          if (kIsWeb) {
                            final blob = html.Blob([image]);
                            final url = html.Url.createObjectUrlFromBlob(blob);
                            html.AnchorElement(href: url)
                              ..setAttribute("download", "QR_${zone['name']}.png")
                              ..click();
                            html.Url.revokeObjectUrl(url);
                          } else {
                            await ImageGallerySaver.saveImage(image, name: "QR_${zone['name']}");
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR Code saved to gallery')));
                          }
                        }
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kLightGray,
                      foregroundColor: _kText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
