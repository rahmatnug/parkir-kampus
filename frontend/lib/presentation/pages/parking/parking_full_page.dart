import 'package:flutter/material.dart';
import '../../widgets/global_parking_layout.dart';

class ParkingFullPage extends StatelessWidget {
  final List<String> availableZones;
  final String vehicleType;

  const ParkingFullPage({
    Key? key,
    required this.availableZones,
    required this.vehicleType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final zonesText = availableZones.join(' DAN ');

    return GlobalParkingLayout(
      title: 'Parking Assigned',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty,
                size: 40,
                color: Color(0xFF1E70EB),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TEMPAT PENUH',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SILAKAN CARI TEMPAT PARKIR DI ZONA\nLAIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'SLOT KOSONG UNTUK ${vehicleType.toUpperCase()}\nTERSEDIA DI ZONA $zonesText',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E70EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notifications_none, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Stay Notified?',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black, size: 20),
                        onPressed: () {
                          // TODO: Dismiss card logic
                        },
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.check, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            // TODO: Opt-in notifications logic
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jika seluruh zona penuh kamu bisa aktifkan notif agar kami bisa memberitahu notifikasi saat ada slot kosong di zona',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Empty placeholder box for aesthetic balance as seen in the mockup
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
