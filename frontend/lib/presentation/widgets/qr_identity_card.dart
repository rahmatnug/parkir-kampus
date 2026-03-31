import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRIdentityCard extends StatelessWidget {
  const QRIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            data: "MHS-DUMMY-001", // ID User yang akan di-scan
            version: QrVersions.auto,
            size: 180.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
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
