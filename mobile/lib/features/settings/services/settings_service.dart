import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import '../models/settings_model.dart';

class SettingsService {
  final Dio _dio;

  SettingsService(this._dio);

  Future<ApiKeyStatus> getApiKeys() async {
    try {
      final response = await _dio.get('/settings/keys');
      return ApiKeyStatus.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> saveApiKeys(String apiKey, String secretKey) async {
    try {
      await _dio.post(
        '/settings/keys',
        data: {'apiKey': apiKey, 'secretKey': secretKey},
      );
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<SystemSetting> getSystemSettings() async {
    try {
      final response = await _dio.get('/settings/general');
      return SystemSetting.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> saveSystemSettings(SystemSetting settings) async {
    try {
      await _dio.post('/settings/general', data: settings.toJson());
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final response = await _dio.get('/settings/notifications');
      return NotificationSettings.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      await _dio.put('/settings/notifications', data: settings.toJson());
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post('/settings/fcm-token', data: {'fcmToken': token});
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
