import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/login_screen.dart';
import 'package:mobile/features/auth/signup_screen.dart';
import 'package:mobile/features/auth/forgot_password_screen.dart';
import 'package:mobile/features/auth/splash_screen.dart';
import 'package:mobile/features/dashboard/dashboard_screen.dart';
import 'package:mobile/features/bots/bot_detail_screen.dart';
import 'package:mobile/features/bots/screens/bot_create_wizard_screen.dart';
import 'package:mobile/features/scanner/scanner_screen.dart';
import 'package:mobile/features/backtest/backtest_config_screen.dart';
import 'package:mobile/features/wallet/wallet_screen.dart';
import 'package:mobile/features/reports/reports_screen.dart';
import 'package:mobile/features/market_analysis/market_analysis_screen.dart';
import 'package:mobile/features/settings/profile_edit_screen.dart';
import 'package:mobile/features/settings/change_password_screen.dart';
import 'package:mobile/features/settings/notifications_settings_screen.dart';
import 'package:mobile/features/settings/binance_api_keys_screen.dart';
import 'package:mobile/features/tools/calculators_screen.dart';
import 'package:mobile/features/tools/screens/pnl_calculator_screen.dart';
import 'package:mobile/features/tools/screens/position_size_calculator_screen.dart';
import 'package:mobile/features/tools/screens/dca_calculator_screen.dart';
import 'package:mobile/features/tools/market_intelligence_screen.dart';
import 'package:mobile/features/education/screens/academy_screen.dart';
import 'package:mobile/features/education/screens/topic_detail_screen.dart';
import 'package:mobile/features/education/models/education_models.dart';
import 'package:mobile/features/alerts/screens/alerts_screen.dart';

import 'package:mobile/core/network/auth_state_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final isAuthenticated = authAsync.value ?? false;
  final isLoading = authAsync.isLoading;

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: null,
    redirect: (context, state) {
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/';

      // Auth state henüz yüklenmediyse splash'te bekle
      if (isLoading && state.matchedLocation != '/') {
        return '/';
      }

      if (!isAuthenticated && !isAuthRoute) {
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
        path: '/bots/create',
        builder: (context, state) => const BotCreateWizardScreen(),
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
      GoRoute(
        path: '/settings/api-keys',
        builder: (context, state) => const BinanceApiKeysScreen(),
      ),
      GoRoute(
        path: '/calculators',
        builder: (context, state) => const CalculatorsScreen(),
        routes: [
          GoRoute(
            path: 'pnl',
            builder: (context, state) => const PnlCalculatorScreen(),
          ),
          GoRoute(
            path: 'position-size',
            builder: (context, state) => const PositionSizeCalculatorScreen(),
          ),
          GoRoute(
            path: 'dca',
            builder: (context, state) => const DcaCalculatorScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/market-intelligence',
        builder: (context, state) => const MarketIntelligenceScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/academy',
        builder: (context, state) => const AcademyScreen(),
        routes: [
          GoRoute(
            path: 'topic',
            builder: (context, state) {
              final topic = state.extra as EducationTopic;
              return TopicDetailScreen(topic: topic);
            },
          ),
        ],
      ),
    ],
  );
});
