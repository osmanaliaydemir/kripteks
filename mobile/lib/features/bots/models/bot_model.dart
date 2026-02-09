class Bot {
  final String id;
  final String symbol;
  final String strategyName;
  final double amount;
  final String interval;
  final double? stopLoss;
  final double? takeProfit;
  final String status;
  final double pnl;
  final double pnlPercent;
  final DateTime createdAt;
  final double entryPrice;
  final DateTime? entryDate;
  final DateTime? exitDate;
  final double currentPnl;
  final double currentPnlPercent;
  final bool isTrailingStop;
  final double? trailingStopDistance;
  final double? maxPriceReached;
  final bool isArchived;
  final List<BotLog>? logs;

  Bot({
    required this.id,
    required this.symbol,
    required this.strategyName,
    required this.amount,
    required this.interval,
    this.stopLoss,
    this.takeProfit,
    required this.status,
    required this.pnl,
    required this.pnlPercent,
    required this.createdAt,
    required this.entryPrice,
    this.entryDate,
    this.exitDate,
    required this.currentPnl,
    required this.currentPnlPercent,
    required this.isTrailingStop,
    this.trailingStopDistance,
    this.maxPriceReached,
    required this.isArchived,
    this.logs,
  });

  factory Bot.fromJson(Map<String, dynamic> json) {
    return Bot(
      id: json['id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      strategyName: json['strategyName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      interval: json['interval'] as String? ?? '',
      stopLoss: (json['stopLoss'] as num?)?.toDouble(),
      takeProfit: (json['takeProfit'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Unknown',
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0.0,
      pnlPercent: (json['pnlPercent'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      entryPrice: (json['entryPrice'] as num?)?.toDouble() ?? 0.0,
      entryDate: json['entryDate'] != null
          ? DateTime.tryParse(json['entryDate'] as String)
          : null,
      exitDate: json['exitDate'] != null
          ? DateTime.tryParse(json['exitDate'] as String)
          : null,
      currentPnl: (json['currentPnl'] as num?)?.toDouble() ?? 0.0,
      currentPnlPercent: (json['currentPnlPercent'] as num?)?.toDouble() ?? 0.0,
      isTrailingStop: json['isTrailingStop'] as bool? ?? false,
      trailingStopDistance: (json['trailingStopDistance'] as num?)?.toDouble(),
      maxPriceReached: (json['maxPriceReached'] as num?)?.toDouble(),
      isArchived: json['isArchived'] as bool? ?? false,
      logs: (json['logs'] as List<dynamic>?)
          ?.map((e) => BotLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BotLog {
  final int id;
  final String botId;
  final String message;
  final String logLevel;
  final DateTime timestamp;

  BotLog({
    required this.id,
    required this.botId,
    required this.message,
    required this.logLevel,
    required this.timestamp,
  });

  factory BotLog.fromJson(Map<String, dynamic> json) {
    return BotLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      botId: json['botId'] as String? ?? '',
      message: json['message'] as String? ?? '',
      logLevel: json['logLevel'] as String? ?? 'INFO',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
