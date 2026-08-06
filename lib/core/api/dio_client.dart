import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class DioClient {
  DioClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.timeout),
      receiveTimeout: Duration(milliseconds: AppConfig.timeout),
      sendTimeout: Duration(milliseconds: AppConfig.timeout),
      headers: const {'Accept': 'application/json'},
    ),
  );

  static Future<void> setAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      dio.options.headers.remove('Authorization');
      return;
    }

    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<void> persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    dio.options.headers.remove('Authorization');
  }
}
