import 'package:flutter/material.dart';
import '../../data/models/waiting_list.dart';

class WaitingListCard extends StatelessWidget {
  final WaitingList entry;
  final int index;
  const WaitingListCard({super.key, required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final bool isDosen = entry.role == "Dosen";
    final Color priorityColor = isDosen ? const Color(0xFF6366F1) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDosen ? priorityColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: isDosen ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.2),
          child: Text("${index + 1}", style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          entry.namaPengguna,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            _roleBadge(entry.role),
            const SizedBox(width: 8),
            Text(entry.waktuKedatangan, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("Estimasi", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            Text(
              entry.estimasiTunggu,
              style: TextStyle(color: isDosen ? const Color(0xFF6366F1) : const Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    final isDosen = role == "Dosen";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDosen ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: isDosen ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
