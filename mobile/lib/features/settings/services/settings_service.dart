import 'package:dio/dio.dart';
import '../models/settings_model.dart';

class SettingsService {
  final Dio _dio;

  SettingsService(this._dio);

  Future<ApiKeyStatus> getApiKeys() async {
    try {
      final response = await _dio.get('/settings/keys');
      return ApiKeyStatus.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch API keys status: $e');
    }
  }

  Future<void> saveApiKeys(String apiKey, String secretKey) async {
    try {
      await _dio.post(
        '/settings/keys',
        data: {'apiKey': apiKey, 'secretKey': secretKey},
      );
    } catch (e) {
      throw Exception('Failed to save API keys: $e');
    }
  }

  Future<SystemSetting> getSystemSettings() async {
    try {
      final response = await _dio.get('/settings/general');
      return SystemSetting.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch system settings: $e');
    }
  }

  Future<void> saveSystemSettings(SystemSetting settings) async {
    try {
      await _dio.post('/settings/general', data: settings.toJson());
    } catch (e) {
      throw Exception('Failed to save system settings: $e');
    }
  }

  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final response = await _dio.get('/settings/notifications');
      return NotificationSettings.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch notification settings: $e');
    }
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      await _dio.put('/settings/notifications', data: settings.toJson());
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post('/settings/fcm-token', data: {'fcmToken': token});
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }
}
