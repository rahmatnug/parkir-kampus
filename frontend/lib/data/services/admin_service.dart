import 'dart:convert';
import 'package:http/http.dart' as http;
// No extra imports

import '../../core/config/app_config.dart';

class AdminService {
  String get _baseUrl => '${AppConfig.baseUrl}/api';
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/dashboard'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['users'] ?? [];
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/activities'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['activities'] ?? [];
      } else {
        throw Exception('Failed to load activities');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
