import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/zone_card.dart';
import '../widgets/waiting_list_card.dart';
import '../../data/models/parking_zone.dart';
import '../../data/models/waiting_list.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const _OkupansiZonaView(),
    const _AntreanAdminView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'DASHBOARD ADMIN',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8)),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
        ],
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Okupansi'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Antrean'),
        ],
      ),
    );
  }
}

class _OkupansiZonaView extends StatelessWidget {
  const _OkupansiZonaView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderBanner(title: "Status Okupansi", subtitle: "Monitoring real-time slot parkir kampus."),
          const SizedBox(height: 28),
          Expanded(
            child: StreamBuilder<List<ParkingZone>>(
              stream: getParkingUpdates(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final zones = snapshot.data ?? [];
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
                  itemCount: zones.length,
                  itemBuilder: (context, index) => ZoneCard(zone: zones[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AntreanAdminView extends StatelessWidget {
  const _AntreanAdminView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderBanner(title: "Daftar Antrean", subtitle: "Kelola urutan prioritas kendaraan masuk."),
          const SizedBox(height: 28),
          const Text("DAFTAR TUNGGU (PRIORITAS)", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: dummyWaitingList.length,
              itemBuilder: (context, index) => WaitingListCard(entry: dummyWaitingList[index], index: index),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderBanner({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF06B6D4)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
