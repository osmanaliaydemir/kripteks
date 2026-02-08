import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/network/market_data_signalr_service.dart';
import 'package:mobile/features/market_analysis/models/market_data.dart';
import 'package:signalr_netcore/hub_connection.dart';

// SignalR Service Provider
final marketDataSignalRProvider = Provider<MarketDataSignalRService>((ref) {
  final service = MarketDataSignalRService();

  // Connect when provider is first accessed
  service.connect();

  // Disconnect when provider is disposed
  ref.onDispose(() {
    service.disconnect();
  });

  return service;
});

// SignalR Connection State Provider
final marketDataConnectionStateProvider = StreamProvider<HubConnectionState>((
  ref,
) {
  return ref.watch(marketDataSignalRProvider).connectionStateStream;
});

// Real-time Market Overview Provider
final marketOverviewStreamProvider = StreamProvider<MarketOverview>((ref) {
  return ref.watch(marketDataSignalRProvider).marketOverviewStream;
});

// Real-time Top Gainers Provider
final topGainersStreamProvider = StreamProvider<List<TopMover>>((ref) {
  return ref.watch(marketDataSignalRProvider).topGainersStream;
});

// Real-time Top Losers Provider
final topLosersStreamProvider = StreamProvider<List<TopMover>>((ref) {
  return ref.watch(marketDataSignalRProvider).topLosersStream;
});

// Real-time Volume Update Provider
final volumeDataStreamProvider = StreamProvider<VolumeData>((ref) {
  return ref.watch(marketDataSignalRProvider).volumeDataStream;
});

// Market Overview Provider (Combines initial fetch with real-time stream)
final marketOverviewProvider = FutureProvider<MarketOverview>((ref) async {
  final dio = ref.watch(dioProvider);

  // Initial fetch
  final response = await dio.get('/market-analysis/overview');
  final initialData = MarketOverview.fromJson(response.data);

  return initialData;
});

// Top Gainers Provider
final topGainersProvider = FutureProvider<List<TopMover>>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/market-analysis/top-gainers',
    queryParameters: {'count': 5},
  );
  final List<dynamic> data = response.data;
  return data
      .map((item) => TopMover.fromJson(item as Map<String, dynamic>))
      .toList();
});

// Top Losers Provider
final topLosersProvider = FutureProvider<List<TopMover>>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/market-analysis/top-losers',
    queryParameters: {'count': 5},
  );
  final List<dynamic> data = response.data;
  return data
      .map((item) => TopMover.fromJson(item as Map<String, dynamic>))
      .toList();
});

// Volume History Provider
final volumeHistoryProvider = FutureProvider<List<VolumeData>>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/market-analysis/volume-history',
    queryParameters: {'hours': 24},
  );
  final List<dynamic> data = response.data;
  return data
      .map((item) => VolumeData.fromJson(item as Map<String, dynamic>))
      .toList();
});

// Market Metrics Provider
final marketMetricsProvider = FutureProvider<MarketMetrics>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get('/market-analysis/metrics');
  return MarketMetrics.fromJson(response.data);
});
