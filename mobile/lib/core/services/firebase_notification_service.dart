import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/router/app_router.dart';
import '../../features/notifications/services/notification_service.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';

/// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger(
    'FirebaseNotification',
  ).info('Background message received: ${message.messageId}');
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal() {
    WidgetsBinding.instance.addObserver(_observer);
  }

  final _LifecycleObserver _observer = _LifecycleObserver();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('FirebaseNotificationService');

  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  bool _isInitialized = false;

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initialize(NotificationService notificationService) async {
    if (_isInitialized) {
      await _checkAndRegisterToken(notificationService);
      return;
    }

    try {
      // Request permission (iOS + Android 13+)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _logger.info(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      // Android 13+ (API 33): Request POST_NOTIFICATIONS permission explicitly
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          final granted =
              await androidPlugin.requestNotificationsPermission() ?? false;
          if (!granted) {
            _logger.warning('Android notification permission denied');
            return;
          }
        }
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Setup message handlers
        _setupMessageHandlers();

        _isInitialized = true;

        // Clear badge on startup
        await clearBadge();

        // Check and register token
        await _checkAndRegisterToken(notificationService);

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          _logger.info('FCM Token refreshed');
          _fcmToken = newToken;
          final deviceModel = await _getDeviceModel();
          final appVersion = await _getAppVersion();
          await _registerTokenWithBackend(
            notificationService,
            newToken,
            deviceModel: deviceModel,
            appVersion: appVersion,
          );
        });
      } else {
        _logger.warning('Notification permission denied');
      }
    } catch (e) {
      _logger.severe('Failed to initialize Firebase Messaging: $e');
    }
  }

  /// iOS'ta APNs token hazır olmadan getToken() hata verir.
  /// Retry mekanizması ile getToken()'ı tekrar deneriz.
  Future<void> _checkAndRegisterToken(
    NotificationService notificationService,
  ) async {
    const maxRetries = 10;
    const retryDelay = Duration(seconds: 3);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        _fcmToken = await _firebaseMessaging.getToken();

        if (_fcmToken != null) {
          _logger.info('FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');

          final deviceModel = await _getDeviceModel();
          final appVersion = await _getAppVersion();

          await _registerTokenWithBackend(
            notificationService,
            _fcmToken!,
            deviceModel: deviceModel,
            appVersion: appVersion,
          );
          return;
        }
      } catch (e) {
        final isApnsError = e.toString().contains('apns-token-not-set');
        if (isApnsError && attempt < maxRetries) {
          _logger.info(
            'APNs token not ready, retrying ($attempt/$maxRetries)...',
          );
          await Future.delayed(retryDelay);
          continue;
        }
        _logger.severe('Failed to get FCM token after $attempt attempts: $e');
        return;
      }
    }
    _logger.warning(
      'FCM token could not be obtained after $maxRetries retries',
    );
  }

  /// Cihaz model bilgisini al
  Future<String?> _getDeviceModel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      }
    } catch (e) {
      _logger.warning('Failed to get device model: $e');
    }
    return null;
  }

  /// Uygulama versiyon bilgisini al
  Future<String?> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      _logger.warning('Failed to get app version: $e');
    }
    return null;
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
    String token, {
    String? deviceModel,
    String? appVersion,
  }) async {
    try {
      await notificationService.registerDeviceToken(
        fcmToken: token,
        deviceType: _getDeviceType(),
        deviceModel: deviceModel,
        appVersion: appVersion,
      );
      _logger.info('FCM token successfully registered with backend');
    } catch (e) {
      _logger.severe('Failed to register token with backend: $e');
    }
  }

  /// Get device type
  String _getDeviceType() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android';
    }
    return 'Unknown';
  }

  /// Clear app badge
  Future<void> clearBadge() async {
    try {
      if (await FlutterAppBadgeControl.isAppBadgeSupported()) {
        FlutterAppBadgeControl.removeBadge();
        _logger.info('App badge cleared');
      }
    } catch (e) {
      _logger.warning('Failed to clear app badge: $e');
    }
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

class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FirebaseNotificationService().clearBadge();
    }
  }
}
