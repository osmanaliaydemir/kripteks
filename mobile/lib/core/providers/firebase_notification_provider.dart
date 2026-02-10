import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/auth_state_provider.dart';
import 'package:mobile/core/services/firebase_notification_service.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';

final firebaseNotificationServiceProvider = Provider<FirebaseNotificationService>((
  ref,
) {
  final service = FirebaseNotificationService();
  final notificationService = ref.read(notificationServiceProvider);
  final isAuth = ref.watch(authStateProvider);

  // Initialize the service if authorized.
  // Note: initialize() handles internally if it's already initialized if we modify it,
  // or we just call it once and it registers if token is available.
  if (isAuth) {
    service.initialize(notificationService);
  }

  return service;
});
