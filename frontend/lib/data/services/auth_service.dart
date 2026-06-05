import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

class AuthService {
  static final Map<String, String> _memoryStorage = {};
  String _activePrefix = 'user_';

  static const _tokenKey = 'auth_token';
  static const _namaKey = 'user_nama';
  static const _emailKey = 'user_email';
  static const _nimKey = 'user_nim';
  static const _roleKey = 'user_role';

  Future<void> _writeKey(String key, String? value, bool rememberMe) async {
    if (value == null) return;
    final actualKey = '$_activePrefix$key';
    final prefs = await SharedPreferences.getInstance();

    // Always persist to SharedPreferences to survive F5 on Web
    await prefs.setString(actualKey, value);
    _memoryStorage[actualKey] = value;
  }

  Future<String?> _readKey(String key) async {
    final actualKey = '$_activePrefix$key';
    if (_memoryStorage.containsKey(actualKey)) {
      return _memoryStorage[actualKey];
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(actualKey);
  }

  Future<String?> getToken() async {
    if (_memoryStorage.containsKey('admin_auth_token')) {
      _activePrefix = 'admin_';
      return _memoryStorage['admin_auth_token'];
    }
    if (_memoryStorage.containsKey('user_auth_token')) {
      _activePrefix = 'user_';
      return _memoryStorage['user_auth_token'];
    }
    final prefs = await SharedPreferences.getInstance();
    final adminToken = prefs.getString('admin_auth_token');
    if (adminToken != null) {
      _activePrefix = 'admin_';
      return adminToken;
    }
    final userToken = prefs.getString('user_auth_token');
    if (userToken != null) {
      _activePrefix = 'user_';
      return userToken;
    }
    return null;
  }

  Future<void> fetchProfile() async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/api/user/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          final user = data['user'];
          final isInStorage = true; // Always save metadata when profile fetched

          await _writeKey(_namaKey, user['nama']?.toString(), isInStorage);
          await _writeKey(_emailKey, user['email']?.toString(), isInStorage);
          await _writeKey(_nimKey, user['nim']?.toString(), isInStorage);
          await _writeKey(_roleKey, user['id_role']?.toString(), isInStorage);

          await _writeKey(
            'user_total_poin',
            user['total_poin']?.toString(),
            isInStorage,
          );
          await _writeKey(
            'user_is_blacklisted',
            user['is_blacklisted']?.toString(),
            isInStorage,
          );
          await _writeKey(
            'user_blacklist_reason',
            user['blacklist_reason']?.toString(),
            isInStorage,
          );
          await _writeKey(
            'user_blacklist_date',
            user['blacklist_date']?.toString(),
            isInStorage,
          );
          if (user['riwayat_pelanggaran'] != null) {
            await _writeKey(
              'user_riwayat_pelanggaran',
              jsonEncode(user['riwayat_pelanggaran']),
              isInStorage,
            );
          }

          if (user['kendaraans'] != null &&
              (user['kendaraans'] as List?)?.isNotEmpty == true) {
            final kendaraan = user['kendaraans'][0];
            await _writeKey(
              'user_id_kendaraan',
              kendaraan['id_kendaraan']?.toString(),
              isInStorage,
            );
            await _writeKey(
              'user_plat_nomor',
              kendaraan['nomor_polisi']?.toString(),
              isInStorage,
            );
            await _writeKey(
              'user_jenis_kendaraan',
              kendaraan['jenis_kendaraan']?.toString(),
              isInStorage,
            );
          }
          await _writeKey(
            'user_profile_image_url',
            user['profile_image_url']?.toString(),
            isInStorage,
          );
        }
      }
    } catch (e) {
      // Ignore errors on background fetch
    }
  }

  Future<String> login(String email, String password, bool rememberMe) async {
    try {
      final d = dio_pkg.Dio();
      final response = await d.post(
        AppConfig.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'] ?? '';
        if (token.isEmpty) {
          throw Exception('Server mengembalikan token kosong');
        }
        if (data['user'] != null) {
          final user = data['user'];

          // ── FIX 1: Blokir login jika status user adalah 'blocked' ──────
          final userStatus = user['status']?.toString() ?? '';
          if (userStatus == 'blocked' || userStatus == 'blacklisted') {
            throw Exception('Akun Anda telah diblokir. Hubungi administrator.');
          }

          final roleName =
              user['role']?['nama_role']?.toString().toLowerCase() ?? '';
          final idRole = user['id_role']?.toString();
          if (roleName.isNotEmpty) {
            _activePrefix = (roleName == 'admin' || roleName == 'petugas')
                ? 'admin_'
                : 'user_';
          } else {
            _activePrefix = (idRole == '1' || idRole == '6')
                ? 'admin_'
                : 'user_';
          }

          await _writeKey(_namaKey, user['nama']?.toString(), rememberMe);
          await _writeKey(_emailKey, user['email']?.toString(), rememberMe);
          await _writeKey(_nimKey, user['nim']?.toString(), rememberMe);
          await _writeKey(_roleKey, idRole, rememberMe);

          await _writeKey(
            'user_total_poin',
            user['total_poin']?.toString(),
            rememberMe,
          );
          await _writeKey(
            'user_is_blacklisted',
            user['is_blacklisted']?.toString(),
            rememberMe,
          );
          await _writeKey(
            'user_blacklist_reason',
            user['blacklist_reason']?.toString(),
            rememberMe,
          );
          await _writeKey(
            'user_blacklist_date',
            user['blacklist_date']?.toString(),
            rememberMe,
          );
          if (user['riwayat_pelanggaran'] != null) {
            await _writeKey(
              'user_riwayat_pelanggaran',
              jsonEncode(user['riwayat_pelanggaran']),
              rememberMe,
            );
          }

          if (user['kendaraans'] != null &&
              (user['kendaraans'] as List?)?.isNotEmpty == true) {
            final kendaraan = user['kendaraans'][0];
            await _writeKey(
              'user_id_kendaraan',
              kendaraan['id_kendaraan']?.toString(),
              rememberMe,
            );
            await _writeKey(
              'user_plat_nomor',
              kendaraan['nomor_polisi']?.toString(),
              rememberMe,
            );
            await _writeKey(
              'user_jenis_kendaraan',
              kendaraan['jenis_kendaraan']?.toString(),
              rememberMe,
            );
          }
          await _writeKey(
            'user_profile_image_url',
            user['profile_image_url']?.toString(),
            rememberMe,
          );
        }
        await _writeKey(_tokenKey, token, rememberMe);
        return token;
      } else {
        throw Exception('Login gagal: ${response.statusCode}');
      }
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        'DioException di login: ${e.message}, response data: ${e.response?.data}',
      );
      String msg = 'Gagal terhubung ke server';
      final data = e.response?.data;

      if (data is Map) {
        msg = data['message'] ?? data['error'] ?? e.message ?? msg;
      } else if (data is String) {
        try {
          final decoded = jsonDecode(data);
          msg = decoded['message'] ?? decoded['error'] ?? data;
        } catch (_) {
          msg = data;
        }
      } else if (e.message != null) {
        msg = e.message!;
      }
      throw Exception(msg);
    } on SocketException {
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw Exception('Request timeout. Server tidak merespons.');
    }
  }

  Future<void> register(
    String nama,
    String nim,
    String email,
    String password,
    String platNomor,
    String jenisKendaraan, {
    String role = '',
  }) async {
    try {
      final body = {
        'nama': nama,
        'nim': nim,
        'email': email,
        'password': password,
        'plat_nomor': platNomor,
        'jenis_kendaraan': jenisKendaraan,
      };
      if (role.isNotEmpty) {
        body['role'] = role;
      }
      final d = dio_pkg.Dio();
      final response = await d.post(AppConfig.registerEndpoint, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception('Gagal melakukan registrasi: ${response.statusCode}');
      }
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        'DioException di register: ${e.message}, response data: ${e.response?.data}',
      );
      String msg = 'Gagal terhubung ke server';
      final data = e.response?.data;

      if (data is Map) {
        msg = data['message'] ?? data['error'] ?? e.message ?? msg;
      } else if (data is String) {
        try {
          final decoded = jsonDecode(data);
          msg = decoded['message'] ?? decoded['error'] ?? data;
        } catch (_) {
          msg = data;
        }
      } else if (e.message != null) {
        msg = e.message!;
      }
      throw Exception(msg);
    } on SocketException {
      throw Exception(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw Exception('Request timeout. Server tidak merespons.');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all keys regardless of current prefix, or specifically based on app logic
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('admin_') || key.startsWith('user_')) {
        await prefs.remove(key);
      }
    }
    _memoryStorage.clear();
    _activePrefix = 'user_';
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'nama': await _readKey(_namaKey),
      'email': await _readKey(_emailKey),
      'nim': await _readKey(_nimKey),
      'role': await _readKey(_roleKey),
      'id_kendaraan': await _readKey('user_id_kendaraan'),
      'plat_nomor': await _readKey('user_plat_nomor'),
      'jenis_kendaraan': await _readKey('user_jenis_kendaraan'),
      'profile_image_url': await _readKey('user_profile_image_url'),
      'total_poin': await _readKey('user_total_poin'),
      'is_blacklisted': await _readKey('user_is_blacklisted'),
      'blacklist_reason': await _readKey('user_blacklist_reason'),
      'blacklist_date': await _readKey('user_blacklist_date'),
      'riwayat_pelanggaran': await _readKey('user_riwayat_pelanggaran'),
    };
  }

  /// Update user profile (vehicle info)
  Future<void> updateProfile(
    int idKendaraan,
    String nomorPolisi,
    String jenisKendaraan,
    String warna,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('Tidak ada token');

    final response = await http
        .put(
          Uri.parse('${AppConfig.baseUrl}/api/user/kendaraan'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'id_kendaraan': idKendaraan,
            'nomor_polisi': nomorPolisi,
            'jenis_kendaraan': jenisKendaraan,
            'warna': warna,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal memperbarui profil');
    }
  }

  /// Uploads avatar image to backend, returns the new public URL.
  Future<String> uploadAvatar(Uint8List bytes, String filename) async {
    final token = await getToken();
    if (token == null) throw Exception('Tidak ada token');

    final d = dio_pkg.Dio();
    d.options.headers['Authorization'] = 'Bearer $token';
    d.options.connectTimeout = const Duration(seconds: 15);
    d.options.sendTimeout = const Duration(seconds: 30);
    d.options.receiveTimeout = const Duration(seconds: 15);

    final formData = dio_pkg.FormData.fromMap({
      'avatar': dio_pkg.MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await d.post(
      '${AppConfig.baseUrl}/api/user/avatar',
      data: formData,
    );

    if (response.statusCode == 200) {
      final url = response.data['profile_image_url'] as String;
      // Persist the new URL
      await _writeKey('user_profile_image_url', url, true);
      return url;
    } else {
      throw Exception(response.data['message'] ?? 'Upload gagal');
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
