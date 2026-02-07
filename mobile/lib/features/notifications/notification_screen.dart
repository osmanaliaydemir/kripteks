import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'providers/notification_provider.dart';
import 'models/notification_model.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Bildirimler',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllAsRead(),
            child: const Text(
              'Tümünü Oku',
              style: TextStyle(color: Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.read(notificationsProvider.notifier).refresh();
        },
        color: const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFF1E293B),
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.white10,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Okunmamış bildirim yok',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildNotificationItem(context, ref, notifications[index]),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Hata: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.Success:
        icon = Icons.check_circle;
        color = const Color(0xFF10B981);
        break;
      case NotificationType.Warning:
        icon = Icons.warning;
        color = const Color(0xFFF59E0B);
        break;
      case NotificationType.Error:
        icon = Icons.error;
        color = const Color(0xFFEF4444);
        break;
      case NotificationType.Trade:
        icon = Icons.currency_exchange;
        color = Colors.blueAccent;
        break;
      case NotificationType.Info:
        icon = Icons.info;
        color = Colors.blueGrey;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: const Color(0xFFEF4444),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(notificationsProvider.notifier).markAsRead(notification.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(notification.createdAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    if (DateTime.now().difference(date).inDays < 1) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd MMM').format(date);
  }
}
