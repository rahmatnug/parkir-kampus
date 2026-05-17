import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBlue    = Color(0xFF1E3FAE);
const _kBg      = Color(0xFFF6F6F8);
const _kBorder  = Color(0xFFE8EAF0);
const _kText    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);
const _kGreen   = Color(0xFF16A34A);
const _kRed     = Color(0xFFDC2626);
const _kSuccess = Color(0xFFECFDF5);

// ─── Page ─────────────────────────────────────────────────────────────────────
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey       = GlobalKey<FormState>();
  final _currentCtrl   = TextEditingController();
  final _newCtrl       = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  bool _showCurrent  = false;
  bool _showNew      = false;
  bool _showConfirm  = false;
  bool _isLoading    = false;
  String? _errorMsg;
  bool _success = false;

  // ─── Requirements state ─────────────────────────────────────────────────────
  bool get _hasMinLength     => _newCtrl.text.length >= 8;
  bool get _hasUppercase     => _newCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase     => _newCtrl.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber        => _newCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar   => _newCtrl.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _passwordsMatch   => _newCtrl.text == _confirmCtrl.text && _confirmCtrl.text.isNotEmpty;
  bool get _notSameAsCurrent => _newCtrl.text != _currentCtrl.text || _newCtrl.text.isEmpty;

  // Strength 0–4
  int get _strength {
    int s = 0;
    if (_hasMinLength)   s++;
    if (_hasUppercase)   s++;
    if (_hasNumber)      s++;
    if (_hasSpecialChar) s++;
    return s;
  }

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      // Ambil token JWT dari secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': _currentCtrl.text,
          'new_password':     _newCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() { _isLoading = false; _success = true; });
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _errorMsg = body['message'] ?? 'Gagal memperbarui password';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Gagal terhubung ke server. Periksa koneksi Anda.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: _kText),
                    onPressed: () => Navigator.pop(context),
                  ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ganti Password',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _kText)),
                    SizedBox(height: 4),
                    Text('Perbarui credential akun Anda',
                        style: TextStyle(fontSize: 13, color: _kMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Two-column layout
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildFormCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _buildSecurityPanel()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildFormCard(),
                    const SizedBox(height: 20),
                    _buildSecurityPanel(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Form Card ──────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section heading
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      size: 20, color: _kBlue),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Perbarui Password',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _kText)),
                    Text('Isi semua field di bawah',
                        style: TextStyle(fontSize: 12, color: _kMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Success banner
            if (_success) ...[
              _SuccessBanner(onDismiss: () => setState(() => _success = false)),
              const SizedBox(height: 20),
            ],

            // Error banner
            if (_errorMsg != null) ...[
              _ErrorBanner(message: _errorMsg!),
              const SizedBox(height: 16),
            ],

            // Current password
            _FieldLabel('Password Saat Ini'),
            const SizedBox(height: 6),
            _PasswordField(
              controller: _currentCtrl,
              placeholder: 'Masukkan password lama',
              show: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Field ini wajib diisi';
                if (v.length < 3) return 'Password tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // New password
            _FieldLabel('Password Baru'),
            const SizedBox(height: 6),
            _PasswordField(
              controller: _newCtrl,
              placeholder: 'Min. 8 karakter',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Field ini wajib diisi';
                if (!_hasMinLength) return 'Minimal 8 karakter';
                if (!_notSameAsCurrent) {
                  return 'Password baru tidak boleh sama dengan yang lama';
                }
                return null;
              },
            ),

            // Strength bar
            const SizedBox(height: 10),
            _StrengthBar(strength: _strength),
            const SizedBox(height: 20),

            // Confirm password
            _FieldLabel('Konfirmasi Password Baru'),
            const SizedBox(height: 6),
            _PasswordField(
              controller: _confirmCtrl,
              placeholder: 'Ulangi password baru',
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Field ini wajib diisi';
                if (v != _newCtrl.text) return 'Password tidak sama';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  disabledBackgroundColor: _kBlue.withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan Password Baru',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Security Panel ─────────────────────────────────────────────────────────
  Widget _buildSecurityPanel() {
    return Column(
      children: [
        // Requirements card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.security_rounded,
                        size: 20, color: _kGreen),
                  ),
                  const SizedBox(width: 12),
                  const Text('Security Requirements',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _kText)),
                ],
              ),
              const SizedBox(height: 20),
              _Requirement(
                label: 'Minimal 8 karakter',
                met: _hasMinLength,
              ),
              _Requirement(
                label: 'Mengandung huruf besar (A–Z)',
                met: _hasUppercase,
              ),
              _Requirement(
                label: 'Mengandung huruf kecil (a–z)',
                met: _hasLowercase,
              ),
              _Requirement(
                label: 'Mengandung angka (0–9)',
                met: _hasNumber,
              ),
              _Requirement(
                label: 'Mengandung simbol (!@#\$...)',
                met: _hasSpecialChar,
              ),
              _Requirement(
                label: 'Password konfirmasi cocok',
                met: _passwordsMatch,
              ),
              _Requirement(
                label: 'Berbeda dari password lama',
                met: _notSameAsCurrent && _newCtrl.text.isNotEmpty,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tips card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBlue.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: _kBlue),
                  const SizedBox(width: 8),
                  const Text('Tips Keamanan',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _kBlue)),
                ],
              ),
              const SizedBox(height: 12),
              _Tip('Jangan gunakan password yang sama di banyak layanan.'),
              _Tip('Gunakan kombinasi huruf, angka, dan simbol.'),
              _Tip('Ganti password secara berkala (3–6 bulan sekali).'),
              _Tip('Jangan bagikan password kepada siapapun.'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Reusable Field Widgets ───────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kText));
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String   placeholder;
  final bool     show;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.placeholder,
    required this.show,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _kText),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
        suffixIcon: IconButton(
          icon: Icon(
            show
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: _kMuted,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: _kBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kRed, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Password Strength Bar ────────────────────────────────────────────────────
class _StrengthBar extends StatelessWidget {
  final int strength; // 0–4
  const _StrengthBar({required this.strength});

  Color get _color {
    switch (strength) {
      case 0:
      case 1: return _kRed;
      case 2: return _kOrange;
      case 3: return const Color(0xFF84CC16);
      case 4: return _kGreen;
      default: return _kRed;
    }
  }

  String get _label {
    switch (strength) {
      case 0: return '';
      case 1: return 'Lemah';
      case 2: return 'Cukup';
      case 3: return 'Kuat';
      case 4: return 'Sangat Kuat';
      default: return '';
    }
  }

  static const _kOrange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < strength;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? _color : _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(_label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _color)),
      ],
    );
  }
}

// ─── Requirement Row ──────────────────────────────────────────────────────────
class _Requirement extends StatelessWidget {
  final String label;
  final bool   met;
  const _Requirement({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: met
                  ? _kGreen.withValues(alpha: 0.12)
                  : _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: met ? _kGreen : _kBorder, width: 1.5),
            ),
            child: met
                ? const Icon(Icons.check_rounded, size: 12, color: _kGreen)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: met ? _kText : _kMuted)),
          ),
        ],
      ),
    );
  }
}

// ─── Tips ─────────────────────────────────────────────────────────────────────
class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 5, color: _kBlue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: _kText)),
          ),
        ],
      ),
    );
  }
}

// ─── Banners ──────────────────────────────────────────────────────────────────
class _SuccessBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SuccessBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSuccess,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGreen.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 20, color: _kGreen),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Password berhasil diperbarui!',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kGreen)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: _kGreen),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: _kRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: _kRed)),
          ),
        ],
      ),
    );
  }
}

// Needed for _StrengthBar
const _kOrange = Color(0xFFF59E0B);
