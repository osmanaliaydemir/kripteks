import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/auth_state_provider.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/dashboard/models/dashboard_stats.dart';
import 'package:mobile/features/dashboard/services/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final dio = ref.watch(dioProvider);
  return AnalyticsService(dio);
});

final dashboardStatsProvider = StreamProvider.autoDispose<DashboardStats>((
  ref,
) async* {
  // Kullanıcı giriş yapmamışsa stream'i durdur
  final authState = ref.watch(authStateProvider);
  final isAuthenticated = authState.asData?.value == true;

  if (!isAuthenticated) {
    return;
  }

  final service = ref.watch(analyticsServiceProvider);

  try {
    yield await service.getDashboardStats();

    // Periyodik güncelleme
    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      // Auth kontrolü her iterasyonda yapılmalı
      if (ref.read(authStateProvider).value != true) break;
      yield await service.getDashboardStats();
    }
  } catch (e) {
    // Auth hatası ise sessizce bitir (router yönlendirecek)
    if (e.toString().contains('StatusCode: 401') ||
        e.toString().contains('AuthException')) {
      return;
    }
    rethrow;
  }
});
