import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/services/firebase_notification_service.dart';
import 'package:mobile/features/notifications/services/notification_service.dart';

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
        }
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?.toString() ?? 'Giriş başarısız');
      }
      rethrow;
    }
  }

  Future<void> logout(NotificationService notificationService) async {
    // Önce FCM token'ı backend'den kaldır
    try {
      await FirebaseNotificationService().unregisterDevice(notificationService);
    } catch (_) {
      // Unregister başarısız olsa bile logout devam etmeli
    }

    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['message'] ?? 'İşlem başarısız');
      }
      rethrow;
    }
  }

  Future<void> verifyResetCode(String email, String code) async {
    try {
      await _dio.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['message'] ?? 'Kod doğrulanamadı');
      }
      rethrow;
    }
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['message'] ?? 'Şifre sıfırlanamadı');
      }
      rethrow;
    }
  }
}
