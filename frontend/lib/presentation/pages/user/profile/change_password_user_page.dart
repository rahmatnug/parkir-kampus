import 'package:flutter/material.dart';
import '../../../widgets/global_parking_layout.dart';

class ChangePasswordUserPage extends StatefulWidget {
  const ChangePasswordUserPage({super.key});

  @override
  State<ChangePasswordUserPage> createState() => _ChangePasswordUserPageState();
}

class _ChangePasswordUserPageState extends State<ChangePasswordUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Panggil BLoC/Service khusus User
      // context.read<ChangePasswordUserBloc>().add(UpdatePasswordEvent(...));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memproses perubahan password User...'),
          backgroundColor: Color(0xFF1E70EB),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalParkingLayout(
      title: 'Ganti Password',
      currentIndex: 3, // Menandakan navigasi di tab Profile
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F5FF), 
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_backup_restore, // Refresh/lock alternative
                        size: 40,
                        color: Color(0xFF1E70EB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Amankan Akun',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _buildLabel('PASSWORD SAAT INI'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _oldPasswordController,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureOld,
                onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Password lama tidak boleh kosong';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              _buildLabel('PASSWORD BARU'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _newPasswordController,
                prefixIcon: Icons.key_outlined,
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                onChanged: (val) => setState(() {}), 
                validator: (val) {
                  if (val == null || val.length < 8) return 'Password minimal 8 karakter';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              _buildStrengthMeter(_newPasswordController.text),
              
              const SizedBox(height: 24),
              _buildLabel('KONFIRMASI PASSWORD BARU'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                prefixIcon: Icons.shield_outlined,
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _newPasswordController.text) return 'Password konfirmasi tidak cocok';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Color(0xFF1E70EB), size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Password minimal 8 karakter, harus mengandung kombinasi huruf besar, huruf kecil, dan angka.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E70EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Update Password',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4B5563),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData prefixIcon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF6B7280)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF6B7280),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  Widget _buildStrengthMeter(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;

    Color strengthColor = const Color(0xFFE5E7EB);
    String strengthText = '';
    
    if (password.isNotEmpty) {
      if (strength == 3) {
        strengthColor = Colors.green;
        strengthText = 'KUAT';
      } else if (strength == 2) {
        strengthColor = Colors.orange;
        strengthText = 'SEDANG';
      } else {
        strengthColor = Colors.red;
        strengthText = 'LEMAH';
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KEKUATAN PASSWORD',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 1 ? strengthColor : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 2 ? strengthColor : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: strength >= 3 ? strengthColor : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
