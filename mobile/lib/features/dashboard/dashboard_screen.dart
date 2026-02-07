import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/features/dashboard/dashboard_panel.dart';
import 'package:mobile/features/bots/bot_list_screen.dart';
import 'package:mobile/features/scanner/scanner_screen.dart';
import 'package:mobile/features/backtest/backtest_config_screen.dart';
import 'package:mobile/features/settings/settings_screen.dart';
// ignore: unused_import
import 'package:mobile/features/wallet/wallet_screen.dart';
import 'package:mobile/features/notifications/notification_screen.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';
import 'package:mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:mobile/core/network/signalr_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize SignalR connection once when Dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signalRServiceProvider).initConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DashboardPanel(),
          const BotListScreen(),
          const ScannerScreen(),
          const BacktestConfigScreen(),
          const SettingsScreen(),
        ],
      ),
      appBar: _currentIndex == 0 ? _buildDashboardAppBar() : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Botlar'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Tarayıcı'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Backtest'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  PreferredSizeWidget _buildDashboardAppBar() {
    final signalRStatus = ref.watch(signalRStatusProvider);

    return AppBar(
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          const Icon(
            Icons
                .candlestick_chart_rounded, // Using candlestick icon as in screenshot
            color: Color(0xFFF59E0B),
            size: 28,
          ),
          const SizedBox(width: 12),
          // Text
          Text(
            'KRIPTEKS',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800, // Extra bold
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      actions: [
        // Online Badge
        _buildConnectionStatus(signalRStatus.value),
        const SizedBox(width: 12),

        // Bildirim Zili
        Consumer(
          builder: (context, ref, child) {
            final notificationsAsync = ref.watch(notificationsProvider);
            final unreadCount =
                notificationsAsync.asData?.value
                    .where((n) => !n.isRead)
                    .length ??
                0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildConnectionStatus(SignalRConnectionStatus? status) {
    Color color;
    String text;

    switch (status) {
      case SignalRConnectionStatus.connected:
        color = const Color(0xFF10B981); // Green
        text = 'Çevrimiçi';
        break;
      case SignalRConnectionStatus.connecting:
      case SignalRConnectionStatus.reconnecting:
        color = const Color(0xFFF59E0B); // Amber
        text = 'Bağlanıyor';
        break;
      default:
        color = const Color(0xFFEF4444); // Red
        text = 'Bağlantı Yok';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
