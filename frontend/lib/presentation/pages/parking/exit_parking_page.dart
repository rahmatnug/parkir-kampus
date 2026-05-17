import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/parking_provider.dart';
import '../../widgets/global_parking_layout.dart';
import '../../widgets/parking_map_overlay.dart';

class ExitParkingPage extends StatefulWidget {
  final String zone;
  final String slotNumber;
  final double xCoord;
  final double yCoord;

  const ExitParkingPage({
    super.key,
    required this.zone,
    required this.slotNumber,
    this.xCoord = 120.0,
    this.yCoord = 120.0,
  });

  @override
  State<ExitParkingPage> createState() => _ExitParkingPageState();
}

class _ExitParkingPageState extends State<ExitParkingPage> {
  bool _isExiting = false;
  String? _duration;

  Future<void> _handleExit() async {
    setState(() {
      _isExiting = true;
    });

    final provider = context.read<ParkingProvider>();
    final result = await provider.exitParking();

    if (!mounted) return;

    setState(() {
      _isExiting = false;
    });

    if (result['success']) {
      final data = result['data'];
      // Coba hitung durasi jika ada waktu masuk dan keluar dari response API
      if (data != null && data['waktu_masuk'] != null && data['waktu_keluar'] != null) {
        try {
          final start = DateTime.parse(data['waktu_masuk']);
          final end = DateTime.parse(data['waktu_keluar']);
          final diff = end.difference(start);
          final hours = diff.inHours;
          final minutes = diff.inMinutes.remainder(60);
          _duration = '${hours}h ${minutes}m';
        } catch (e) {
          _duration = null;
        }
      }

      // Tampilkan dialog sukses dengan durasi (opsional)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Berhasil Keluar'),
          content: Text(_duration != null 
              ? 'Terima kasih telah menggunakan layanan kami.\nDurasi parkir: $_duration'
              : 'Terima kasih telah menggunakan layanan kami.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal keluar parkir'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalParkingLayout(
      title: 'Exit Parking',
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F0FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.exit_to_app,
                size: 40,
                color: Color(0xFF1E70EB),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Konfirmasi Keluar\nSilakan tekan tombol di bawah jika Anda ingin keluar dari tempat parkir',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ParkingMapOverlay(zone: widget.zone, slotNumber: widget.slotNumber, xCoord: widget.xCoord, yCoord: widget.yCoord),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keluar dari zona ${widget.zone}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Slot #${widget.slotNumber}',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const Text(
                    'Akan tersedia lagi setelah Anda keluar',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isExiting ? null : _handleExit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E70EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isExiting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Keluar Sekarang',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
}

