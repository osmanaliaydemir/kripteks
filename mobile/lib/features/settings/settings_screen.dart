import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/auth/biometric_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/settings/services/profile_service.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiStatusAsync = ref.watch(apiKeyStatusProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: AppLocalizations.of(context)!.settings,
        showBackButton: false,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildSectionHeader(AppLocalizations.of(context)!.profile),
                  profileAsync.when(
                    data: (profile) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.white10),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/settings/profile-edit'),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    '${profile.firstName.isNotEmpty ? profile.firstName[0] : ''}${profile.lastName.isNotEmpty ? profile.lastName[0] : ''}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${profile.firstName} ${profile.lastName}',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.email,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    loading: () => _buildLoadingCard(),
                    error: (err, stack) => _buildErrorCard(context, err),
                  ),
                  const SizedBox(height: 32),

                  // API Keys Section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.exchangeConnection,
                  ),
                  apiStatusAsync.when(
                    data: (status) => _buildApiKeyCard(context, ref, status),
                    loading: () => _buildLoadingCard(),
                    error: (err, stack) => _buildErrorCard(context, err),
                  ),
                  const SizedBox(height: 32),

                  // App Settings
                  _buildSectionHeader(AppLocalizations.of(context)!.app),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.white10),
                    ),
                    child: Column(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final biometricState = ref.watch(
                              biometricStateProvider,
                            );
                            return biometricState.when(
                              data: (state) {
                                if (!state.isSupported) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    _buildSwitchTile(
                                      context,
                                      icon: Icons.fingerprint_rounded,
                                      title: AppLocalizations.of(
                                        context,
                                      )!.biometricLogin,
                                      subtitle: AppLocalizations.of(
                                        context,
                                      )!.biometricLoginSubtitle,
                                      value: state.isEnabled,
                                      onChanged: (value) async {
                                        await ref
                                            .read(biometricServiceProvider)
                                            .setBiometricEnabled(value);
                                        ref.invalidate(biometricStateProvider);
                                      },
                                    ),
                                    const Divider(
                                      color: AppColors.white05,
                                      height: 1,
                                      indent: 64,
                                    ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        _buildListTile(
                          icon: Icons.notifications_none_rounded,
                          title: AppLocalizations.of(context)!.notifications,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.notificationsSubtitle,
                          onTap: () => context.push('/settings/notifications'),
                        ),
                        const Divider(
                          color: AppColors.white05,
                          height: 1,
                          indent: 64,
                        ),
                        _buildListTile(
                          icon: Icons.lock_outline_rounded,
                          title: AppLocalizations.of(context)!.updatePassword,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.updatePasswordSubtitle,
                          onTap: () =>
                              context.push('/settings/change-password'),
                        ),
                        const Divider(
                          color: AppColors.white05,
                          height: 1,
                          indent: 64,
                        ),
                        _buildListTile(
                          icon: Icons.logout_rounded,
                          title: AppLocalizations.of(context)!.logout,
                          color: AppColors.error,
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  AppLocalizations.of(context)!.logout,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                content: Text(
                                  'Hesaptan çıkış yapmak istediğinize emin misiniz?',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Çıkış',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
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
    );
  }

  Widget _buildApiKeyCard(BuildContext context, WidgetRef ref, dynamic status) {
    final bool isConnected = status.hasKeys;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
      ),
      child: InkWell(
        onTap: () => context.push('/settings/api-keys'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.binance.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.currency_bitcoin_rounded,
                  color: AppColors.binance,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Binance Global',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? '${AppLocalizations.of(context)!.connected} (${status.apiKey.substring(0, 4)}***)'
                          : AppLocalizations.of(context)!.notConnected,
                      style: GoogleFonts.plusJakartaSans(
                        color: isConnected
                            ? AppColors.success
                            : AppColors.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_input_component_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textDisabled,
        size: 20,
      ),
      onTap: onTap,
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

  Widget _buildLoadingCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, Object err) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        '${AppLocalizations.of(context)!.profileLoadError}: $err',
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
