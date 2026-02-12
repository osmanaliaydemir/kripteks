import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final service = ref.watch(analyticsServiceProvider);
  yield await service.getDashboardStats();
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield await service.getDashboardStats();
  }
});
