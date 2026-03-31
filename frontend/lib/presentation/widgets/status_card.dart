import 'package:flutter/material.dart';
import '../../data/models/vehicle_status.dart';

class StatusCard extends StatelessWidget {
  final VehicleStatus status;
  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData icon;
    String detailText = "";

    switch (status.state) {
      case VehicleState.belumParkir:
        cardColor = Colors.grey.shade400;
        icon = Icons.no_crash_rounded;
        detailText = "Anda belum memarkirkan kendaraan.";
        break;
      case VehicleState.dalamAntrean:
        cardColor = Colors.orangeAccent;
        icon = Icons.hourglass_top_rounded;
        detailText = "Mohon tunggu sejenak.";
        break;
      case VehicleState.sedangParkir:
        cardColor = Colors.greenAccent.shade400;
        icon = Icons.check_circle_rounded;
        detailText = "Kendaraan Anda terpantau aman.";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cardColor, size: 28),
              const SizedBox(width: 12),
              Text(
                status.statusText.toUpperCase(),
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailContent(status, cardColor),
          const SizedBox(height: 16),
          Text(
            detailText,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(VehicleStatus status, Color color) {
    if (status.state == VehicleState.dalamAntrean) {
      return Column(
        children: [
          const Text("POSISI ANTREAN", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            "${status.posisiAntrean}",
            style: TextStyle(
              color: color,
              fontSize: 72,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    } else if (status.state == VehicleState.sedangParkir) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _infoColumn("ZONA", status.zona ?? "-", color),
            Container(width: 1, height: 40, color: Colors.white10),
            _infoColumn("SLOT", status.slot ?? "-", color),
          ],
        ),
      );
    }
    return const Icon(Icons.directions_car_filled_rounded, size: 60, color: Colors.white10);
  }

  Widget _infoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
