import 'package:flutter/material.dart';
import '../pages/parking/qr_scan_page.dart';

class GlobalParkingLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;

  const GlobalParkingLayout({
    super.key,
    required this.title,
    required this.body,
    this.currentIndex = 1, // Default to Parking tab
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827), // Near black
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRScanPage()),
            );
          },
          backgroundColor: Colors.white,
          elevation: 0,
          child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, "Home", 0),
              _buildNavItem(context, Icons.local_parking, "Parking", 1),
              const SizedBox(width: 48), // Space for centered FAB
              _buildNavItem(context, Icons.notifications_none, "Alerts", 2),
              _buildNavItem(context, Icons.person_outline, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF1E70EB) : const Color(0xFF6B7280);
    return InkWell(
      onTap: () {
        // Return to main home (user_home_page) where real tab navigation lives
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'Montserrat',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
