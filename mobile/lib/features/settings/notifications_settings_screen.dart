import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: AppLocalizations.of(context)!.notificationSettings,
        showBackButton: true,
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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.notificationsInfo,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Notification Settings
                _buildSection(AppLocalizations.of(context)!.botNotifications, [
                  _buildSwitchTile(
                    context,
                    icon: Icons.trending_up_rounded,
                    title: AppLocalizations.of(context)!.buySignals,
                    subtitle: AppLocalizations.of(context)!.buySignalsSubtitle,
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildSwitchTile(
                    context,
                    icon: Icons.trending_down_rounded,
                    title: AppLocalizations.of(context)!.sellSignals,
                    subtitle: AppLocalizations.of(context)!.sellSignalsSubtitle,
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildSwitchTile(
                    context,
                    icon: Icons.warning_amber_rounded,
                    title: AppLocalizations.of(context)!.stopLoss,
                    subtitle: AppLocalizations.of(context)!.stopLossSubtitle,
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildSwitchTile(
                    context,
                    icon: Icons.check_circle_outline_rounded,
                    title: AppLocalizations.of(context)!.takeProfit,
                    subtitle: AppLocalizations.of(context)!.takeProfitSubtitle,
                    value: true,
                    onChanged: (value) {},
                  ),
                ]),
                const SizedBox(height: 32),

                _buildSection(
                  AppLocalizations.of(context)!.systemNotifications,
                  [
                    _buildSwitchTile(
                      context,
                      icon: Icons.notifications_active_rounded,
                      title: AppLocalizations.of(context)!.generalNotifications,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.generalNotificationsSubtitle,
                      value: true,
                      onChanged: (value) {},
                    ),
                    _buildSwitchTile(
                      context,
                      icon: Icons.error_outline_rounded,
                      title: AppLocalizations.of(context)!.errorNotifications,
                      subtitle: AppLocalizations.of(
                        context,
                      )!.errorNotificationsSubtitle,
                      value: true,
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white10),
          ),
          child: Column(
            children: List.generate(children.length, (index) {
              return Column(
                children: [
                  children[index],
                  if (index < children.length - 1)
                    const Divider(
                      color: AppColors.white05,
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
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.success,
        activeTrackColor: AppColors.success.withValues(alpha: 0.2),
        inactiveThumbColor: AppColors.textDisabled,
        inactiveTrackColor: AppColors.white05,
      ),
    );
  }
}
