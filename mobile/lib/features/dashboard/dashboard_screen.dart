import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/features/dashboard/dashboard_panel.dart';
import 'package:mobile/features/bots/bot_list_screen.dart';
import 'package:mobile/features/settings/settings_screen.dart';
import 'package:mobile/features/tools/tools_screen.dart';
import 'package:mobile/features/wallet/wallet_screen.dart';
import 'package:mobile/features/notifications/notification_screen.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';
import 'package:mobile/features/dashboard/providers/dashboard_provider.dart';
import 'package:mobile/core/network/signalr_service.dart';
import 'package:mobile/core/widgets/app_header.dart';

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
      backgroundColor: Colors.black, // Dark base
      body: Stack(
        children: [
          // Background Gradient (Same as Login)
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
                  colors: [
                    Color(0x40F59E0B), // Amber with transparency
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Content
          IndexedStack(
            index: _currentIndex,
            children: const [
              DashboardPanel(),
              BotListScreen(),
              ToolsScreen(),
              WalletScreen(),
              SettingsScreen(),
            ],
          ),
        ],
      ),
      appBar: _currentIndex == 0 ? _buildDashboardAppBar() : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(
          0xFF0F172A,
        ).withValues(alpha: 0.8), // Slightly transparent
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Botlar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Araçlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Cüzdanım',
          ),
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

    return AppHeader(
      showBackButton: false,
      centerTitle: false,
      titleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.candlestick_chart_rounded,
            color: Color(0xFFF59E0B),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'KRIPTEKS',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      actions: [
        _buildConnectionStatus(
          signalRStatus.value ?? SignalRConnectionStatus.disconnected,
        ),
        const SizedBox(width: 12),
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
      ],
    );
  }

  Widget _buildConnectionStatus(SignalRConnectionStatus status) {
    bool isOnline = status == SignalRConnectionStatus.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF10B981).withValues(alpha: 0.2)
              : const Color(0xFFEF4444).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
            style: TextStyle(
              color: isOnline
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
