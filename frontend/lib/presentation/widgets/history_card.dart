import 'package:flutter/material.dart';
import '../../data/models/parking_history.dart';

class HistoryCard extends StatelessWidget {
  final ParkingHistory history;
  const HistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final isPenalty = history.status == HistoryStatus.penalti;
    final statusColor = isPenalty ? Colors.redAccent : Colors.greenAccent;
    final statusIcon = isPenalty ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.tanggal,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${history.zona} • ${history.slot}",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      history.status == HistoryStatus.selesai ? "SELESAI" : "PENALTI",
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _timeInfo("Masuk", history.waktuMasuk),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white10, size: 16),
              _timeInfo("Keluar", history.waktuKeluar),
              const SizedBox(width: 40), // Spacer
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeInfo(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
