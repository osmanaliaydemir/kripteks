import 'package:dio/dio.dart';
import '../models/scanner_model.dart';

class ScannerService {
  final Dio _dio;

  ScannerService(this._dio);

  Future<ScannerResult> scan(ScannerRequest request) async {
    try {
      final response = await _dio.post('/scanner/scan', data: request.toJson());
      return ScannerResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Scan failed: $e');
    }
  }

  Future<List<ScannerFavoriteList>> getFavoriteLists() async {
    try {
      final response = await _dio.get('/scanner/favorites');
      final List<dynamic> data = response.data;
      return data.map((json) => ScannerFavoriteList.fromJson(json)).toList();
    } catch (e) {
      // Return empty list on simple failure to not block UI,
      // or rethrow if strict error handling needed.
      // For now, logging and returning empty is safer for initial Favorites rollout.
      return [];
    }
  }

  Future<void> saveFavoriteList(String name, List<String> symbols) async {
    try {
      await _dio.post(
        '/scanner/favorites',
        data: {'name': name, 'symbols': symbols},
      );
    } catch (e) {
      throw Exception('Failed to save favorites: $e');
    }
  }
}
