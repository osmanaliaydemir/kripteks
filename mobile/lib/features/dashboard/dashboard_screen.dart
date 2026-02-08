import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';

import 'package:mobile/features/dashboard/dashboard_panel.dart';
import 'package:mobile/features/bots/bot_list_screen.dart';
import 'package:mobile/features/settings/settings_screen.dart';
import 'package:mobile/features/tools/tools_screen.dart';
import 'package:mobile/features/wallet/wallet_screen.dart';
import 'package:mobile/features/notifications/notification_screen.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';

import 'package:mobile/core/network/signalr_service.dart';
import 'package:mobile/core/widgets/app_header.dart';
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
    // Initialize SignalR connection once when Dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signalRServiceProvider).initConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Dark base
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
                    AppColors.primaryTransparent, // Amber with transparency
                    AppColors.transparent,
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
        backgroundColor: AppColors.surface.withValues(
          alpha: 0.8,
        ), // Slightly transparent
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: AppLocalizations.of(context)!.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy),
            label: AppLocalizations.of(context)!.bots,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_rounded),
            label: AppLocalizations.of(context)!.tools,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: AppLocalizations.of(context)!.wallet,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
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
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'KRIPTEKS',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
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
                    color: AppColors.textPrimary,
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
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
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
    final signalRService = ref.read(signalRServiceProvider);

    return InkWell(
      onTap: () {
        _showStatusBottomSheet(context, status, signalRService.lastError);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isOnline
                  ? AppLocalizations.of(context)!.online
                  : AppLocalizations.of(context)!.offline,
              style: TextStyle(
                color: isOnline ? AppColors.success : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusBottomSheet(
    BuildContext context,
    SignalRConnectionStatus status,
    String? lastError,
  ) {
    bool isOnline = status == SignalRConnectionStatus.connected;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                isOnline ? Icons.check_circle_rounded : Icons.error_rounded,
                color: isOnline ? AppColors.success : AppColors.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                isOnline ? l10n.online : l10n.offline,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOnline
                    ? 'Sistem aktif çalışıyor ve gerçek zamanlı veriler alınıyor.'
                    : 'Sunucu bağlantısı koptu. Veriler güncellenemiyor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isOnline && lastError != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.bug_report_outlined,
                            size: 16,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hata Detayı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lastError,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!isOnline) {
                      ref.read(signalRServiceProvider).initConnection();
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline
                        ? AppColors.primary
                        : AppColors.error,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isOnline ? 'Kapat' : 'Tekrar Bağlanmayı Dene'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
