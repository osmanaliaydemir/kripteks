class BotCreateRequest {
  final String symbol;
  final String strategyId;
  final double amount;
  final String interval;
  final double? stopLoss;
  final double? takeProfit;
  final bool isTrailingStop;
  final double? trailingStopDistance;

  BotCreateRequest({
    required this.symbol,
    required this.strategyId,
    required this.amount,
    required this.interval,
    this.stopLoss,
    this.takeProfit,
    this.isTrailingStop = false,
    this.trailingStopDistance,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'strategyId': strategyId,
      'amount': amount,
      'interval': interval,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'isTrailingStop': isTrailingStop,
      'trailingStopDistance': trailingStopDistance,
    };
  }
}
