enum AlertType { price, indicator }

enum AlertCondition { above, below, crossOver, crossUnder }

class Alert {
  final String id;
  final String symbol;
  final AlertType type;
  final double targetValue;
  final AlertCondition condition;
  final String? indicatorName;
  final String? timeframe;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;

  const Alert({
    required this.id,
    required this.symbol,
    required this.type,
    required this.targetValue,
    required this.condition,
    this.indicatorName,
    this.timeframe,
    this.isEnabled = true,
    required this.createdAt,
    this.lastTriggeredAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      type: AlertType.values[json['type'] as int],
      targetValue: (json['targetValue'] as num).toDouble(),
      condition: AlertCondition.values[json['condition'] as int],
      indicatorName: json['indicatorName'] as String?,
      timeframe: json['timeframe'] as String?,
      isEnabled: json['isEnabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastTriggeredAt: json['lastTriggeredAt'] != null
          ? DateTime.parse(json['lastTriggeredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type.index,
      'targetValue': targetValue,
      'condition': condition.index,
      'indicatorName': indicatorName,
      'timeframe': timeframe,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
    };
  }

  String get conditionText {
    switch (condition) {
      case AlertCondition.above:
        return 'Yukarı';
      case AlertCondition.below:
        return 'Aşağı';
      case AlertCondition.crossOver:
        return 'Yukarı Kesen';
      case AlertCondition.crossUnder:
        return 'Aşağı Kesen';
    }
  }

  String get conditionSymbol {
    switch (condition) {
      case AlertCondition.above:
        return '>';
      case AlertCondition.below:
        return '<';
      case AlertCondition.crossOver:
        return '↗';
      case AlertCondition.crossUnder:
        return '↘';
    }
  }
}

class CreateAlertDto {
  final String symbol;
  final AlertType type;
  final double targetValue;
  final AlertCondition condition;
  final String? indicatorName;
  final String? timeframe;

  CreateAlertDto({
    required this.symbol,
    required this.type,
    required this.targetValue,
    required this.condition,
    this.indicatorName,
    this.timeframe,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'type': type.index,
      'targetValue': targetValue,
      'condition': condition.index,
      'indicatorName': indicatorName,
      'timeframe': timeframe,
    };
  }
}
