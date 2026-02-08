class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String url;
  final DateTime publishedAt;
  final double sentimentScore;
  final String aiSummary;
  final bool isAnalyzed;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    required this.publishedAt,
    required this.sentimentScore,
    required this.aiSummary,
    required this.isAnalyzed,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      source: json['source'] as String? ?? '',
      url: json['url'] as String? ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : DateTime.now(),
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble() ?? 0.0,
      aiSummary: json['aiSummary'] as String? ?? '',
      isAnalyzed: json['isAnalyzed'] as bool? ?? false,
    );
  }
}

class SentimentHistory {
  final int id;
  final double score;
  final String action;
  final String symbol;
  final String summary;
  final DateTime recordedAt;
  final int modelCount;

  SentimentHistory({
    required this.id,
    required this.score,
    required this.action,
    required this.symbol,
    required this.summary,
    required this.recordedAt,
    required this.modelCount,
  });

  factory SentimentHistory.fromJson(Map<String, dynamic> json) {
    return SentimentHistory(
      id: json['id'] as int? ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      action: json['action'] as String? ?? 'HOLD',
      symbol: json['symbol'] as String? ?? 'BTC',
      summary: json['summary'] as String? ?? '',
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
      modelCount: json['modelCount'] as int? ?? 2,
    );
  }
}
