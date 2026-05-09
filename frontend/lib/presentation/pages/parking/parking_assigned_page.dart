import 'package:flutter/material.dart';
import '../../widgets/global_parking_layout.dart';
import '../../widgets/parking_map_overlay.dart';

class ParkingAssignedPage extends StatelessWidget {
  final String zone;
  final String slotNumber;
  final String vehicleType;

  const ParkingAssignedPage({
    Key? key,
    required this.zone,
    required this.slotNumber,
    this.vehicleType = 'Mobil',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlobalParkingLayout(
      title: 'Parking Assigned',
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
                Icons.check_circle,
                size: 40,
                color: Color(0xFF1E70EB),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pembayaran Berhasil!\nSilakan Parkir di zona $zone',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We've reserved the best available spot\nfor $vehicleType",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ParkingMapOverlay(zone: zone, slotNumber: slotNumber),
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
                  const Text(
                    'ASSIGNED SLOT',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E70EB),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Zone $zone',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    'Slot #$slotNumber',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate or Complete Action using ParkingBloc
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E70EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'SELESAI',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Implement Share logic
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Share Spot',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // TODO: Implement Help logic
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Help',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
