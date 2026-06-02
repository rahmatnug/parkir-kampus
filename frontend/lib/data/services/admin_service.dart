import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import 'auth_service.dart';

class AdminService {
  String get _baseUrl => '${AppConfig.baseUrl}/api';
  final AuthService _authService = AuthService();

  /// Retrieve stored JWT token for authenticated requests.
  /// Uses AuthService to cover both in-memory and secure storage tokens.
  Future<String?> _getToken() => _authService.getToken();

  // ─── GET: Dashboard stats ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Failed to load dashboard stats');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── GET: Users list ──────────────────────────────────────────────────────
  Future<List<dynamic>> getUsers() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['users'] ?? [];
      }
      throw Exception('Failed to load users');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── GET: Single user by ID (with kendaraans) ────────────────────────────
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>;
      }
      throw Exception('Gagal memuat data user');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── GET: Activity logs ───────────────────────────────────────────────────
  Future<List<dynamic>> getActivities() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['activities'] ?? [];
      }
      throw Exception('Failed to load activities');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── DELETE: Remove user ──────────────────────────────────────────────────
  Future<void> deleteUser(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal menghapus user');
      }
    } catch (e) {
      throw Exception('Gagal menghapus user: $e');
    }
  }

  // ─── PUT: Update user role ────────────────────────────────────────────────
  Future<void> updateUserRole(int userId, String newRole) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/users/$userId/role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'role': newRole}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal update role');
      }
    } catch (e) {
      throw Exception('Gagal update role: $e');
    }
  }

  // ─── PUT: Update user admin ────────────────────────────────────────────────
  Future<void> updateUserAdmin(int userId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal memperbarui user');
      }
    } catch (e) {
      throw Exception('Gagal memperbarui user: $e');
    }
  }

  // ─── PUT: Update user status ──────────────────────────────────────────────
  Future<void> updateUserStatus(int userId, String newStatus) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': newStatus}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal mengubah status');
      }
    } catch (e) {
      throw Exception('Gagal mengubah status: $e');
    }
  }

  // ─── GET: Blacklisted users (poin > 50) ───────────────────────────────────
  Future<List<dynamic>> getBlacklist() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/blacklists'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['blacklist'] ?? [];
      }
      throw Exception('Failed to load blacklist');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── GET: Pending Laporan ──────────────────────────────────────────────────
  Future<List<dynamic>> getPendingLaporan() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/laporan/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load pending laporan: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading pending laporan: $e');
    }
  }

  // ─── GET: Blacklist Stats ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getBlacklistStats() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/blacklist-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load blacklist stats');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── GET: Laporan Detail ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getLaporanDetail(int laporanId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/laporan/$laporanId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load laporan detail');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── POST: Approve Laporan ────────────────────────────────────────────────
  Future<void> approveLaporan(int laporanId, int poin, String pelanggaran) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/penalti/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_laporan': laporanId,
          'poin_penalti': poin,
          'jenis_pelanggaran': pelanggaran,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? body['message'] ?? 'Gagal approve laporan');
      }
    } catch (e) {
      throw Exception('Gagal approve laporan: $e');
    }
  }

  // ─── PUT: Reject Laporan ────────────────────────────────────────────────
  Future<void> rejectLaporan(int laporanId) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/admin/laporan/$laporanId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? body['message'] ?? 'Gagal reject laporan');
      }
    } catch (e) {
      throw Exception('Gagal reject laporan: $e');
    }
  }

  // ─── POST: Force Exit Activity ────────────────────────────────────────────
  Future<void> forceExitActivity(int activityId) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/activities/$activityId/force-exit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal force exit kendaraan');
      }
    } catch (e) {
      throw Exception('Gagal force exit: $e');
    }
  }

  // ─── POST: Add Penalty ────────────────────────────────────────────────────
  Future<void> addPenalty(int userId, int poin, String keterangan) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/users/$userId/penalty'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'poin': poin,
          'keterangan': keterangan,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal menambahkan penalti');
      }
    } catch (e) {
      throw Exception('Gagal menambahkan penalti: $e');
    }
  }

  // ─── DELETE: Remove Penalty ─────────────────────────────────────────────────
  Future<void> removePenalty(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/users/$userId/penalty'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal menghapus penalti');
      }
    } catch (e) {
      throw Exception('Gagal menghapus penalti: $e');
    }
  }

  // ─── GET: Zones (used for QR Codes) ─────────────────────────────────────────
  Future<List<dynamic>> getQrCodes() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/zones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['zones'] ?? data['data'] ?? [];
      }
      throw Exception('Failed to load zones');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ─── POST: Generate QR (Creates a Zone) ───────────────────────────────────
  Future<Map<String, dynamic>> generateQrCode(String name, {String deskripsi = '', int kapasitas = 50, String jenisKendaraan = 'motor'}) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/admin/zones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nama_zona': name,
          'deskripsi': deskripsi,
          'kapasitas': kapasitas,
          'jenis_kendaraan': jenisKendaraan,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal membuat zona');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal membuat zona: $e');
    }
  }
}
