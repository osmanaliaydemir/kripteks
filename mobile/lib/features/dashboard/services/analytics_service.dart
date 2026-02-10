import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/features/dashboard/models/dashboard_stats.dart';

class AnalyticsService {
  final Dio _dio;

  AnalyticsService(this._dio);

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get('/analytics/stats');
      return DashboardStats.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<List<dynamic>> getEquityCurve() async {
    try {
      final response = await _dio.get('/analytics/equity');
      return response.data as List<dynamic>;
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<List<dynamic>> getStrategyPerformance() async {
    try {
      final response = await _dio.get('/analytics/performance');
      return response.data as List<dynamic>;
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
