import 'package:dio/dio.dart';

class MarketDataService {
  final Dio _dio;

  MarketDataService(this._dio);

  Future<List<String>> getAvailablePairs() async {
    try {
      final response = await _dio.get('/stocks');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // The API might return a list of objects (Maps) or Strings.
        // The error indicates it's a List<Map<String, dynamic>>.
        // We need to extract the symbol.
        if (data.isNotEmpty && data.first is Map) {
          return data.map((e) => e['symbol'].toString()).toList();
        }
        return data.cast<String>();
      }
      throw Exception('Failed to load pairs');
    } catch (e) {
      throw Exception('Failed to load pairs: $e');
    }
  }
}
