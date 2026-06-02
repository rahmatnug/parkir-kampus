import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../../data/services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  int? _idRole; // 1: Admin, 2: Dosen, 3: Mahasiswa
  String? _roleString;
  int _penaltyPoints = 0;
  bool _isBlacklisted = false;
  String _blacklistReason = "";
  String _blacklistDate = "";
  List<dynamic> _riwayatPelanggaran = [];

  String? _nama;
  String? _email;
  String? _nim;
  String? _idKendaraan;
  String? _platNomor;
  String? _jenisKendaraan;
  String? _profileImageUrl;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int? get idRole => _idRole;
  String? get roleString => _roleString;
  int get penaltyPoints => _penaltyPoints;
  bool get isBlacklisted => _isBlacklisted;
  String get blacklistReason => _blacklistReason;
  String get blacklistDate => _blacklistDate;
  List<dynamic> get riwayatPelanggaran => _riwayatPelanggaran;
  bool get isAuthenticated => _status == AuthStatus.authenticated;  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    _nama = data['nama'];
    _email = data['email'];
    _nim = data['nim'];
    _idKendaraan = data['id_kendaraan'];
    _platNomor = data['plat_nomor'];
    _jenisKendaraan = data['jenis_kendaraan'];
    _profileImageUrl = data['profile_image_url'];
    
    _penaltyPoints = int.tryParse(data['total_poin'] ?? '0') ?? 0;
    _isBlacklisted = data['is_blacklisted'] == 'true';
    _blacklistReason = data['blacklist_reason'] ?? '';
    _blacklistDate = data['blacklist_date'] ?? '';
    
    if (data['riwayat_pelanggaran'] != null && data['riwayat_pelanggaran'].toString().isNotEmpty) {
      try {
        _riwayatPelanggaran = jsonDecode(data['riwayat_pelanggaran']!);
      } catch (e) {
        _riwayatPelanggaran = [];
      }
    }
  }

  /// Public method to refresh user data from the backend and notify listeners.
  Future<void> refreshUserData() async {
    await _authService.fetchProfile();
    await _loadUserData();
    notifyListeners();
  }

  String? get nama => _nama;
  String? get email => _email;
  String? get nim => _nim;
  String? get idKendaraan => _idKendaraan;
  String? get platNomor => _platNomor;
  String? get jenisKendaraan => _jenisKendaraan;
  String? get profileImageUrl => _profileImageUrl;

  /// Simulasi data user (Bisa diubah untuk testing)
  void setMockStatus({int penalty = 0, bool blacklisted = false, String reason = ""}) {
    _penaltyPoints = penalty;
    _isBlacklisted = blacklisted;
    _blacklistReason = reason;
    notifyListeners();
  }

  /// Get the currently stored token
  Future<String?> getToken() async {
    return await _authService.getToken();
  }

  /// Check saved token and extract role on app launch
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final token = await _authService.getToken();
    if (token != null && !JwtDecoder.isExpired(token)) {
      _extractRole(token);
      await _authService.fetchProfile();
      await _loadUserData();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Login and extract role from JWT
  Future<bool> login(String email, String password, bool rememberMe) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(email, password, rememberMe);
      _extractRole(token);
      await _loadUserData();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      debugPrint('AuthProvider catch DioException: ${e.message}');
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.response?.data['message'] ?? e.message ?? 'Gagal login';
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AuthProvider catch generic Exception: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String nama, String nim, String email, String password, String platNomor, String jenisKendaraan, {String role = ''}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(nama, nim, email, password, platNomor, jenisKendaraan, role: role);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.response?.data['message'] ?? e.response?.data['error'] ?? e.message ?? 'Gagal registrasi';
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }



  void _extractRole(String token) {
    try {
      if (token.isEmpty) {
        _idRole = null;
        _roleString = null;
        return;
      }
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      // Mendukung key 'id_role' atau 'role_id'
      _idRole = decodedToken['id_role'] ?? decodedToken['role_id']; 
      _roleString = decodedToken['role'] ?? '';
      debugPrint("Token decoded successfully. Role ID: $_idRole, Role: $_roleString");
    } catch (e) {
      debugPrint("Error decoding token: $e");
      _idRole = null;
      _roleString = null;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _idRole = null;
    _nama = null;
    _email = null;
    _nim = null;
    _platNomor = null;
    _jenisKendaraan = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
