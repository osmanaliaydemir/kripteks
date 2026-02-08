class EquityPoint {
  final String date;
  final double balance;
  final double dailyPnl;

  EquityPoint({
    required this.date,
    required this.balance,
    required this.dailyPnl,
  });

  factory EquityPoint.fromJson(Map<String, dynamic> json) {
    return EquityPoint(
      date: json['date'] as String,
      balance: (json['balance'] as num).toDouble(),
      dailyPnl: (json['dailyPnl'] as num).toDouble(),
    );
  }
}

class StrategyPerformance {
  final String strategyName;
  final double totalPnl;
  final double winRate;
  final double profitFactor;
  final double avgTrade;

  StrategyPerformance({
    required this.strategyName,
    required this.totalPnl,
    required this.winRate,
    required this.profitFactor,
    required this.avgTrade,
  });

  factory StrategyPerformance.fromJson(Map<String, dynamic> json) {
    return StrategyPerformance(
      strategyName: json['strategyName'] as String,
      totalPnl: (json['totalPnl'] as num).toDouble(),
      winRate: (json['winRate'] as num).toDouble(),
      profitFactor: (json['profitFactor'] as num).toDouble(),
      avgTrade: (json['avgTrade'] as num).toDouble(),
    );
  }
}
