import 'package:flutter/material.dart';
import '../../data/models/parking_zone.dart';

class ZoneCard extends StatelessWidget {
  final ParkingZone zone;
  const ZoneCard({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    bool isFull = zone.terisiSaatIni >= zone.kapasitasMaksimal;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              zone.nama,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "${zone.terisiSaatIni} / ${zone.kapasitasMaksimal}",
              style: TextStyle(
                color: isFull ? Colors.redAccent : Colors.greenAccent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isFull ? "PENUH" : "TERSEDIA",
              style: TextStyle(
                color: isFull ? Colors.redAccent : Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
