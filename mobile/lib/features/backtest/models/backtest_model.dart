class BacktestRequest {
  final String symbol;
  final String strategyId;
  final String interval;
  final DateTime startDate;
  final DateTime endDate;
  final double initialBalance;

  BacktestRequest({
    required this.symbol,
    required this.strategyId,
    required this.interval,
    required this.startDate,
    required this.endDate,
    required this.initialBalance,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'strategyId': strategyId,
      'interval': interval,
      // API expects ISO 8601 strings
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'initialBalance': initialBalance,
    };
  }
}

class BacktestResult {
  final double totalPnl;
  final double totalPnlPercent;
  final int tradeCount;
  final int winCount;
  final int lossCount;
  final double winRate;
  final double maxDrawdown;
  final double maxDrawdownPercent;
  final List<BacktestTrade> trades;
  // Equity curve could be a list of {time, balance}
  final List<Map<String, dynamic>> equityCurve;

  BacktestResult({
    required this.totalPnl,
    required this.totalPnlPercent,
    required this.tradeCount,
    required this.winCount,
    required this.lossCount,
    required this.winRate,
    required this.maxDrawdown,
    required this.maxDrawdownPercent,
    required this.trades,
    required this.equityCurve,
  });

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    return BacktestResult(
      totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0.0,
      totalPnlPercent: (json['totalPnlPercent'] as num?)?.toDouble() ?? 0.0,
      tradeCount: json['tradeCount'] as int? ?? 0,
      winCount: json['winCount'] as int? ?? 0,
      lossCount: json['lossCount'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble() ?? 0.0,
      maxDrawdownPercent:
          (json['maxDrawdownPercent'] as num?)?.toDouble() ?? 0.0,
      trades:
          (json['trades'] as List<dynamic>?)
              ?.map((e) => BacktestTrade.fromJson(e))
              .toList() ??
          [],
      equityCurve:
          (json['equityCurve'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class BacktestTrade {
  final String symbol;
  final String type; // BUY, SELL
  final DateTime entryTime;
  final DateTime? exitTime;
  final double entryPrice;
  final double? exitPrice;
  final double? pnl;
  final double? pnlPercent;

  BacktestTrade({
    required this.symbol,
    required this.type,
    required this.entryTime,
    this.exitTime,
    required this.entryPrice,
    this.exitPrice,
    this.pnl,
    this.pnlPercent,
  });

  factory BacktestTrade.fromJson(Map<String, dynamic> json) {
    return BacktestTrade(
      symbol: json['symbol'] as String,
      type: json['type'] as String,
      entryTime: DateTime.parse(json['entryTime']),
      exitTime: json['exitTime'] != null
          ? DateTime.parse(json['exitTime'])
          : null,
      entryPrice: (json['entryPrice'] as num).toDouble(),
      exitPrice: (json['exitPrice'] as num?)?.toDouble(),
      pnl: (json['pnl'] as num?)?.toDouble(),
      pnlPercent: (json['pnlPercent'] as num?)?.toDouble(),
    );
  }
}
