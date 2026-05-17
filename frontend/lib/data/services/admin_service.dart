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
  }

  // ─── PUT: Update user role ────────────────────────────────────────────────
  Future<void> updateUserRole(int userId, String newRole) async {
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
      throw Exception(body['message'] ?? 'Gagal mengubah role');
    }
  }

  // ─── GET: Blacklisted users (poin > 50) ───────────────────────────────────
  Future<List<dynamic>> getBlacklist() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/blacklist'),
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
  // ─── POST: Force Exit Activity ────────────────────────────────────────────
  Future<void> forceExitActivity(int activityId) async {
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
  }

  // ─── POST: Add Penalty ────────────────────────────────────────────────────
  Future<void> addPenalty(int userId, int poin, String keterangan) async {
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
  }

  // ─── DELETE: Remove Penalty ─────────────────────────────────────────────────
  Future<void> removePenalty(int userId) async {
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
  }
}
