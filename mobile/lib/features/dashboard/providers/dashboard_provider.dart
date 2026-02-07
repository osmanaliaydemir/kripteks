import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/dashboard/models/dashboard_stats.dart';
import 'package:mobile/features/dashboard/services/analytics_service.dart';
import 'package:mobile/core/network/signalr_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final dio = ref.watch(dioProvider);
  return AnalyticsService(dio);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getDashboardStats();
});

final signalRServiceProvider = Provider<SignalRService>((ref) {
  return SignalRService();
});

final signalRStatusProvider = StreamProvider<SignalRConnectionStatus>((ref) {
  final service = ref.watch(signalRServiceProvider);
  return service.statusStream;
});
