import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/market_analysis/models/market_data.dart';

// Market Overview Provider
final marketOverviewProvider = FutureProvider<MarketOverview>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get('/market-analysis/overview');
  return MarketOverview.fromJson(response.data);
});

// Top Gainers Provider
final topGainersProvider = FutureProvider<List<TopMover>>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/market-analysis/top-gainers',
    queryParameters: {'count': 5},
  );
  final List<dynamic> data = response.data;
  return data.map((item) => TopMover.fromJson(item)).toList();
});

// Top Losers Provider
final topLosersProvider = FutureProvider<List<TopMover>>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/market-analysis/top-losers',
    queryParameters: {'count': 5},
  );
  final List<dynamic> data = response.data;
  return data.map((item) => TopMover.fromJson(item)).toList();
});

// Volume History Provider
final volumeHistoryProvider = FutureProvider<List<VolumeData>>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/market-analysis/volume-history',
    queryParameters: {'hours': 24},
  );
  final List<dynamic> data = response.data;
  return data.map((item) => VolumeData.fromJson(item)).toList();
});

// Market Metrics Provider
final marketMetricsProvider = FutureProvider<MarketMetrics>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get('/market-analysis/metrics');
  return MarketMetrics.fromJson(response.data);
});
