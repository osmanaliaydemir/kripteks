import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/market_analysis/models/news_sentiment.dart';

// News Feed Provider
final newsFeedProvider = FutureProvider.autoDispose
    .family<List<NewsItem>, String>((ref, symbol) async {
      final dio = ref.watch(dioProvider);
      final cancelToken = ref.watch(cancelTokenProvider);

      final response = await dio.get(
        '/analytics/news',
        queryParameters: {'symbol': symbol},
        cancelToken: cancelToken,
      );

      final List<dynamic> data = response.data;
      return data
          .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
          .toList();
    });

// Current Sentiment Provider
final currentSentimentProvider = FutureProvider.autoDispose<SentimentHistory>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final cancelToken = ref.watch(cancelTokenProvider);

  final response = await dio.get(
    '/analytics/sentiment',
    cancelToken: cancelToken,
  );
  return SentimentHistory.fromJson(response.data);
});

// Sentiment History Provider
final sentimentHistoryProvider = FutureProvider.autoDispose
    .family<List<SentimentHistory>, int>((ref, hours) async {
      final dio = ref.watch(dioProvider);
      final cancelToken = ref.watch(cancelTokenProvider);

      final response = await dio.get(
        '/analytics/sentiment-history',
        queryParameters: {'hours': hours},
        cancelToken: cancelToken,
      );

      final List<dynamic> data = response.data;
      return data
          .map(
            (item) => SentimentHistory.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
