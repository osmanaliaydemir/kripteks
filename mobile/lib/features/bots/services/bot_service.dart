import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/core/models/paged_result.dart';
import '../models/bot_model.dart';
import '../models/bot_create_request_model.dart';

class BotService {
  final Dio _dio;

  BotService(this._dio);

  Future<PagedResult<Bot>> getBots({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        '/bots',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Bot.fromJson(json),
      );
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<Bot> getBot(String id) async {
    try {
      final response = await _dio.get('/bots/$id');
      return Bot.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<PagedResult<BotLog>> getBotLogs(
    String botId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/bots/$botId/logs',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return PagedResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => BotLog.fromJson(json),
      );
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> stopBot(String id) async {
    try {
      await _dio.post('/bots/$id/stop');
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> clearLogs(String id) async {
    try {
      await _dio.post('/bots/$id/clear-logs');
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<void> createBot(BotCreateRequest request) async {
    try {
      await _dio.post('/bots/start', data: request.toJson());
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
