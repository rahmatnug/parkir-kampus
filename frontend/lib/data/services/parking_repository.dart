import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/parking_zone.dart';

class ParkingRepository {
  final ApiClient _apiClient = ApiClient();

  /// Mengambil status okupansi dari Backend Golang
  Future<List<ParkingZone>> getParkingStatus() async {
    try {
      final response = await _apiClient.dio.get('/api/v1/parking/status');
      
      if (response.statusCode == 200) {
        final List data = response.data['data']; // Asumsi response: {"data": [...]}
        return data.map((e) => ParkingZone.fromJson(e)).toList();
      } else {
        throw Exception("Gagal mengambil data status parkir.");
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Koneksi ke server bermasalah.");
    }
  }

  /// Contoh POST request (Misal: Tap-In via QR)
  Future<bool> tapIn(String userId, String qrData) async {
    try {
      await _apiClient.dio.post('/api/v1/parking/tap-in', data: {
        'user_id': userId,
        'qr_data': qrData,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
