import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthService(this._dio, this._storage);

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];

        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
          // Optionally store user data
          // await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
        }
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?.toString() ?? 'Giriş başarısız');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
