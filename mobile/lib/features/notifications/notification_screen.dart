import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/providers/firebase_notification_provider.dart';
import 'providers/notification_provider.dart';
import 'models/notification_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Clear app icon badge when viewing notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firebaseNotificationServiceProvider).clearBadge();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      ref.read(paginatedNotificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(paginatedNotificationsProvider);
    final filteredNotifications = ref.watch(filteredNotificationsProvider);
    final selectedFilter = ref.watch(notificationFilterProvider);
    final hasUnread =
        notificationsAsync.asData?.value.items.any((n) => !n.isRead) ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: 'Bildirimler',
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () {
                ref
                    .read(paginatedNotificationsProvider.notifier)
                    .markAllAsRead();
                ref.read(firebaseNotificationServiceProvider).clearBadge();
              },
              child: Text(
                'Tümünü Oku',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.8,
                  colors: [AppColors.primaryTransparent, Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Filter Chips
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: NotificationFilter.values.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = NotificationFilter.values[index];
                      final isSelected = filter == selectedFilter;
                      return _buildFilterChip(filter, isSelected);
                    },
                  ),
                ),

                // Notifications List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref
                        .read(paginatedNotificationsProvider.notifier)
                        .refresh(),
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    child: notificationsAsync.when(
                      data: (paginatedState) {
                        if (filteredNotifications.isEmpty &&
                            !paginatedState.isLoadingMore) {
                          // Eğer filtre seçili ve boşsa ama genel liste doluysa, filtreye uyan yok demektir.
                          // Ama ana liste de boşsa hiç bildirim yok demektir.
                          final bool isCleanEmpty =
                              paginatedState.items.isEmpty &&
                              selectedFilter == NotificationFilter.all;

                          return ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isCleanEmpty
                                            ? Icons.notifications_none_outlined
                                            : Icons.filter_list_off_outlined,
                                        size: 64,
                                        color: AppColors.textDisabled,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        isCleanEmpty
                                            ? 'Bildirim bulunmuyor'
                                            : '${selectedFilter.label} kategorisinde bildirim yok',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 32,
                            left: 16,
                            right: 16,
                          ),
                          itemCount:
                              filteredNotifications.length +
                              (paginatedState.isLoadingMore ||
                                      !paginatedState.hasMore
                                  ? 1
                                  : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= filteredNotifications.length) {
                              if (paginatedState.isLoadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              // Filtreli görünümde "Hepsi yüklendi" demek biraz kafa karıştırıcı olabilir
                              // ama teknik olarak doğru.
                              return const SizedBox(height: 16);
                            }
                            return _buildNotificationTile(
                              context,
                              ref,
                              filteredNotifications[index],
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Hata: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(NotificationFilter filter, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(notificationFilterProvider.notifier).setFilter(filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.white05,
          ),
        ),
        child: Text(
          filter.label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.Trade:
        icon = Icons.swap_horiz_rounded;
        color = AppColors.success;
        break;
      case NotificationType.Info:
        icon = Icons.info_outline;
        color = AppColors.info;
        break;
      case NotificationType.Warning:
        icon = Icons.warning_amber_outlined;
        color = AppColors.primary;
        break;
      case NotificationType.Error:
        icon = Icons.error_outline;
        color = AppColors.error;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref
              .read(paginatedNotificationsProvider.notifier)
              .markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.white05
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            DateFormat('HH:mm').format(notification.createdAt),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textDisabled,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
