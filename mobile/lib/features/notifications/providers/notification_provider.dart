import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationService(dio);
});

// Using a notifier to allow manual refresh and optimistic updates
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final service = ref.read(notificationServiceProvider);
    return service.getUnreadNotifications();
  }

  Future<void> markAsRead(String id) async {
    final service = ref.read(notificationServiceProvider);
    await service.markAsRead(id);

    // Optimistic update
    final previousState = state.asData?.value;
    if (previousState != null) {
      state = AsyncData(previousState.where((n) => n.id != id).toList());
    } else {
      // Refresh if no previous state
      ref.invalidateSelf();
    }
  }

  Future<void> markAllAsRead() async {
    final service = ref.read(notificationServiceProvider);
    await service.markAllAsRead();
    state = const AsyncData([]);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
