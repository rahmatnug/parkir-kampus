import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/parking_provider.dart';
import '../../widgets/parking_grid_blueprint.dart';

class ExitParkingPage extends StatefulWidget {
  final String zone;
  final String slotNumber;
  final double xCoord;
  final double yCoord;

  const ExitParkingPage({
    super.key,
    required this.zone,
    required this.slotNumber,
    this.xCoord = 0.0,
    this.yCoord = 0.0,
  });

  @override
  State<ExitParkingPage> createState() => _ExitParkingPageState();
}

class _ExitParkingPageState extends State<ExitParkingPage> {
  bool _isExiting = false;
  bool _exitSuccess = false;
  String? _duration;

  Future<void> _handleExit() async {
    setState(() => _isExiting = true);

    final provider = context.read<ParkingProvider>();
    final result = await provider.exitParking();

    if (!mounted) return;
    setState(() => _isExiting = false);

    if (result['success']) {
      final data = result['data'];
      if (data != null && data['waktu_masuk'] != null && data['waktu_keluar'] != null) {
        try {
          final start = DateTime.parse(data['waktu_masuk']);
          final end = DateTime.parse(data['waktu_keluar']);
          final diff = end.difference(start);
          _duration = '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
        } catch (_) {}
      }
      setState(() => _exitSuccess = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Gagal keluar parkir'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Exit Parking',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _exitSuccess ? _buildSuccessView() : _buildConfirmView(),
    );
  }

  // ── Pre-exit: Confirmation view ──
  Widget _buildConfirmView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.exit_to_app_rounded, size: 40, color: Color(0xFF1E70EB)),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Konfirmasi Keluar\nSilakan tekan tombol di bawah untuk keluar dari tempat parkir',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827), height: 1.3),
            ),
          ),
          const SizedBox(height: 24),

          // Grid blueprint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ParkingGridBlueprint(
              zoneName: 'Zona ${widget.zone}',
              highlightSlot: widget.slotNumber,
            ),
          ),
          const SizedBox(height: 0),

          // Info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Keluar dari zona ${widget.zone}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                Text('Slot #${widget.slotNumber}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                const Text('Akan tersedia lagi setelah Anda keluar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isExiting ? null : _handleExit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E70EB), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0, disabledBackgroundColor: const Color(0xFF94A3B8)),
                    child: _isExiting
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Keluar Sekarang',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Post-exit: Success confirmation view ──
  Widget _buildSuccessView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Success icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF1E70EB).withValues(alpha: 0.15),
                const Color(0xFF60A5FA).withValues(alpha: 0.08),
              ]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 44, color: Color(0xFF1E70EB)),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Berhasil Konfirmasi keluar!\nSilakan Keluar dari tempat parkir',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3),
            ),
          ),
          const SizedBox(height: 24),

          // Grid showing slot now free (green)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ParkingGridBlueprint(
              zoneName: 'Zona ${widget.zone}',
              highlightSlot: widget.slotNumber,
              showSlotAsEmpty: true,
            ),
          ),

          // Session release info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Keluar dari zona ${widget.zone}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                Text('Slot #${widget.slotNumber}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Tersedia lagi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
                ]),
                if (_duration != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Text('Durasi: $_duration',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E70EB), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: const Text('Keluar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
