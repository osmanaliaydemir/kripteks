class WhaleTrade {
  final String symbol;
  final double price;
  final double quantity;
  final double usdValue;
  final DateTime timestamp;
  final bool isBuyerMaker;

  WhaleTrade({
    required this.symbol,
    required this.price,
    required this.quantity,
    required this.usdValue,
    required this.timestamp,
    required this.isBuyerMaker,
  });

  factory WhaleTrade.fromJson(Map<String, dynamic> json) {
    return WhaleTrade(
      symbol: json['symbol'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      usdValue: (json['usdValue'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isBuyerMaker: json['isBuyerMaker'] as bool? ?? false,
    );
  }
}

class ArbitrageOpportunity {
  final String asset;
  final String pair1;
  final String pair2;
  final double price1;
  final double price2;
  final double differencePercent;
  final double potentialProfitUsd;

  ArbitrageOpportunity({
    required this.asset,
    required this.pair1,
    required this.pair2,
    required this.price1,
    required this.price2,
    required this.differencePercent,
    required this.potentialProfitUsd,
  });

  factory ArbitrageOpportunity.fromJson(Map<String, dynamic> json) {
    return ArbitrageOpportunity(
      asset: json['asset'] as String? ?? '',
      pair1: json['pair1'] as String? ?? '',
      pair2: json['pair2'] as String? ?? '',
      price1: (json['price1'] as num?)?.toDouble() ?? 0.0,
      price2: (json['price2'] as num?)?.toDouble() ?? 0.0,
      differencePercent: (json['differencePercent'] as num?)?.toDouble() ?? 0.0,
      potentialProfitUsd:
          (json['potentialProfitUsd'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
