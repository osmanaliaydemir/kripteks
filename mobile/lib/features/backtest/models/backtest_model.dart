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
      // API expects YYYY-MM-DD or ISO 8601
      'startDate':
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
      'endDate':
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
      'initialBalance': initialBalance,
    };
  }
}

class BacktestResult {
  final double totalPnl;
  final double totalPnlPercent;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double winRate;
  final double maxDrawdown;
  final List<BacktestTrade> trades;
  final List<BacktestCandle> candles;

  BacktestResult({
    required this.totalPnl,
    required this.totalPnlPercent,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.winRate,
    required this.maxDrawdown,
    required this.trades,
    required this.candles,
  });

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    return BacktestResult(
      totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0.0,
      totalPnlPercent: (json['totalPnlPercent'] as num?)?.toDouble() ?? 0.0,
      totalTrades: json['totalTrades'] as int? ?? 0,
      winningTrades: json['winningTrades'] as int? ?? 0,
      losingTrades: json['losingTrades'] as int? ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble() ?? 0.0,
      trades:
          (json['trades'] as List<dynamic>?)
              ?.map((e) => BacktestTrade.fromJson(e))
              .toList() ??
          [],
      candles:
          (json['candles'] as List<dynamic>?)
              ?.map((e) => BacktestCandle.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BacktestCandle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  BacktestCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory BacktestCandle.fromJson(Map<String, dynamic> json) {
    return BacktestCandle(
      time: DateTime.parse(json['time']),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
    );
  }
}

class BacktestTrade {
  final String type; // BUY, SELL
  final DateTime entryDate;
  final DateTime exitDate;
  final double entryPrice;
  final double exitPrice;
  final double pnl;
  final double commission;

  BacktestTrade({
    required this.type,
    required this.entryDate,
    required this.exitDate,
    required this.entryPrice,
    required this.exitPrice,
    required this.pnl,
    required this.commission,
  });

  factory BacktestTrade.fromJson(Map<String, dynamic> json) {
    return BacktestTrade(
      type: json['type'] as String? ?? 'BUY',
      entryDate: DateTime.parse(json['entryDate']),
      exitDate: DateTime.parse(json['exitDate']),
      entryPrice: (json['entryPrice'] as num?)?.toDouble() ?? 0.0,
      exitPrice: (json['exitPrice'] as num?)?.toDouble() ?? 0.0,
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
