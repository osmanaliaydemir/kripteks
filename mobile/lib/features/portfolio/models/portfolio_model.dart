/// Portföy modelleri: asset dağılımı, risk metrikleri, rebalancing önerileri.
library;

class PortfolioSummary {
  final double totalValue;
  final double totalInvested;
  final double totalPnl;
  final double totalPnlPercent;
  final double dailyPnl;
  final double dailyPnlPercent;
  final int assetCount;
  final List<PortfolioAsset> assets;
  final PortfolioRiskMetrics riskMetrics;
  final List<RebalanceSuggestion> rebalanceSuggestions;

  PortfolioSummary({
    required this.totalValue,
    required this.totalInvested,
    required this.totalPnl,
    required this.totalPnlPercent,
    required this.dailyPnl,
    required this.dailyPnlPercent,
    required this.assetCount,
    required this.assets,
    required this.riskMetrics,
    required this.rebalanceSuggestions,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0.0,
      totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0.0,
      totalPnlPercent: (json['totalPnlPercent'] as num?)?.toDouble() ?? 0.0,
      dailyPnl: (json['dailyPnl'] as num?)?.toDouble() ?? 0.0,
      dailyPnlPercent: (json['dailyPnlPercent'] as num?)?.toDouble() ?? 0.0,
      assetCount: (json['assetCount'] as num?)?.toInt() ?? 0,
      assets:
          (json['assets'] as List<dynamic>?)
              ?.map((e) => PortfolioAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      riskMetrics: json['riskMetrics'] != null
          ? PortfolioRiskMetrics.fromJson(
              json['riskMetrics'] as Map<String, dynamic>,
            )
          : PortfolioRiskMetrics.empty(),
      rebalanceSuggestions:
          (json['rebalanceSuggestions'] as List<dynamic>?)
              ?.map(
                (e) => RebalanceSuggestion.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class PortfolioAsset {
  final String symbol;
  final String baseAsset;
  final double quantity;
  final double averageCost;
  final double currentPrice;
  final double currentValue;
  final double totalInvested;
  final double pnl;
  final double pnlPercent;
  final double allocationPercent;
  final double dailyChange;
  final DateTime firstBuyDate;

  PortfolioAsset({
    required this.symbol,
    required this.baseAsset,
    required this.quantity,
    required this.averageCost,
    required this.currentPrice,
    required this.currentValue,
    required this.totalInvested,
    required this.pnl,
    required this.pnlPercent,
    required this.allocationPercent,
    required this.dailyChange,
    required this.firstBuyDate,
  });

  factory PortfolioAsset.fromJson(Map<String, dynamic> json) {
    return PortfolioAsset(
      symbol: json['symbol']?.toString() ?? '',
      baseAsset: json['baseAsset']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      averageCost: (json['averageCost'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0.0,
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0.0,
      pnlPercent: (json['pnlPercent'] as num?)?.toDouble() ?? 0.0,
      allocationPercent: (json['allocationPercent'] as num?)?.toDouble() ?? 0.0,
      dailyChange: (json['dailyChange'] as num?)?.toDouble() ?? 0.0,
      firstBuyDate:
          DateTime.tryParse(json['firstBuyDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class PortfolioRiskMetrics {
  final double sharpeRatio;
  final double sortinoRatio;
  final double beta;
  final double maxDrawdown;
  final double concentrationRisk;
  final double volatility;
  final String riskLevel;

  PortfolioRiskMetrics({
    required this.sharpeRatio,
    required this.sortinoRatio,
    required this.beta,
    required this.maxDrawdown,
    required this.concentrationRisk,
    required this.volatility,
    required this.riskLevel,
  });

  factory PortfolioRiskMetrics.fromJson(Map<String, dynamic> json) {
    return PortfolioRiskMetrics(
      sharpeRatio: (json['sharpeRatio'] as num?)?.toDouble() ?? 0.0,
      sortinoRatio: (json['sortinoRatio'] as num?)?.toDouble() ?? 0.0,
      beta: (json['beta'] as num?)?.toDouble() ?? 0.0,
      maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble() ?? 0.0,
      concentrationRisk: (json['concentrationRisk'] as num?)?.toDouble() ?? 0.0,
      volatility: (json['volatility'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['riskLevel']?.toString() ?? 'Orta',
    );
  }

  factory PortfolioRiskMetrics.empty() {
    return PortfolioRiskMetrics(
      sharpeRatio: 0,
      sortinoRatio: 0,
      beta: 0,
      maxDrawdown: 0,
      concentrationRisk: 0,
      volatility: 0,
      riskLevel: 'Yok',
    );
  }
}

class RebalanceSuggestion {
  final String symbol;
  final String baseAsset;
  final double currentPercent;
  final double targetPercent;
  final double deltaPercent;
  final String action;
  final double suggestedAmountUsdt;
  final String reason;

  RebalanceSuggestion({
    required this.symbol,
    required this.baseAsset,
    required this.currentPercent,
    required this.targetPercent,
    required this.deltaPercent,
    required this.action,
    required this.suggestedAmountUsdt,
    required this.reason,
  });

  factory RebalanceSuggestion.fromJson(Map<String, dynamic> json) {
    return RebalanceSuggestion(
      symbol: json['symbol']?.toString() ?? '',
      baseAsset: json['baseAsset']?.toString() ?? '',
      currentPercent: (json['currentPercent'] as num?)?.toDouble() ?? 0.0,
      targetPercent: (json['targetPercent'] as num?)?.toDouble() ?? 0.0,
      deltaPercent: (json['deltaPercent'] as num?)?.toDouble() ?? 0.0,
      action: json['action']?.toString() ?? '',
      suggestedAmountUsdt:
          (json['suggestedAmountUsdt'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? '',
    );
  }
}
