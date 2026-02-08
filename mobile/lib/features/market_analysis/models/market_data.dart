class MarketOverview {
  final double totalMarketCap;
  final double volume24h;
  final double btcDominance;
  final double ethDominance;
  final int activeCryptos;
  final String marketTrend; // 'bullish', 'bearish', 'neutral'

  MarketOverview({
    required this.totalMarketCap,
    required this.volume24h,
    required this.btcDominance,
    required this.ethDominance,
    required this.activeCryptos,
    required this.marketTrend,
  });

  factory MarketOverview.fromJson(Map<String, dynamic> json) {
    return MarketOverview(
      totalMarketCap: (json['totalMarketCap'] as num?)?.toDouble() ?? 0.0,
      volume24h: (json['volume24h'] as num?)?.toDouble() ?? 0.0,
      btcDominance: (json['btcDominance'] as num?)?.toDouble() ?? 0.0,
      ethDominance: (json['ethDominance'] as num?)?.toDouble() ?? 0.0,
      activeCryptos: json['activeCryptos'] as int? ?? 0,
      marketTrend: json['marketTrend'] as String? ?? 'neutral',
    );
  }
}

class TopMover {
  final String symbol;
  final String name;
  final double price;
  final double changePercent24h;
  final double volume24h;

  TopMover({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent24h,
    required this.volume24h,
  });

  factory TopMover.fromJson(Map<String, dynamic> json) {
    return TopMover(
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      changePercent24h: (json['changePercent24h'] as num?)?.toDouble() ?? 0.0,
      volume24h: (json['volume24h'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VolumeData {
  final DateTime timestamp;
  final double volume;

  VolumeData({required this.timestamp, required this.volume});

  factory VolumeData.fromJson(Map<String, dynamic> json) {
    return VolumeData(
      timestamp: DateTime.parse(json['timestamp'] as String),
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MarketMetrics {
  final double fearGreedIndex;
  final String fearGreedLabel;
  final double totalVolume24h;
  final double btcPrice;
  final double ethPrice;
  final int tradingPairs;

  MarketMetrics({
    required this.fearGreedIndex,
    required this.fearGreedLabel,
    required this.totalVolume24h,
    required this.btcPrice,
    required this.ethPrice,
    required this.tradingPairs,
  });

  factory MarketMetrics.fromJson(Map<String, dynamic> json) {
    return MarketMetrics(
      fearGreedIndex: (json['fearGreedIndex'] as num?)?.toDouble() ?? 50.0,
      fearGreedLabel: json['fearGreedLabel'] as String? ?? 'Neutral',
      totalVolume24h: (json['totalVolume24h'] as num?)?.toDouble() ?? 0.0,
      btcPrice: (json['btcPrice'] as num?)?.toDouble() ?? 0.0,
      ethPrice: (json['ethPrice'] as num?)?.toDouble() ?? 0.0,
      tradingPairs: json['tradingPairs'] as int? ?? 0,
    );
  }
}
