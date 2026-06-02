import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../data/services/parking_repository.dart';

/// A custom painter to draw a smooth, high-precision dashed border around
/// a rectangular container, perfect for a modern upload file area.
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.dashLength = 8.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(borderRadius),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    for (final PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class PetugasReportPage extends StatefulWidget {
  const PetugasReportPage({super.key});

  @override
  State<PetugasReportPage> createState() => _PetugasReportPageState();
}

class _PetugasReportPageState extends State<PetugasReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _platNomorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedJenis;
  String? _selectedKategori;
  String? _selectedZona;
  String? _uploadedFileName;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _jenisOptions = ['Mobil', 'Motor'];
  final List<String> _kategoriOptions = [
    'Parkir Ganda',
    'Parkir Liar / Luar Slot',
    'Menghalangi Jalur Evakuasi',
    'Tanpa Stiker / QR Code',
    'Lainnya'
  ];
  List<String> _zonaOptions = [];
  bool _isLoadingZones = true;

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final repo = ParkingRepository();
      final zones = await repo.getParkingStatus();
      if (mounted) {
        setState(() {
          _zonaOptions = zones.map((z) => z.nama).toList();
          _isLoadingZones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _zonaOptions = ['Zona A', 'Zona B', 'Zona C']; // fallback
          _isLoadingZones = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _platNomorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final int sizeInBytes = await image.length();
        final double sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 5.0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file tidak boleh lebih dari 5MB'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final bytes = await image.readAsBytes();

        setState(() {
          _uploadedFileName = image.name;
          _imageBytes = bytes;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Berhasil memilih file: $_uploadedFileName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF047857), // Emerald 700
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka kamera: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _platNomorCtrl.clear();
      _descCtrl.clear();
      _selectedJenis = null;
      _selectedKategori = null;
      _selectedZona = null;
      _uploadedFileName = null;
      _imageBytes = null;
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Harap isi semua kolom wajib terlebih dahulu.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626), // Red 600
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Wajib mengunggah bukti foto pelanggaran.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEAB308), // Yellow 600
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ApiClient().dio;
      final formData = dio_pkg.FormData.fromMap({
        'plat_nomor': _platNomorCtrl.text.trim(),
        'jenis_kendaraan': _selectedJenis,
        'kategori': _selectedKategori,
        'deskripsi': _descCtrl.text.trim(),
        'zona': _selectedZona,
        'bukti_foto': dio_pkg.MultipartFile.fromBytes(
          _imageBytes!,
          filename: _uploadedFileName,
        ),
      });

      await dio.post(
        '/api/v1/report', 
        data: formData,
        options: dio_pkg.Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Laporan Berhasil Dikirim!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981), // Emerald 500
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
          backgroundColor: const Color(0xFFDC2626), // Red 600
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Premium styling helpers
    const Color bgSoftGrey = Color(0xFFF8FAFC); // extremely soft light grey background
    const Color textDark = Color(0xFF0F172A); // Slate 900
    const Color textMuted = Color(0xFF64748B); // Slate 500
    const Color navyBlue = Color(0xFF112D72); // Navy Blue for primary actions

    return Scaffold(
      backgroundColor: bgSoftGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: const Text(
          'Lapor Pelanggaran',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Keluar',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top mini-banner with officer details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: navyBlue.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person_pin_rounded,
                      size: 24,
                      color: navyBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.nama ?? 'Petugas Lapangan',
                          style: const TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          auth.email ?? 'petugas@parkir.com',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lens, color: Color(0xFF10B981), size: 8),
                        SizedBox(width: 4),
                        Text(
                          'AKTIF',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Core Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // SECTION 1: DATA KENDARAAN (Card Putih Atas)
                      _buildSectionCard(
                        title: 'Data Kendaraan',
                        icon: Icons.directions_car_rounded,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sisi Kiri: Plat Nomor
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Plat Nomor',
                                    style: TextStyle(
                                      color: textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _platNomorCtrl,
                                    textCapitalization: TextCapitalization.characters,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(12),
                                    ],
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: _buildInputDecoration(
                                      hintText: 'MISAL: B 1234 XYZ',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Plat Nomor wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Sisi Kanan: Jenis Kendaraan
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Jenis Kendaraan',
                                    style: TextStyle(
                                      color: textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedJenis,
                                    dropdownColor: Colors.white,
                                    items: _jenisOptions.map((String val) {
                                      return DropdownMenuItem<String>(
                                        value: val,
                                        child: Text(val),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedJenis = val;
                                      });
                                    },
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: _buildInputDecoration(
                                      hintText: 'Pilih Jenis',
                                    ),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Pilih jenis';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION 2: DETAIL PELANGGARAN (Card Putih Kedua)
                      _buildSectionCard(
                        title: 'Detail Pelanggaran',
                        icon: Icons.tune_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategori Pelanggaran',
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedKategori,
                              dropdownColor: Colors.white,
                              items: _kategoriOptions.map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(
                                    val,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedKategori = val;
                                });
                              },
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                hintText: 'Pilih Kategori Pelanggaran',
                              ),
                              validator: (value) {
                                if (value == null) {
                                  return 'Kategori wajib dipilih';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Deskripsi Kejadian',
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descCtrl,
                              minLines: 4,
                              maxLines: 8,
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                hintText: 'Berikan detail tambahan mengenai pelanggaran...',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Deskripsi wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION 3: LOKASI (Card Putih Ketiga)
                      _buildSectionCard(
                        title: 'Lokasi',
                        icon: Icons.location_on_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Zona / Area',
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _isLoadingZones 
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                              initialValue: _selectedZona,
                              dropdownColor: Colors.white,
                              items: _zonaOptions.map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedZona = val;
                                });
                              },
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                hintText: 'Pilih Zona Parkir',
                              ),
                              validator: (value) {
                                if (value == null) {
                                  return 'Zona wajib dipilih';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION 4: UNGGAH BUKTI FOTO (Card Putih Keempat)
                      _buildSectionCard(
                        title: 'Unggah Bukti Foto',
                        icon: Icons.camera_alt_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                painter: DashedRectPainter(
                                  color: const Color(0xFFCBD5E1), // Slate 300
                                  strokeWidth: 1.5,
                                  borderRadius: 12,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      // Circle upload container
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(0xFFF1F5F9), // Slate 100
                                        child: const Icon(
                                          Icons.upload_rounded,
                                          color: Color(0xFF64748B), // Slate 500
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Tarik & Letakkan foto di sini',
                                        style: TextStyle(
                                          color: textDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'klik untuk menelusuri file dari perangkat Anda',
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mendukung JPG, PNG (Maks 5MB)',
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_uploadedFileName != null && _imageBytes != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _imageBytes!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5), // Emerald 50
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFA7F3D0)), // Emerald 200
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.image_rounded,
                                      color: Color(0xFF059669), // Emerald 600
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _uploadedFileName!,
                                        style: const TextStyle(
                                          color: Color(0xFF065F46), // Emerald 800
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFF065F46),
                                        size: 16,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          _uploadedFileName = null;
                                          _imageBytes = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            // BOTTOM ACTIONS BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Sisi Kiri: Batal
                  TextButton(
                    onPressed: _isSubmitting ? null : _clearForm,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sisi Kanan: Kirim Laporan
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navyBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: navyBlue.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Kirim Laporan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section container utilizing modern visual aesthetics:
  /// white card background, blue rounded-corner icon, and thin elegant border lines.
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    const Color navyBlue = Color(0xFF112D72);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200 thin border
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: navyBlue.withValues(alpha: 0.1),
                  child: Icon(
                    icon,
                    size: 16,
                    color: navyBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Custom Divider line
            Container(
              height: 1,
              color: const Color(0xFFF1F5F9), // Slate 100
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  /// Reusable input decoration styled in full agreement with mockup rules.
  InputDecoration _buildInputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8), // Slate 400
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF112D72), width: 1.5), // Navy primary active border
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1), // Red error border
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
