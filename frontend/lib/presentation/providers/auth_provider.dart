import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../data/services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  int? _idRole; // 1: Admin, 2: Dosen, 3: Mahasiswa
  int _penaltyPoints = 0;
  bool _isBlacklisted = false;
  String _blacklistReason = "";

  String? _nama;
  String? _email;
  String? _nim;
  String? _platNomor;
  String? _jenisKendaraan;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  int? get idRole => _idRole;
  int get penaltyPoints => _penaltyPoints;
  bool get isBlacklisted => _isBlacklisted;
  String get blacklistReason => _blacklistReason;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  String? get nama => _nama;
  String? get email => _email;
  String? get nim => _nim;
  String? get platNomor => _platNomor;
  String? get jenisKendaraan => _jenisKendaraan;

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
      await _loadUserData();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Login and extract role from JWT
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(email, password);
      _extractRole(token);
      await _loadUserData();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String nama, String nim, String email, String password, String platNomor, String jenisKendaraan) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(nama, nim, email, password, platNomor, jenisKendaraan);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    _nama = data['nama'];
    _email = data['email'];
    _nim = data['nim'];
    _platNomor = data['plat_nomor'];
    _jenisKendaraan = data['jenis_kendaraan'];
  }

  void _extractRole(String token) {
    try {
      if (token.isEmpty) {
        _idRole = null;
        return;
      }
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      // Mendukung key 'id_role' atau 'role_id'
      _idRole = decodedToken['id_role'] ?? decodedToken['role_id']; 
      debugPrint("Token decoded successfully. Role ID: $_idRole");
    } catch (e) {
      debugPrint("Error decoding token: $e");
      _idRole = null;
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
