import 'package:flutter/material.dart';
import 'dart:async';
import 'package:frontend/main.dart';

class UserSplashScreen extends StatefulWidget {
  const UserSplashScreen({super.key});

  @override
  State<UserSplashScreen> createState() => _UserSplashScreenState();
}

class _UserSplashScreenState extends State<UserSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  int _percent = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() => _percent = (_progress.value * 100).round());
      });
    _ctrl.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Logo Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('P',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // App Name
              const Text(
                'ParkirKampus',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Smart Campus Parking Solutions',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),

              // Building Image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: Image.asset(
                    'assets/images/admin_splash.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFDBEAFE),
                      child: const Center(
                        child: Icon(Icons.apartment_rounded,
                            size: 80, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Loading row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loading',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A))),
                  Text('$_percent%',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB))),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar
              AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress.value,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
