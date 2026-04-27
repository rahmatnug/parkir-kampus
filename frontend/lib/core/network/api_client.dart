import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

// Global navigator key agar interceptor bisa melakukan navigasi logout
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiClient {
  late Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 1. Sisipkan Token ke Header secara otomatis
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final statusCode = e.response?.statusCode;
        final context = navigatorKey.currentContext;

        if (statusCode == 401) {
          await _storage.delete(key: 'auth_token');
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: "Sesi telah berakhir. Silakan login kembali.",
          ));
        }

        if (statusCode == 409 && context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sistem sedang sibuk memproses antrean. Silakan coba Tap-In lagi dalam 3 detik.")),
          );
        }

        if (statusCode == 504 && context != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Koneksi Timeout"),
              content: const Text("Gangguan koneksi ke Gerbang Parkir. Hubungi Satpam."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
              ],
            ),
          );
        }

        if (statusCode == 403 && context != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Akses Ditolak"),
              content: const Text("Anda tidak memiliki izin."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
              ],
            ),
          );
        }

        return handler.next(e);
      },
    ));
  }
}
