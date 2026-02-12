import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import '../models/portfolio_model.dart';

class PortfolioService {
  final Dio _dio;

  PortfolioService(this._dio);

  Future<PortfolioSummary> getPortfolioSummary() async {
    try {
      final response = await _dio.get('/portfolio/summary');
      return PortfolioSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
