import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import '../models/coin_pair.dart';
import '../services/market_data_service.dart';

final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  final dio = ref.watch(dioProvider);
  return MarketDataService(dio);
});

final availablePairsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(marketDataServiceProvider);
  return service.getAvailablePairs(market: 'crypto');
});

final availableCoinsProvider = FutureProvider<List<CoinPair>>((ref) async {
  final service = ref.watch(marketDataServiceProvider);
  return service.getAvailableCoins(market: 'crypto');
});

final bistPairsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(marketDataServiceProvider);
  return service.getAvailablePairs(market: 'bist');
});

final bistCoinsProvider = FutureProvider<List<CoinPair>>((ref) async {
  final service = ref.watch(marketDataServiceProvider);
  return service.getAvailableCoins(market: 'bist');
});

final liveMarketDataProvider = StreamProvider.autoDispose<List<CoinPair>>((
  ref,
) {
  final service = ref.watch(marketDataServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 3),
  ).asyncMap((_) => service.getAvailableCoins());
});
