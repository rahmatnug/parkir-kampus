import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../models/login_response.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  /// Sends POST /api/login, returns JWT token on success.
  /// Throws [Exception] with a descriptive message on any failure.
  Future<String> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.loginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = LoginResponse.fromJson(jsonDecode(response.body));
        if (data.token.isEmpty) {
          throw Exception('Server mengembalikan token kosong');
        }
        await saveToken(data.token);
        return data.token;
      } else if (response.statusCode == 401) {
        // Parse error message from server if available
        String msg = 'Email atau Password Salah';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          msg = body['error'] as String? ?? msg;
        } catch (_) {/* ignore parse errors */}
        throw Exception(msg);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
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
  }

  /// Returns true only if a non-empty token is stored.
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
