import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/dashboard/dashboard_panel.dart';
import 'package:mobile/features/bots/bot_list_screen.dart';
import 'package:mobile/features/settings/settings_screen.dart';
import 'package:mobile/features/tools/tools_screen.dart';
import 'package:mobile/features/wallet/wallet_screen.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';

import 'package:mobile/core/providers/signalr_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final signalR = ref.read(signalRServiceProvider);
      await signalR.initConnection();

      // SignalR bağlantısı kurulduktan sonra notification listener'ı register et
      signalR.onNotification((data) {
        if (!mounted) return;
        final notifier = ref.read(paginatedNotificationsProvider.notifier);
        if (data is Map<String, dynamic>) {
          notifier.addFromSignalR(data);
        } else if (data is Map) {
          notifier.addFromSignalR(Map<String, dynamic>.from(data));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Dark base
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary.withValues(alpha: 0.5),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: [
            _buildNavItem(
              Icons.dashboard_rounded,
              AppLocalizations.of(context)!.dashboard,
              0,
            ),
            _buildNavItem(
              Icons.smart_toy_rounded,
              AppLocalizations.of(context)!.bots,
              1,
            ),
            _buildNavItem(
              Icons.grid_view_rounded,
              AppLocalizations.of(context)!.tools,
              2,
            ),
            _buildNavItem(
              Icons.account_balance_wallet_rounded,
              AppLocalizations.of(context)!.wallet,
              3,
            ),
            _buildNavItem(
              Icons.settings_rounded,
              AppLocalizations.of(context)!.settings,
              4,
            ),
          ],
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: isSelected ? 26 : 22),
      ),
      label: label,
    );
  }
}
