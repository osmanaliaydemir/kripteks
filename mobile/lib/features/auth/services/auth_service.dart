import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/error/error_handler.dart';
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
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> logout(NotificationService notificationService) async {
    // Önce FCM token'ı backend'den kaldır
    try {
      await FirebaseNotificationService().unregisterDevice(notificationService);
    } on DioException catch (e, stack) {
      // Unregister başarısız olsa bile logout devam etmeli,
      // ama hatayı Crashlytics'e raporla
      ErrorHandler.handle(e, stack);
    } catch (e, stack) {
      ErrorHandler.handle(e, stack);
    }

    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> verifyResetCode(String email, String code) async {
    try {
      await _dio.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
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
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
