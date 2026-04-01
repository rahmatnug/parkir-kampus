import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/status_card.dart';
import '../widgets/qr_identity_card.dart';
import '../../data/models/vehicle_status.dart';
import 'login_page.dart';
import 'riwayat_parkir_page.dart';

class MahasiswaPage extends StatelessWidget {
  const MahasiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Blacklist View (Override Entire Page)
    if (auth.isBlacklisted) {
      return _BlacklistView(reason: auth.blacklistReason);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: const Text('PARKIR KAMPUS', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18, letterSpacing: 1.5)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
          // 2. Penalty Banner (MaterialBanner)
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(auth.penaltyPoints > 0 ? 110 : 48),
            child: Column(
              children: [
                if (auth.penaltyPoints > 0)
                  MaterialBanner(
                    backgroundColor: Colors.amber.shade700,
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    content: Text(
                      "Anda memiliki ${auth.penaltyPoints} poin penalti. Patuhi aturan parkir kampus.",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {},
                        child: const Text("DETAIL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                const TabBar(
                  indicatorColor: Color(0xFF6366F1),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Color(0xFF94A3B8),
                  tabs: [Tab(text: "STATUS"), Tab(text: "RIWAYAT")],
                ),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _StatusView(),
            RiwayatParkirPage(),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const QRIdentityCard(),
          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 32),
          StreamBuilder<VehicleStatus>(
            stream: getVehicleStatusUpdates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
              if (snapshot.hasError) return Text("Error: ${snapshot.error}");
              return StatusCard(status: snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
}

class _BlacklistView extends StatelessWidget {
  final String reason;
  const _BlacklistView({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_flipped, color: Colors.redAccent, size: 100),
              const SizedBox(height: 24),
              const Text(
                "AKSES PARKIR DIBLOKIR",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                child: Text(
                  "Alasan: $reason",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text("KELUAR APLIKASI"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}
