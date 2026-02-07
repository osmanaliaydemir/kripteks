import 'package:dio/dio.dart';
import '../models/strategy_model.dart';
import '../models/backtest_model.dart';

class BacktestService {
  final Dio _dio;

  BacktestService(this._dio);

  Future<List<Strategy>> getStrategies() async {
    try {
      final response = await _dio.get('/strategies');
      final List<dynamic> data = response.data;
      return data.map((json) => Strategy.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch strategies: $e');
    }
  }

  Future<BacktestResult> runBacktest(BacktestRequest request) async {
    try {
      // Backend endpoint is /api/backtest/run based on BacktestController
      final response = await _dio.post('/backtest/run', data: request.toJson());
      return BacktestResult.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?.toString() ?? 'Backtest failed');
      }
      throw Exception('Backtest failed: $e');
    }
  }

  // Future<List<BacktestResult>> getHistory() async { ... } // Implement later if needed
}
