import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/mahasiswa_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ParkirkampusApp(),
    ),
  );
}

class ParkirkampusApp extends StatelessWidget {
  const ParkirkampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PARKIR KAMPUS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const _AuthGate(),
    );
  }
}

/// Splash / auth gate widget that checks stored token on first run.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // Check stored token after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    if (status == AuthStatus.initial || status == AuthStatus.loading) {
      // Splash screen while checking token
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_parking_rounded,
                  color: Color(0xFF6366F1), size: 64),
              SizedBox(height: 16),
              CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      );
    }

    if (status == AuthStatus.authenticated) {
      final idRole = context.watch<AuthProvider>().idRole;
      if (idRole == 1) {
        return const DashboardPage();
      } else {
        return const MahasiswaPage();
      }
    }

    return const LoginPage();
  }
}
