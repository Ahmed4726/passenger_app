import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../models/app_user.dart';

class AuthService {
  Future<AppUser?> login({required String email, required String password}) async {
    final response = await DioClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final payload = response.data['data'];
    final token = payload['token']?.toString() ?? '';
    final user = AppUser.fromJson(Map<String, dynamic>.from(payload['user'] ?? {}), token: token);

    await DioClient.persistToken(token);
    await DioClient.setAuthToken(token);
    return user;
  }

  Future<void> logout() async {
    try {
      await DioClient.dio.post('/logout');
    } on DioException {
      // ignore
    }
    await DioClient.clearSession();
  }
}
