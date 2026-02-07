class WalletDetails {
  final double currentBalance;
  final double availableBalance;
  final double lockedBalance;
  final double totalPnl;

  WalletDetails({
    required this.currentBalance,
    required this.availableBalance,
    required this.lockedBalance,
    required this.totalPnl,
  });

  factory WalletDetails.fromJson(Map<String, dynamic> json) {
    return WalletDetails(
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      lockedBalance: (json['locked_balance'] as num?)?.toDouble() ?? 0.0,
      totalPnl: (json['total_pnl'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

enum TransactionType {
  // ignore: constant_identifier_names
  Deposit,
  // ignore: constant_identifier_names
  Withdraw,
  // ignore: constant_identifier_names
  BotInvestment,
  // ignore: constant_identifier_names
  BotReturn,
  // ignore: constant_identifier_names
  Fee,
}

class WalletTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    // Helper to get value from multiple possible keys
    dynamic getValue(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key];
        }
      }
      return null;
    }

    final amountVal = getValue(['amount', 'Amount']);
    final descVal = getValue(['description', 'Description']);
    final createdVal = getValue(['created_at', 'createdAt', 'CreatedAt']);
    final typeVal = getValue(['type', 'Type']);

    // Parse type safely
    TransactionType parsedType = TransactionType.Fee;
    if (typeVal != null) {
      final typeStr = typeVal.toString();
      parsedType = TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => TransactionType.Fee,
      );
    }

    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      amount: (amountVal as num?)?.toDouble() ?? 0.0,
      type: parsedType,
      description: descVal?.toString() ?? '',
      createdAt:
          DateTime.tryParse(createdVal?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
