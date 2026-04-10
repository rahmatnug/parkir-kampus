import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/pages/user_auth_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/user_home_page.dart';
import 'package:frontend/presentation/pages/admin_splash_screen.dart';

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
      // LAYAR PERTAMA SEKARANG ADALAH ADMIN SPLASH SCREEN
      home: const AdminSplashScreen(),
    );
  }
}

/// Splash / auth gate widget that checks stored token on first run.
/// Diubah menjadi public (AuthGate) agar bisa diakses dari SplashScreen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
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
      // Mini loading screen (hanya muncul sekilas saat token dicek)
      return const Scaffold(
        backgroundColor: Color(0xFFF6F6F8), // Disamakan dengan background splash
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (status == AuthStatus.authenticated) {
      final idRole = context.watch<AuthProvider>().idRole;
      if (idRole == 1) {
        return const DashboardPage();
      } else {
        return const UserHomePage();
      }
    }

    return const UserAuthPage();
  }
}