class CoinPair {
  final String symbol;
  final double price;

  CoinPair({required this.symbol, required this.price});

  factory CoinPair.fromJson(Map<String, dynamic> json) {
    return CoinPair(
      symbol: json['symbol'] as String,
      price: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
