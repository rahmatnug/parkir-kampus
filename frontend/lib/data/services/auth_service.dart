import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
    if (rememberMe) {
      await _storage.write(key: actualKey, value: value);
      _memoryStorage.remove(actualKey);
    } else {
      _memoryStorage[actualKey] = value;
      await _storage.delete(key: actualKey);
    }
  }

  Future<String?> _readKey(String key) async {
    final actualKey = '$_activePrefix$key';
    if (_memoryStorage.containsKey(actualKey)) {
      return _memoryStorage[actualKey];
    }
    return await _storage.read(key: actualKey);
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
    final adminToken = await _storage.read(key: 'admin_auth_token');
    if (adminToken != null) {
      _activePrefix = 'admin_';
      return adminToken;
    }
    final userToken = await _storage.read(key: 'user_auth_token');
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
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          final user = data['user'];
          final actualTokenKey = '$_activePrefix$_tokenKey';
          final isInStorage = await _storage.read(key: actualTokenKey) != null;
          
          await _writeKey(_namaKey, user['nama']?.toString(), isInStorage);
          await _writeKey(_emailKey, user['email']?.toString(), isInStorage);
          await _writeKey(_nimKey, user['nim']?.toString(), isInStorage);
          await _writeKey(_roleKey, user['id_role']?.toString(), isInStorage);
          
          if (user['kendaraans'] != null && (user['kendaraans'] as List).isNotEmpty) {
            final kendaraan = user['kendaraans'][0];
            await _writeKey('user_plat_nomor', kendaraan['nomor_polisi']?.toString(), isInStorage);
            await _writeKey('user_jenis_kendaraan', kendaraan['jenis_kendaraan']?.toString(), isInStorage);
          }
          await _writeKey('user_profile_image_url', user['profile_image_url']?.toString(), isInStorage);
        }
      }
    } catch (e) {
      // Ignore errors on background fetch
    }
  }

  Future<String> login(String email, String password, bool rememberMe) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.loginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? '';
        if (token.isEmpty) {
          throw Exception('Server mengembalikan token kosong');
        }
        if (data['user'] != null) {
          final user = data['user'];
          final idRole = user['id_role']?.toString();
          _activePrefix = (idRole == '1' || idRole == '2') ? 'admin_' : 'user_';

          await _writeKey(_namaKey, user['nama']?.toString(), rememberMe);
          await _writeKey(_emailKey, user['email']?.toString(), rememberMe);
          await _writeKey(_nimKey, user['nim']?.toString(), rememberMe);
          await _writeKey(_roleKey, idRole, rememberMe);
          
          if (user['kendaraans'] != null && (user['kendaraans'] as List).isNotEmpty) {
            final kendaraan = user['kendaraans'][0];
            await _writeKey('user_plat_nomor', kendaraan['nomor_polisi']?.toString(), rememberMe);
            await _writeKey('user_jenis_kendaraan', kendaraan['jenis_kendaraan']?.toString(), rememberMe);
          }
          await _writeKey('user_profile_image_url', user['profile_image_url']?.toString(), rememberMe);
        }
        await _writeKey(_tokenKey, token, rememberMe);
        return token;
      } else if (response.statusCode == 401) {
        throw Exception("Email atau password salah (Unauthorized 401).");
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw Exception('Request timeout. Server tidak merespons.');
    }
  }

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
        return; 
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Gagal melakukan registrasi');
      }
    } on SocketException {
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw Exception('Request timeout. Server tidak merespons.');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: '$_activePrefix$_tokenKey');
    await _storage.delete(key: '$_activePrefix$_namaKey');
    await _storage.delete(key: '$_activePrefix$_emailKey');
    await _storage.delete(key: '$_activePrefix$_nimKey');
    await _storage.delete(key: '$_activePrefix$_roleKey');
    await _storage.delete(key: '${_activePrefix}user_plat_nomor');
    await _storage.delete(key: '${_activePrefix}user_jenis_kendaraan');
    
    _memoryStorage.removeWhere((key, value) => key.startsWith(_activePrefix));
    _activePrefix = 'user_'; 
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'nama': await _readKey(_namaKey),
      'email': await _readKey(_emailKey),
      'nim': await _readKey(_nimKey),
      'role': await _readKey(_roleKey),
      'plat_nomor': await _readKey('user_plat_nomor'),
      'jenis_kendaraan': await _readKey('user_jenis_kendaraan'),
      'profile_image_url': await _readKey('user_profile_image_url'),
    };
  }

  /// Uploads avatar image to backend, returns the new public URL.
  Future<String> uploadAvatar(String filePath) async {
    final token = await getToken();
    if (token == null) throw Exception('Tidak ada token');

    final d = dio_pkg.Dio();
    d.options.headers['Authorization'] = 'Bearer $token';
    d.options.connectTimeout = const Duration(seconds: 15);
    d.options.sendTimeout = const Duration(seconds: 30);
    d.options.receiveTimeout = const Duration(seconds: 15);

    final formData = dio_pkg.FormData.fromMap({
      'avatar': await dio_pkg.MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last.split('\\').last,
      ),
    });

    final response = await d.post(
      '${AppConfig.baseUrl}/api/user/avatar',
      data: formData,
    );

    if (response.statusCode == 200) {
      final url = response.data['profile_image_url'] as String;
      // Persist the new URL
      final actualTokenKey = '$_activePrefix$_tokenKey';
      final isInStorage = await _storage.read(key: actualTokenKey) != null;
      await _writeKey('user_profile_image_url', url, isInStorage);
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

