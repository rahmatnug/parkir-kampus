import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';
import '../../main.dart';

class UserAuthPage extends StatefulWidget {
  const UserAuthPage({super.key});

  @override
  State<UserAuthPage> createState() => _UserAuthPageState();
}

class _UserAuthPageState extends State<UserAuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Login fields
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPassVisible = false;
  bool _rememberDevice = false;
  bool _isLoading = false;

  final _loginFormKey = GlobalKey<FormState>();

  final _registerFormKey = GlobalKey<FormState>();

  // Register fields
  final _regNamaCtrl = TextEditingController();
  final _regNimCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  final _platCtrl = TextEditingController();
  bool _regPassVisible = false;
  bool _regConfirmVisible = false;
  String _jenisKendaraan = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNamaCtrl.dispose();
    _regNimCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _platCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      bool success = await context.read<AuthProvider>().login(
            _loginEmailCtrl.text.trim(),
            _loginPassCtrl.text,
            _rememberDevice,
          );
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (Route<dynamic> route) => false,
        );
      } else {
        if (!mounted) return;
        _showSnack(context.read<AuthProvider>().errorMessage ?? 'Gagal login');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }
    if (_jenisKendaraan.isEmpty) {
      _showSnack('Pilih jenis kendaraan terlebih dahulu');
      return;
    }
    setState(() => _isLoading = true);
    try {
      bool success = await context.read<AuthProvider>().register(
            _regNamaCtrl.text.trim(),
            _regNimCtrl.text.trim(),
            _regEmailCtrl.text.trim(),
            _regPassCtrl.text,
            _platCtrl.text.trim(),
            _jenisKendaraan,
          );
      if (success) {
        _showSnack('Registrasi berhasil! Silakan login.');
        _tabCtrl.animateTo(0);
        setState(() {});
      } else {
        if (!mounted) return;
        _showSnack(context.read<AuthProvider>().errorMessage ?? 'Gagal register');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      body: Stack(
        children: [
          // Top decorative background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: CustomPaint(painter: _TopBgPainter()),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo row
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('P',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ParkirKampus',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Efficient parking for every civitas academica.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 28),

                  // Tab bar
                  TabBar(
                    controller: _tabCtrl,
                    labelStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    unselectedLabelStyle:
                        const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                    labelColor: const Color(0xFF2563EB),
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    indicatorColor: const Color(0xFF2563EB),
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Register'),
                    ],
                    onTap: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),

                  // Tab content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _tabCtrl.index == 0
                        ? _buildLoginForm()
                        : _buildRegisterForm(),
                  ),

                  const SizedBox(height: 16),

                  // Admin switch
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                      },
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                      label: const Text('Masuk sebagai Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footer
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          "By continuing, you agree to ParkirKampus's ",
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Terms of Service — segera tersedia'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Text(
                          ' and ',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Privacy Policy — segera tersedia'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOGIN FORM ────────────────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _FieldLabel(label: 'EMAIL OR NIM/ID'),
        const SizedBox(height: 8),
        _AuthField(
          controller: _loginEmailCtrl,
          hint: 'e.g. 25051204306 or 25051204306@mhs.unesa.ac.id',
          prefixIcon: Icons.person_outline_rounded,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email/NIM wajib diisi';
            bool isNim = RegExp(r'^[0-9]+$').hasMatch(v);
            bool isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v);
            if (!isNim && !isEmail) return 'Masukkan NIM atau Email yang valid';
            return null;
          },
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _FieldLabel(label: 'PASSWORD'),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hubungi Admin untuk reset password mahasiswa'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Forgot?',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AuthField(
          controller: _loginPassCtrl,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _loginPassVisible,
          onToggleVisibility: () =>
              setState(() => _loginPassVisible = !_loginPassVisible),
          validator: (v) => v == null || v.isEmpty ? 'Password wajib diisi' : null,
        ),
        const SizedBox(height: 14),

        // Remember device
        Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: _rememberDevice,
                onChanged: (v) =>
                    setState(() => _rememberDevice = v ?? false),
                activeColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Remember this device',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ],
        ),
        const SizedBox(height: 24),

        // Login button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Login to Account',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Create account button
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              _tabCtrl.animateTo(1);
              setState(() {});
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFFDBEAFE), width: 1.5),
              backgroundColor: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create New Account',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB))),
          ),
        ),
      ],
    ),
  );
  }

  // ─── REGISTER FORM ─────────────────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const _FieldLabel(label: 'NAMA LENGKAP'),
        const SizedBox(height: 8),
        _AuthField(
          controller: _regNamaCtrl,
          hint: 'e.g. Budi Santoso',
          prefixIcon: Icons.badge_outlined,
          validator: (v) => v == null || v.isEmpty ? 'Nama lengkap wajib diisi' : null,
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'NIM / NIP'),
        const SizedBox(height: 8),
        _AuthField(
          controller: _regNimCtrl,
          hint: 'e.g. 21004567',
          prefixIcon: Icons.assignment_ind_outlined,
          validator: (v) {
            if (v == null || v.isEmpty) return 'NIM wajib diisi';
            if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'NIM hanya boleh berisi angka';
            if (v.length < 5) return 'NIM terlalu pendek';
            return null;
          },
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'EMAIL KAMPUS'),
        const SizedBox(height: 8),
        _AuthField(
          controller: _regEmailCtrl,
          hint: 'e.g. 25051204306@mhs.unesa.ac.id',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email wajib diisi';
            if (!RegExp(r'^[0-9]+@mhs\.unesa\.ac\.id$').hasMatch(v)) return 'Gunakan format email resmi: [NIM]@mhs.unesa.ac.id';
            return null;
          },
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'PASSWORD'),
        const SizedBox(height: 8),
        _AuthField(
          controller: _regPassCtrl,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _regPassVisible,
          onToggleVisibility: () =>
              setState(() => _regPassVisible = !_regPassVisible),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password wajib diisi';
            if (v.length < 8) return 'Password minimal 8 karakter';
            return null;
          },
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'KONFIRMASI PASSWORD'),
        const SizedBox(height: 8),
        _AuthField(
          controller: _regConfirmPassCtrl,
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          isVisible: _regConfirmVisible,
          onToggleVisibility: () =>
              setState(() => _regConfirmVisible = !_regConfirmVisible),
          validator: (v) {
            if (v != _regPassCtrl.text) return 'Konfirmasi password tidak cocok';
            return null;
          },
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'IDENTITAS KENDARAAN'),
        const SizedBox(height: 8),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _platCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500),
                validator: (v) => v == null || v.isEmpty ? 'Isi plat nomor' : null,
                decoration: InputDecoration(
                  hintText: 'PLAT NOMOR',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: Color(0xFFB0BAC9)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                  errorStyle: const TextStyle(color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF2563EB), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Colors.red, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _jenisKendaraan.isEmpty ? null : _jenisKendaraan,
                    hint: const Text('Jenis Kendaraan',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFFB0BAC9))),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF94A3B8)),
                    isDense: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF0F172A)),
                    onChanged: (v) =>
                        setState(() => _jenisKendaraan = v ?? ''),
                    items: ['Motor', 'Mobil']
                        .map((e) => DropdownMenuItem(
                              value: e.toLowerCase(),
                              child: Text(e),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Register button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Register Account',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 14),

        Center(
          child: GestureDetector(
            onTap: () {
              _tabCtrl.animateTo(0);
              setState(() {});
            },
            child: const Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                children: [
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ─── Auth Field ────────────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.isVisible = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: Color(0xFFB0BAC9)),
        prefixIcon:
            Icon(prefixIcon, size: 18, color: const Color(0xFF94A3B8)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.red),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
        letterSpacing: 0.6,
      ),
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────────────────
class _TopBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFDBEAFE).withValues(alpha: 0.6);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.6)
      ..quadraticBezierTo(
          size.width * 0.5, size.height, 0, size.height * 0.7)
      ..close();
    canvas.drawPath(path, paint);

    // Decorative circles (mountain silhouette hint)
    final circlePaint = Paint()
      ..color = const Color(0xFFBFD7FF).withValues(alpha: 0.4);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.9), 60, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.8), 80, circlePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
