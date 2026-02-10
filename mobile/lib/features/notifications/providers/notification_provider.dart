import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/paged_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/paginated_provider.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationService(dio);
});

/// Sayfalanmış bildirimler provider'ı.
final paginatedNotificationsProvider =
    AsyncNotifierProvider<
      PaginatedNotificationsNotifier,
      PaginatedState<NotificationModel>
    >(PaginatedNotificationsNotifier.new);

/// Okunmamış bildirim sayısı (badge için).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(paginatedNotificationsProvider);
  return notificationsState.asData?.value.items
          .where((n) => !n.isRead)
          .length ??
      0;
});

class PaginatedNotificationsNotifier
    extends PaginatedAsyncNotifier<NotificationModel> {
  @override
  int get pageSize => 20;

  @override
  Future<PagedResult<NotificationModel>> fetchPage(int page, int pageSize) {
    final service = ref.read(notificationServiceProvider);
    return service.getNotifications(page: page, pageSize: pageSize);
  }

  /// SignalR'dan gelen bildirimi listeye ekle.
  void addFromSignalR(Map<String, dynamic> json) {
    try {
      final notification = NotificationModel.fromJson(json);
      final currentState = state.asData?.value;
      if (currentState == null) return;

      // Duplicate kontrolü
      if (currentState.items.any((n) => n.id == notification.id)) return;

      // Yeni bildirimi listenin başına ekle
      state = AsyncData(
        currentState.copyWith(
          items: [notification, ...currentState.items],
          totalCount: currentState.totalCount + 1,
        ),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('🔴 [NotificationProvider] SignalR parse error: $e');
        debugPrint('$stack');
      }
    }
  }

  Future<void> markAsRead(String id) async {
    final service = ref.read(notificationServiceProvider);
    await service.markAsRead(id);

    final currentState = state.asData?.value;
    if (currentState != null) {
      state = AsyncData(
        currentState.copyWith(
          items: currentState.items
              .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
              .toList(),
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final service = ref.read(notificationServiceProvider);
    await service.markAllAsRead();

    final currentState = state.asData?.value;
    if (currentState != null) {
      state = AsyncData(
        currentState.copyWith(
          items: currentState.items
              .map((n) => n.copyWith(isRead: true))
              .toList(),
        ),
      );
    }
  }
}
