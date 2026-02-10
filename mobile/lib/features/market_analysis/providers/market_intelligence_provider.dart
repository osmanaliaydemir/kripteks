import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/market_analysis/models/market_intelligence_models.dart';

// Whale Tracker Provider
final whaleTradesProvider = FutureProvider.autoDispose
    .family<List<WhaleTrade>, int>((ref, minUsd) async {
      final dio = ref.watch(dioProvider);
      final cancelToken = ref.watch(cancelTokenProvider);

      final response = await dio.get(
        '/WhaleTracker',
        queryParameters: {'minUsdValue': minUsd, 'count': 50},
        cancelToken: cancelToken,
      );

      final List<dynamic> data = response.data;
      return data
          .map((item) => WhaleTrade.fromJson(item as Map<String, dynamic>))
          .toList();
    });

// Arbitrage Opportunities Provider
final arbitrageOpportunitiesProvider =
    FutureProvider.autoDispose<List<ArbitrageOpportunity>>((ref) async {
      final dio = ref.watch(dioProvider);
      final cancelToken = ref.watch(cancelTokenProvider);

      final response = await dio.get(
        '/Arbitrage/opportunities',
        cancelToken: cancelToken,
      );

      final List<dynamic> data = response.data;
      return data
          .map(
            (item) =>
                ArbitrageOpportunity.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
