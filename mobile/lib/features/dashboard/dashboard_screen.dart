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
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

          // Custom Floating Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24, // Ekranın altından boşluk
            child: Container(
              height: 70, // Sabit yükseklik
              decoration: BoxDecoration(
                color: const Color(
                  0xFF1E293B,
                ).withValues(alpha: 0.9), // Koyu, yarı saydam arka plan
                borderRadius: BorderRadius.circular(24), // Oval köşeler
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), // İnce border
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              )
              .animate(target: isSelected ? 1 : 0)
              .scaleXY(end: 1.1, duration: 200.ms),
        ],
      ),
    );
  }
}
