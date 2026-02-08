import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/login_screen.dart';
import 'package:mobile/features/auth/signup_screen.dart';
import 'package:mobile/features/auth/forgot_password_screen.dart';
import 'package:mobile/features/auth/splash_screen.dart';
import 'package:mobile/features/dashboard/dashboard_screen.dart';
import 'package:mobile/features/bots/bot_detail_screen.dart';
import 'package:mobile/features/scanner/scanner_screen.dart';
import 'package:mobile/features/backtest/backtest_config_screen.dart';
import 'package:mobile/features/wallet/wallet_screen.dart';
import 'package:mobile/features/reports/reports_screen.dart';
import 'package:mobile/features/market_analysis/market_analysis_screen.dart';
import 'package:mobile/features/settings/profile_edit_screen.dart';
import 'package:mobile/features/settings/change_password_screen.dart';
import 'package:mobile/features/settings/notifications_settings_screen.dart';

import 'package:mobile/core/network/auth_state_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: null, // We handle redirection via build-level watch
    redirect: (context, state) {
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/';

      if (!authState && !isLoggingIn) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/bots/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BotDetailScreen(botId: id);
        },
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/simulation',
        builder: (context, state) => const BacktestConfigScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/market-analysis',
        builder: (context, state) => const MarketAnalysisScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/settings/profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/settings/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationsSettingsScreen(),
      ),
    ],
  );
});
