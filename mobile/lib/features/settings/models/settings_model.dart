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
