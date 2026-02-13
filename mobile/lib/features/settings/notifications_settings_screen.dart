import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/settings_provider.dart';
import 'models/settings_model.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: AppLocalizations.of(context)!.notificationSettings,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // Modern Background Glow
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

          SafeArea(
            child: settingsAsync.when(
              data: (settings) => _buildContent(context, ref, settings),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ayarlar yüklenemedi',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(notificationSettingsProvider),
                      child: const Text('Tekrar Dene'),
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Modern Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.notificationsInfo,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Push Notifications Section
        _buildSection(context, 'Push Bildirimleri', [
          _buildSwitchTile(
            context,
            ref,
            icon: Icons.notifications_active_rounded,
            title: 'Push Bildirimleri',
            subtitle: 'Anlık bildirimler alın',
            value: settings.enablePushNotifications,
            onChanged: (val) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleSetting('enablePushNotifications', val);
            },
          ),
        ]),
        const SizedBox(height: 32),

        // Bot Notifications
        _buildSection(context, AppLocalizations.of(context)!.botNotifications, [
          _buildSwitchTile(
            context,
            ref,
            icon: Icons.trending_up_rounded,
            title: AppLocalizations.of(context)!.buySignals,
            subtitle: AppLocalizations.of(context)!.buySignalsSubtitle,
            value: settings.notifyBuySignals,
            onChanged: (val) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleSetting('notifyBuySignals', val);
            },
          ),
          _buildSwitchTile(
            context,
            ref,
            icon: Icons.trending_down_rounded,
            title: AppLocalizations.of(context)!.sellSignals,
            subtitle: AppLocalizations.of(context)!.sellSignalsSubtitle,
            value: settings.notifySellSignals,
            onChanged: (val) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleSetting('notifySellSignals', val);
            },
          ),
          _buildSwitchTile(
            context,
            ref,
            icon: Icons.warning_amber_rounded,
            title: AppLocalizations.of(context)!.stopLoss,
            subtitle: AppLocalizations.of(context)!.stopLossSubtitle,
            value: settings.notifyStopLoss,
            onChanged: (val) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleSetting('notifyStopLoss', val);
            },
          ),
          _buildSwitchTile(
            context,
            ref,
            icon: Icons.check_circle_outline_rounded,
            title: AppLocalizations.of(context)!.takeProfit,
            subtitle: AppLocalizations.of(context)!.takeProfitSubtitle,
            value: settings.notifyTakeProfit,
            onChanged: (val) {
              ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleSetting('notifyTakeProfit', val);
            },
          ),
        ]),
        const SizedBox(height: 32),

        _buildSection(
          context,
          AppLocalizations.of(context)!.systemNotifications,
          [
            _buildSwitchTile(
              context,
              ref,
              icon: Icons.notifications_active_rounded,
              title: AppLocalizations.of(context)!.generalNotifications,
              subtitle: AppLocalizations.of(
                context,
              )!.generalNotificationsSubtitle,
              value: settings.notifyGeneral,
              onChanged: (val) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('notifyGeneral', val);
              },
            ),
            _buildSwitchTile(
              context,
              ref,
              icon: Icons.error_outline_rounded,
              title: AppLocalizations.of(context)!.errorNotifications,
              subtitle: AppLocalizations.of(
                context,
              )!.errorNotificationsSubtitle,
              value: settings.notifyErrors,
              onChanged: (val) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSetting('notifyErrors', val);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: List.generate(children.length, (index) {
              return Column(
                children: [
                  children[index],
                  if (index < children.length - 1)
                    Divider(
                      color: Colors.white.withValues(alpha: 0.05),
                      height: 1,
                      indent: 64,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
