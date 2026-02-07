class ScannerRequest {
  final List<String> symbols;
  final String strategyId;
  final String interval;
  final int? minScore;
  final Map<String, String>? strategyParameters;

  ScannerRequest({
    required this.symbols,
    required this.strategyId,
    this.interval = '1h',
    this.minScore,
    this.strategyParameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbols': symbols,
      'strategyId': strategyId,
      'interval': interval,
      'minScore': minScore,
      'strategyParameters': strategyParameters,
    };
  }
}

class ScannerResult {
  final List<ScannerResultItem> results;

  ScannerResult({required this.results});

  factory ScannerResult.fromJson(dynamic json) {
    if (json is Map<String, dynamic> && json.containsKey('results')) {
      var list = json['results'] as List;
      List<ScannerResultItem> itemsList = list
          .map((i) => ScannerResultItem.fromJson(i))
          .toList();
      return ScannerResult(results: itemsList);
    } else if (json is List) {
      List<ScannerResultItem> itemsList = json
          .map((i) => ScannerResultItem.fromJson(i))
          .toList();
      return ScannerResult(results: itemsList);
    }
    return ScannerResult(results: []);
  }
}

class ScannerResultItem {
  final String symbol;
  final double signalScore;
  final int suggestedAction; // 0=Buy, 1=Sell, 2=Wait/Neutral
  final String comment;
  final double lastPrice;

  ScannerResultItem({
    required this.symbol,
    required this.signalScore,
    required this.suggestedAction,
    required this.comment,
    required this.lastPrice,
  });

  factory ScannerResultItem.fromJson(Map<String, dynamic> json) {
    return ScannerResultItem(
      symbol: json['symbol'] as String,
      signalScore: (json['signalScore'] as num).toDouble(),
      suggestedAction: json['suggestedAction'] as int,
      comment: json['comment'] as String? ?? '',
      lastPrice: (json['lastPrice'] as num).toDouble(),
    );
  }
}

class ScannerFavoriteList {
  final String id;
  final String name;
  final List<String> symbols;
  final DateTime createdAt;

  ScannerFavoriteList({
    required this.id,
    required this.name,
    required this.symbols,
    required this.createdAt,
  });

  factory ScannerFavoriteList.fromJson(Map<String, dynamic> json) {
    return ScannerFavoriteList(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: (json['symbols'] as List).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
