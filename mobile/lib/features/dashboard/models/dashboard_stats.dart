class DashboardStats {
  final double totalPnl;
  final double winRate;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final String bestPair;
  final double profitFactor;
  final double avgTradePnL;
  final double maxDrawdown;

  DashboardStats({
    required this.totalPnl,
    required this.winRate,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.bestPair,
    required this.profitFactor,
    required this.avgTradePnL,
    required this.maxDrawdown,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0.0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      totalTrades: json['totalTrades'] as int? ?? 0,
      winningTrades: json['winningTrades'] as int? ?? 0,
      losingTrades: json['losingTrades'] as int? ?? 0,
      bestPair: json['bestPair'] as String? ?? '',
      profitFactor: (json['profitFactor'] as num?)?.toDouble() ?? 0.0,
      avgTradePnL: (json['avgTradePnL'] as num?)?.toDouble() ?? 0.0,
      maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
