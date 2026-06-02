import 'package:flutter/material.dart';
import '../../data/models/parking_zone.dart';

class ZoneCard extends StatelessWidget {
  final ParkingZone zone;
  const ZoneCard({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    bool isFull = zone.isFull;
    return Container(
      decoration: BoxDecoration(
        color: isFull ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFull ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              zone.nama,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCapacityIndicator(
                  "Motor",
                  zone.terpakaiMotor,
                  zone.kapasitasMotor,
                  zone.isFullMotor,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white24,
                ),
                _buildCapacityIndicator(
                  "Mobil",
                  zone.terpakaiMobil,
                  zone.kapasitasMobil,
                  zone.isFullMobil,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isFull ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isFull ? "PENUH" : "TERSEDIA",
                style: TextStyle(
                  color: isFull ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityIndicator(String label, int terpakai, int kapasitas, bool penuh) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        Text(
          "$terpakai / $kapasitas",
          style: TextStyle(
            color: penuh ? Colors.redAccent : Colors.greenAccent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
