import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/router/app_router.dart';
import '../../features/notifications/services/notification_service.dart';

/// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase initialization is handled automatically
  Logger(
    'FirebaseNotification',
  ).info('Background message received: ${message.messageId}');
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('FirebaseNotificationService');

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize(NotificationService notificationService) async {
    try {
      // Request permission (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _logger.info(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        _logger.info('FCM Token obtained: ${_fcmToken?.substring(0, 20)}...');

        // Register token with backend
        if (_fcmToken != null) {
          await _registerTokenWithBackend(notificationService, _fcmToken!);
        }

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Setup message handlers
        _setupMessageHandlers();

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          _logger.info('FCM Token refreshed');
          _fcmToken = newToken;
          await _registerTokenWithBackend(notificationService, newToken);
        });
      } else {
        _logger.warning('Notification permission denied');
      }
    } catch (e) {
      _logger.severe('Failed to initialize Firebase Messaging: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'kripteks_channel',
      'Kripteks Notifications',
      description: 'Bot alerts and system notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Setup Firebase message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info('Foreground message received: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Background/terminated - notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.info('Notification tapped (background): ${message.messageId}');
      _handleNotificationNavigation(message);
    });

    // Check initial message (app opened from terminated state)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _logger.info('App opened from notification: ${message.messageId}');
        _handleNotificationNavigation(message);
      }
    });
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'kripteks_channel',
            'Kripteks Notifications',
            channelDescription: 'Bot alerts and system notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/launcher_icon',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (e) {
        _logger.severe('Failed to parse notification payload: $e');
      }
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(dynamic source) {
    Map<String, dynamic> data;
    if (source is RemoteMessage) {
      data = source.data;
    } else if (source is Map<String, dynamic>) {
      data = source;
    } else {
      return;
    }

    _logger.info('Handling notification navigation with data: $data');

    final type = data['type'];
    final botId = data['relatedBotId'] ?? data['botId'];

    if (botId != null) {
      _logger.info('Navigating to bot detail: $botId');
      navigatorKey.currentState?.pushNamed('/bots/$botId');
    } else if (type == 'wallet') {
      navigatorKey.currentState?.pushNamed('/wallet');
    } else if (type == 'market') {
      navigatorKey.currentState?.pushNamed('/market-analysis');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(
    NotificationService notificationService,
    String token,
  ) async {
    try {
      await notificationService.registerDeviceToken(
        fcmToken: token,
        deviceType: _getDeviceType(),
      );
      _logger.info('FCM token registered with backend');
    } catch (e) {
      _logger.severe('Failed to register token with backend: $e');
    }
  }

  /// Get device type
  String _getDeviceType() {
    // You can use platform detection here
    // For now, returning a placeholder
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android';
    }
    return 'Unknown';
  }

  /// Unregister device on logout
  Future<void> unregisterDevice(NotificationService notificationService) async {
    if (_fcmToken != null) {
      try {
        await notificationService.unregisterDeviceToken(_fcmToken!);
        await _firebaseMessaging.deleteToken();
        _fcmToken = null;
        _logger.info('Device unregistered and token deleted');
      } catch (e) {
        _logger.severe('Failed to unregister device: $e');
      }
    }
  }
}
