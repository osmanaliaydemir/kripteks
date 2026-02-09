class ApiKeyStatus {
  final bool hasKeys;
  final String? apiKey; // Masked

  ApiKeyStatus({required this.hasKeys, this.apiKey});

  factory ApiKeyStatus.fromJson(Map<String, dynamic> json) {
    return ApiKeyStatus(
      hasKeys: json['hasKeys'] as bool,
      apiKey: json['apiKey'] as String?,
    );
  }
}

class SystemSetting {
  final String? telegramBotToken;
  final String? telegramChatId;
  final bool enableTelegramNotifications;
  final double globalStopLossPercent;
  final int maxActiveBots;
  final String? defaultTimeframe;
  final double defaultAmount;

  SystemSetting({
    this.telegramBotToken,
    this.telegramChatId,
    required this.enableTelegramNotifications,
    required this.globalStopLossPercent,
    required this.maxActiveBots,
    this.defaultTimeframe,
    required this.defaultAmount,
  });

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    return SystemSetting(
      telegramBotToken: json['telegramBotToken'] as String?,
      telegramChatId: json['telegramChatId'] as String?,
      enableTelegramNotifications:
          json['enableTelegramNotifications'] as bool? ?? false,
      globalStopLossPercent:
          (json['globalStopLossPercent'] as num?)?.toDouble() ?? 5.0,
      maxActiveBots: json['maxActiveBots'] as int? ?? 5,
      defaultTimeframe: json['defaultTimeframe'] as String?,
      defaultAmount: (json['defaultAmount'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telegramBotToken': telegramBotToken,
      'telegramChatId': telegramChatId,
      'enableTelegramNotifications': enableTelegramNotifications,
      'globalStopLossPercent': globalStopLossPercent,
      'maxActiveBots': maxActiveBots,
      'defaultTimeframe': defaultTimeframe,
      'defaultAmount': defaultAmount,
    };
  }
}

class BiometricState {
  final bool isSupported;
  final bool isEnabled;

  BiometricState({required this.isSupported, required this.isEnabled});
}

class NotificationSettings {
  final bool notifyBuySignals;
  final bool notifySellSignals;
  final bool notifyStopLoss;
  final bool notifyTakeProfit;
  final bool notifyGeneral;
  final bool notifyErrors;
  final bool enablePushNotifications;

  NotificationSettings({
    this.notifyBuySignals = true,
    this.notifySellSignals = true,
    this.notifyStopLoss = true,
    this.notifyTakeProfit = true,
    this.notifyGeneral = true,
    this.notifyErrors = true,
    this.enablePushNotifications = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      notifyBuySignals: json['notifyBuySignals'] as bool? ?? true,
      notifySellSignals: json['notifySellSignals'] as bool? ?? true,
      notifyStopLoss: json['notifyStopLoss'] as bool? ?? true,
      notifyTakeProfit: json['notifyTakeProfit'] as bool? ?? true,
      notifyGeneral: json['notifyGeneral'] as bool? ?? true,
      notifyErrors: json['notifyErrors'] as bool? ?? true,
      enablePushNotifications: json['enablePushNotifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifyBuySignals': notifyBuySignals,
      'notifySellSignals': notifySellSignals,
      'notifyStopLoss': notifyStopLoss,
      'notifyTakeProfit': notifyTakeProfit,
      'notifyGeneral': notifyGeneral,
      'notifyErrors': notifyErrors,
      'enablePushNotifications': enablePushNotifications,
    };
  }

  NotificationSettings copyWith({
    bool? notifyBuySignals,
    bool? notifySellSignals,
    bool? notifyStopLoss,
    bool? notifyTakeProfit,
    bool? notifyGeneral,
    bool? notifyErrors,
    bool? enablePushNotifications,
  }) {
    return NotificationSettings(
      notifyBuySignals: notifyBuySignals ?? this.notifyBuySignals,
      notifySellSignals: notifySellSignals ?? this.notifySellSignals,
      notifyStopLoss: notifyStopLoss ?? this.notifyStopLoss,
      notifyTakeProfit: notifyTakeProfit ?? this.notifyTakeProfit,
      notifyGeneral: notifyGeneral ?? this.notifyGeneral,
      notifyErrors: notifyErrors ?? this.notifyErrors,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
    );
  }
}
