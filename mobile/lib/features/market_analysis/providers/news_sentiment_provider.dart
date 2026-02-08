import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/market_analysis/models/news_sentiment.dart';

// News Feed Provider
final newsFeedProvider = FutureProvider.family<List<NewsItem>, String>((
  ref,
  symbol,
) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get(
    '/analytics/news',
    queryParameters: {'symbol': symbol},
  );

  final List<dynamic> data = response.data;
  return data
      .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
      .toList();
});

// Current Sentiment Provider
final currentSentimentProvider = FutureProvider<SentimentHistory>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get('/analytics/sentiment');
  return SentimentHistory.fromJson(response.data);
});

// Sentiment History Provider
final sentimentHistoryProvider =
    FutureProvider.family<List<SentimentHistory>, int>((ref, hours) async {
      final dio = ref.watch(dioProvider);

      final response = await dio.get(
        '/analytics/sentiment-history',
        queryParameters: {'hours': hours},
      );

      final List<dynamic> data = response.data;
      return data
          .map(
            (item) => SentimentHistory.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
