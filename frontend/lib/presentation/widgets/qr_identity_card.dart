import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';

class QRIdentityCard extends StatelessWidget {
  const QRIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Generate QR data from real user identity
    final qrData = 'PKU-${auth.nim ?? auth.email ?? 'UNKNOWN'}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "TAP-IN IDENTITAS",
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 180.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            auth.nim ?? '-',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Dekatkan QR Code ke scanner di gerbang parkir",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
