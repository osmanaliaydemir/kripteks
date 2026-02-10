import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/firebase_notification_service.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';

final firebaseNotificationServiceProvider =
    Provider<FirebaseNotificationService>((ref) {
      final service = FirebaseNotificationService();
      final notificationService = ref.read(notificationServiceProvider);

      // Initialize the service
      service.initialize(notificationService);

      return service;
    });
