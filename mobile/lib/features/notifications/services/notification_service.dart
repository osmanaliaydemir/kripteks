import 'package:dio/dio.dart';
import '../../notifications/models/notification_model.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      final List<dynamic> data = response.data;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.put('/notifications/$id/read');
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  Future<void> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    String? deviceModel,
    String? appVersion,
  }) async {
    try {
      await _dio.post(
        '/devices/register',
        data: {
          'fcmToken': fcmToken,
          'deviceType': deviceType,
          'deviceModel': deviceModel,
          'appVersion': appVersion,
        },
      );
    } catch (e) {
      throw Exception('Failed to register device token: $e');
    }
  }

  Future<void> unregisterDeviceToken(String fcmToken) async {
    try {
      await _dio.delete('/devices/$fcmToken');
    } catch (e) {
      throw Exception('Failed to unregister device token: $e');
    }
  }
}
