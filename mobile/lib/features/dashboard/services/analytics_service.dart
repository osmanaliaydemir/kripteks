import 'package:dio/dio.dart';
import 'package:mobile/features/dashboard/models/dashboard_stats.dart';

class AnalyticsService {
  final Dio _dio;

  AnalyticsService(this._dio);

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get('/analytics/stats');
      return DashboardStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load dashboard stats: $e');
    }
  }
}
