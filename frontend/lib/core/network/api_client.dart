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
        // 2. Tangani 401 Unauthorized (Token Expired/Invalid)
        if (e.response?.statusCode == 401) {
          await _storage.delete(key: 'auth_token');
          
          // Force Logout: Arahkan ke Login Page
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
          
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: "Sesi telah berakhir. Silakan login kembali.",
          ));
        }
        return handler.next(e);
      },
    ));
  }
}
