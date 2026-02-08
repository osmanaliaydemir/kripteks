import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/notification_provider.dart';
import 'models/notification_model.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: 'Bildirimler',
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllAsRead(),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.read(notificationsProvider.notifier).refresh(),
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: notificationsAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none_outlined,
                                    size: 64,
                                    color: AppColors.textDisabled,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Bildirim bulunmuyor',
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
                      padding: const EdgeInsets.only(top: 16, bottom: 32),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildNotificationTile(
                        context,
                        ref,
                        notifications[index],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
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
          ),
        ],
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

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(notificationsProvider.notifier).markAsRead(notification.id);
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
                      Text(
                        DateFormat('HH:mm').format(notification.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
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
