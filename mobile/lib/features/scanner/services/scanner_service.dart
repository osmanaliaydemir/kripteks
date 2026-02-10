import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import '../models/scanner_model.dart';

class ScannerService {
  final Dio _dio;

  ScannerService(this._dio);

  Future<ScannerResult> scan(ScannerRequest request) async {
    try {
      final response = await _dio.post('/scanner/scan', data: request.toJson());
      return ScannerResult.fromJson(response.data);
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }

  Future<List<ScannerFavoriteList>> getFavoriteLists() async {
    try {
      final response = await _dio.get('/scanner/favorites');
      final List<dynamic> data = response.data;
      return data.map((json) => ScannerFavoriteList.fromJson(json)).toList();
    } on DioException catch (e, stack) {
      // Favori listeleri yüklenemezse hatayı raporla ama boş liste dön
      // UI bloke olmasın diye graceful degradation uyguluyoruz
      ErrorHandler.handle(e, stack);
      return [];
    }
  }

  Future<void> saveFavoriteList(String name, List<String> symbols) async {
    try {
      await _dio.post(
        '/scanner/favorites',
        data: {'name': name, 'symbols': symbols},
      );
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
