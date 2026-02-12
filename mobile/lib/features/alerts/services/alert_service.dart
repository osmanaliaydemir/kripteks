import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import '../models/alert_model.dart';

class AlertService {
  final Dio _dio;

  AlertService(this._dio);

  Future<List<Alert>> getAlerts() async {
    try {
      final response = await _dio.get('/alerts');
      return (response.data as List)
          .map((json) => Alert.fromJson(json))
          .toList();
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<Alert> createAlert(CreateAlertDto request) async {
    try {
      final response = await _dio.post('/alerts', data: request.toJson());
      return Alert.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> deleteAlert(String id) async {
    try {
      await _dio.delete('/alerts/$id');
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
