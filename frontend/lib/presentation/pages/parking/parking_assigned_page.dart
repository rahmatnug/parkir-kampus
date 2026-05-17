import 'package:flutter/material.dart';
import '../../widgets/parking_grid_blueprint.dart';

/// Dual-state page: renders Success OR Zone-Full based on [isFull].
class ParkingAssignedPage extends StatelessWidget {
  final String zone;
  final String slotNumber;
  final String vehicleType;
  final double xCoord;
  final double yCoord;
  final bool isFull;
  final List<String> availableZones;

  const ParkingAssignedPage({
    super.key,
    required this.zone,
    required this.slotNumber,
    this.xCoord = 0.0,
    this.yCoord = 0.0,
    this.vehicleType = 'Motor',
    this.isFull = false,
    this.availableZones = const [],
  });

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
        title: const Text('Parking Assigned',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: isFull
          ? _FullStateBody(
              zone: zone,
              vehicleType: vehicleType,
              availableZones: availableZones,
            )
          : _SuccessStateBody(
              zone: zone,
              slotNumber: slotNumber,
              vehicleType: vehicleType,
            ),
    );
  }
}

// ─── SUCCESS STATE ────────────────────────────────────────────────────────────
class _SuccessStateBody extends StatelessWidget {
  final String zone;
  final String slotNumber;
  final String vehicleType;
  const _SuccessStateBody({required this.zone, required this.slotNumber, required this.vehicleType});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          // ── Success Icon ──
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
          // ── Title ──
          Text('Penempatan Berhasil!\nSilakan Parkir di zona $zone',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.3)),
          const SizedBox(height: 6),
          const Text("We've reserved the best available spot",
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 24),

          // ── Parking Grid Blueprint ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ParkingGridBlueprint(
                zoneName: 'Zona $zone',
                highlightSlot: slotNumber,
              ),
            ),
          ),

          // ── Slot Info Card ──
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
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ASSIGNED SLOT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E70EB), letterSpacing: 1.2)),
                ),
                const SizedBox(height: 12),
                Text('Zone $zone',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text('Slot #$slotNumber',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(vehicleType.toLowerCase() == 'mobil' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                    color: const Color(0xFF64748B), size: 18),
                  const SizedBox(width: 6),
                  Text(vehicleType, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ]),
                const SizedBox(height: 24),
                // Main CTA
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E70EB), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: const Text('SELESAI',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 16),
                // Secondary buttons
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Slot $zone-$slotNumber telah disalin!'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Spot', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF0F172A)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hubungi admin jika membutuhkan bantuan parkir'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('Help', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF0F172A)),
                  )),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── FULL STATE ───────────────────────────────────────────────────────────────
class _FullStateBody extends StatefulWidget {
  final String zone;
  final String vehicleType;
  final List<String> availableZones;
  const _FullStateBody({required this.zone, required this.vehicleType, required this.availableZones});

  @override
  State<_FullStateBody> createState() => _FullStateBodyState();
}

class _FullStateBodyState extends State<_FullStateBody> {
  bool _notifyDismissed = false;

  @override
  Widget build(BuildContext context) {
    final zonesText = widget.availableZones.isNotEmpty
        ? widget.availableZones.join(' DAN ')
        : 'B DAN C';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ── Hourglass Icon ──
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_empty, size: 40, color: Color(0xFF1E70EB)),
          ),
          const SizedBox(height: 24),
          const Text('TEMPAT PENUH',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('SILAKAN CARI TEMPAT PARKIR DI ZONA LAIN',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
          const SizedBox(height: 32),

          // ── Recommendation Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'SLOT KOSONG UNTUK ${widget.vehicleType.toUpperCase()}\nTERSEDIA DI ZONA $zonesText',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // ── Stay Notified Box ──
          if (!_notifyDismissed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E70EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.notifications_none, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Stay Notified?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => setState(() => _notifyDismissed = true),
                  ),
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifikasi diaktifkan! Kami akan menginfokan saat slot tersedia.'),
                            backgroundColor: Color(0xFF16A34A)));
                        setState(() => _notifyDismissed = true);
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                const Text(
                  'Jika seluruh zona penuh kamu bisa aktifkan notif agar kami bisa memberitahu notifikasi saat ada slot kosong di zona',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white, height: 1.5),
                ),
              ]),
            ),
          const SizedBox(height: 24),

          // ── Back Button ──
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: const Color(0xFF0F172A)),
              child: const Text('Kembali ke Dashboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
