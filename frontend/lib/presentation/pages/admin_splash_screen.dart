import 'package:flutter/material.dart';
import 'dart:async';
import 'package:frontend/main.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _statusText = 'Initializing secure admin modules...';
  int _progressPercent = 0;

  final List<String> _statusMessages = [
    'Initializing secure admin modules...',
    'Loading parking data...',
    'Connecting to server...',
    'Syncing user permissions...',
    'Ready!',
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.addListener(() {
      setState(() {
        _progressPercent = (_progressAnimation.value * 100).round();
      });
    });

    _progressController.forward();

    _messageTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_messageIndex < _statusMessages.length - 1) {
        setState(() {
          _messageIndex++;
          _statusText = _statusMessages[_messageIndex];
        });
      } else {
        timer.cancel();
      }
    });

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3FAE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Name
                  const Text(
                    'ParkirKampus',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'Campus Parking Monitoring System',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campus Building Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E3FAE), Color(0xFF3B82F6)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Try loading asset, fallback to gradient with icon
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/admin_splash.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1E3FAE),
                                        Color(0xFF3B82F6),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.apartment_rounded,
                                      color: Colors.white54,
                                      size: 80,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Loading Status Text
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF1E3FAE),
                          value: _progressAnimation.value < 1.0 ? null : 1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress Bar
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFD1D5DB),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1E3FAE),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // System Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SYSTEM STATUS: ONLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '$_progressPercent%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Footer Icons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFooterItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'SSL Encrypted',
                      ),
                      const SizedBox(width: 32),
                      _buildFooterItem(
                        icon: Icons.sync_rounded,
                        label: 'Syncing DB',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Copyright
                  const Text(
                    '© 2024 ParkirKampus',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem({required IconData icon, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
