import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
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
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<BacktestResult> runBacktest(BacktestRequest request) async {
    try {
      final response = await _dio.post('/backtest/run', data: request.toJson());
      return BacktestResult.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
