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

/// Filtre seçenekleri
enum NotificationFilter {
  all('Tümü'),
  trade('İşlemler'),
  system('Sistem'),
  security('Güvenlik'),
  news('Haberler');

  final String label;
  const NotificationFilter(this.label);
}

/// Seçili filtre state'i
/// Seçili filtre state'i
class NotificationFilterNotifier extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() {
    return NotificationFilter.all;
  }

  void setFilter(NotificationFilter filter) {
    state = filter;
  }
}

final notificationFilterProvider =
    NotifierProvider<NotificationFilterNotifier, NotificationFilter>(
      NotificationFilterNotifier.new,
    );

/// Filtrelenmiş bildirim listesi (Backend-side filtering olduğu için doğrudan listeyi döner)
final filteredNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notificationsState = ref.watch(paginatedNotificationsProvider);
  return notificationsState.asData?.value.items ?? [];
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
  Future<PaginatedState<NotificationModel>> build() async {
    // Filtre değiştiğinde otomatik yenilenmesi için izle
    ref.watch(notificationFilterProvider);
    return super.build();
  }

  @override
  int get pageSize => 20;

  @override
  Future<PagedResult<NotificationModel>> fetchPage(int page, int pageSize) {
    final service = ref.read(notificationServiceProvider);
    final filter = ref.read(notificationFilterProvider);

    NotificationType? type;
    switch (filter) {
      case NotificationFilter.trade:
        type = NotificationType.Trade;
        break;
      case NotificationFilter.security:
        type = NotificationType.Warning;
        break;
      case NotificationFilter.news:
        type = NotificationType.Info;
        break;
      case NotificationFilter.system:
        // System kategorisi için şimdilik Success tipini baz alıyoruz
        // Backend çoklu tip desteklerse burayı güncelleyebiliriz
        type = NotificationType.Success;
        break;
      default:
        type = null;
    }

    return service.getNotifications(page: page, pageSize: pageSize, type: type);
  }

  /// SignalR'dan gelen bildirimi listeye ekle.
  void addFromSignalR(Map<String, dynamic> json) {
    try {
      final notification = NotificationModel.fromJson(json);
      final currentState = state.asData?.value;
      if (currentState == null) return;

      final filter = ref.read(notificationFilterProvider);

      // Mevcut filtreye uygun mu kontrol et
      bool matchesFilter = true;
      if (filter != NotificationFilter.all) {
        if (filter == NotificationFilter.trade &&
            notification.type != NotificationType.Trade) {
          matchesFilter = false;
        }
        if (filter == NotificationFilter.security &&
            notification.type != NotificationType.Warning) {
          matchesFilter = false;
        }
        if (filter == NotificationFilter.news &&
            notification.type != NotificationType.Info) {
          matchesFilter = false;
        }
        if (filter == NotificationFilter.system &&
            notification.type != NotificationType.Success &&
            notification.type != NotificationType.Error) {
          matchesFilter = false;
        }
      }

      if (!matchesFilter) return;

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
