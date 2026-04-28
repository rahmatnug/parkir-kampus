import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _namaKey = 'user_nama';
  static const _emailKey = 'user_email';
  static const _nimKey = 'user_nim';
  static const _roleKey = 'user_role';

  /// Sends POST /api/login, returns JWT token on success.
  /// Throws [Exception] with a descriptive message on any failure.
  Future<String> login(String email, String password) async {
    // No mock logic, we use real backend

    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.loginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      // ... rest of the code
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? '';
        if (token.isEmpty) {
          throw Exception('Server mengembalikan token kosong');
        }
        if (data['user'] != null) {
          final user = data['user'];
          await _storage.write(key: _namaKey, value: user['nama']?.toString());
          await _storage.write(key: _emailKey, value: user['email']?.toString());
          await _storage.write(key: _nimKey, value: user['nim']?.toString());
          await _storage.write(key: _roleKey, value: user['id_role']?.toString());
          // Coba ambil kendaraan jika ada
          if (user['kendaraans'] != null && (user['kendaraans'] as List).isNotEmpty) {
            final kendaraan = user['kendaraans'][0];
            await _storage.write(key: 'user_plat_nomor', value: kendaraan['nomor_polisi']?.toString());
            await _storage.write(key: 'user_jenis_kendaraan', value: kendaraan['jenis_kendaraan']?.toString());
          }
        }
        await saveToken(token);
        return token;
      } else if (response.statusCode == 401) {
        throw Exception("Email atau password salah (Unauthorized 401).");
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw Exception('Request timeout. Server tidak merespons.');
    }
  }

  /// Sends POST /api/register
  Future<void> register(String nama, String nim, String email, String password, String platNomor, String jenisKendaraan) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.registerEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nama': nama,
              'nim': nim,
              'email': email,
              'password': password,
              'plat_nomor': platNomor,
              'jenis_kendaraan': jenisKendaraan,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return; // Success
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Gagal melakukan registrasi');
      }
    } on SocketException {
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw Exception('Request timeout. Server tidak merespons.');
    }
  }

  /// Persists JWT token securely on device.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieves stored JWT token, returns null if not found.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Deletes the stored token (logout).
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _namaKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _nimKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: 'user_plat_nomor');
    await _storage.delete(key: 'user_jenis_kendaraan');
  }

  /// Retrieves user data
  Future<Map<String, String?>> getUserData() async {
    return {
      'nama': await _storage.read(key: _namaKey),
      'email': await _storage.read(key: _emailKey),
      'nim': await _storage.read(key: _nimKey),
      'role': await _storage.read(key: _roleKey),
      'plat_nomor': await _storage.read(key: 'user_plat_nomor'),
      'jenis_kendaraan': await _storage.read(key: 'user_jenis_kendaraan'),
    };
  }

  /// Returns true only if a non-empty token is stored.
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
