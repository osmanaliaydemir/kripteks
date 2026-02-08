import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import '../services/market_data_service.dart';

final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  final dio = ref.watch(dioProvider);
  return MarketDataService(dio);
});

final availablePairsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(marketDataServiceProvider);
  return service.getAvailablePairs();
});
