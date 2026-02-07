import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/login_screen.dart';
import 'package:mobile/features/auth/splash_screen.dart';
import 'package:mobile/features/dashboard/dashboard_screen.dart';
import 'package:mobile/features/bots/bot_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
    ],
  );
});
