import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/market_analysis/models/market_intelligence_models.dart';

// Whale Tracker Provider
final whaleTradesProvider = FutureProvider.family<List<WhaleTrade>, int>((
  ref,
  minUsd,
) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/WhaleTracker',
    queryParameters: {'minUsdValue': minUsd, 'count': 50},
  );

  final List<dynamic> data = response.data;
  return data
      .map((item) => WhaleTrade.fromJson(item as Map<String, dynamic>))
      .toList();
});

// Arbitrage Opportunities Provider
final arbitrageOpportunitiesProvider =
    FutureProvider<List<ArbitrageOpportunity>>((ref) async {
      final dio = ref.watch(dioProvider);

      final response = await dio.get('/Arbitrage/opportunities');

      final List<dynamic> data = response.data;
      return data
          .map(
            (item) =>
                ArbitrageOpportunity.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
