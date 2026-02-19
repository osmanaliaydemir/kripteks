import 'package:dio/dio.dart';
import 'package:mobile/core/error/error_handler.dart';
import '../models/coin_pair.dart';

class MarketDataService {
  final Dio _dio;

  MarketDataService(this._dio);

  Future<List<String>> getAvailablePairs({String market = 'crypto'}) async {
    final coins = await getAvailableCoins(market: market);
    return coins.map((c) => c.symbol).toList();
  }

  Future<List<CoinPair>> getAvailableCoins({String market = 'crypto'}) async {
    try {
      final response = await _dio.get(
        '/stocks',
        queryParameters: {'market': market},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty && data.first is Map) {
          return data
              .map((e) => CoinPair.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return data
            .map((e) => CoinPair(symbol: e.toString(), price: 0))
            .toList();
      }
      return [];
    } on DioException catch (e, stack) {
      throw ErrorHandler.handle(e, stack);
    }
  }
}
