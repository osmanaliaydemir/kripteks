import 'package:dio/dio.dart';
import '../models/bot_model.dart';
import '../models/bot_create_request_model.dart';

class BotService {
  final Dio _dio;

  BotService(this._dio);

  Future<List<Bot>> getBots() async {
    try {
      final response = await _dio.get('/bots');
      final List<dynamic> data = response.data;
      return data.map((json) => Bot.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch bots: $e');
    }
  }

  Future<Bot> getBot(String id) async {
    try {
      final response = await _dio.get('/bots/$id');
      return Bot.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch bot details: $e');
    }
  }

  Future<void> stopBot(String id) async {
    try {
      await _dio.post('/bots/$id/stop');
    } catch (e) {
      throw Exception('Failed to stop bot: $e');
    }
  }

  Future<void> clearLogs(String id) async {
    try {
      await _dio.post('/bots/$id/clear-logs');
    } catch (e) {
      throw Exception('Failed to clear logs: $e');
    }
  }

  Future<void> createBot(BotCreateRequest request) async {
    try {
      await _dio.post('/bots', data: request.toJson());
    } catch (e) {
      throw Exception('Failed to create bot: $e');
    }
  }
}
