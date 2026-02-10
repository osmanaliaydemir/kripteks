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
    return service.getNotifications();
  }

  Future<void> markAsRead(String id) async {
    final service = ref.read(notificationServiceProvider);
    await service.markAsRead(id);

    // Optimistic update: isRead = true yap, listeden silme
    final previousState = state.asData?.value;
    if (previousState != null) {
      state = AsyncData(
        previousState
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final service = ref.read(notificationServiceProvider);
    await service.markAllAsRead();

    // Optimistic update: tüm bildirimleri okundu yap
    final previousState = state.asData?.value;
    if (previousState != null) {
      state = AsyncData(
        previousState.map((n) => n.copyWith(isRead: true)).toList(),
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
