import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget ID Tanımları
class DashboardWidgets {
  static const String totalPnl = 'total_pnl'; // Large
  static const String quickActions = 'quick_actions'; // Large & New
  static const String winRate = 'win_rate'; // Large (Overflow fix)
  static const String avgTradePnl = 'avg_trade_pnl'; // Small
  static const String botBalance = 'bot_balance'; // Small
  static const String activeBots = 'active_bots'; // Small
  static const String bestPair = 'best_pair'; // Small
  static const String dailyProfit = 'daily_profit'; // Small
  static const String totalInvest = 'total_invest'; // Small
  static const String bestBot = 'best_bot'; // Large

  static const List<String> defaultOrder = [
    totalPnl,
    quickActions, // Altına taşındı
    winRate,
    avgTradePnl,
    botBalance,
    activeBots,
    bestPair,
    dailyProfit,
    totalInvest,
    bestBot,
  ];

  static bool isLarge(String id) {
    // Toplam PnL, En İyi Bot, Hızlı İşlemler ve Win Rate geniş olsun
    return id == totalPnl ||
        id == bestBot ||
        id == quickActions ||
        id == winRate;
  }

  static String getLabel(String id) {
    switch (id) {
      case totalPnl:
        return 'Toplam Kâr/Zarar';
      case quickActions:
        return 'Hızlı İşlemler';
      case winRate:
        return 'Başarı Oranı';
      case avgTradePnl:
        return 'Ort. İşlem Kârı';
      case botBalance:
        return 'Mevcut Bot Bakiyesi';
      case activeBots:
        return 'Aktif İşlemler';
      case bestPair:
        return 'Kullanılabilir Bakiye'; // Label güncellendi
      case dailyProfit:
        return 'Bugünkü Kazanç';
      case totalInvest:
        return 'Toplam Yatırım';
      case bestBot:
        return 'En Çok Kazandıran Bot';
      default:
        return id;
    }
  }
}

class DashboardLayoutState {
  final List<String> order;
  final List<String> hiddenIds;
  final bool isEditing;

  DashboardLayoutState({
    required this.order,
    this.hiddenIds = const [],
    this.isEditing = false,
  });

  DashboardLayoutState copyWith({
    List<String>? order,
    List<String>? hiddenIds,
    bool? isEditing,
  }) {
    return DashboardLayoutState(
      order: order ?? this.order,
      hiddenIds: hiddenIds ?? this.hiddenIds,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class DashboardLayoutNotifier extends Notifier<DashboardLayoutState> {
  // Key'i değiştirerek (v4) yeni varsayılan düzeni zorluyoruz.
  static const _prefsKeyOrder = 'dashboard_layout_order_v4';
  static const _prefsKeyHidden = 'dashboard_layout_hidden_v4';

  @override
  DashboardLayoutState build() {
    _loadLayout();
    return DashboardLayoutState(order: DashboardWidgets.defaultOrder);
  }

  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList(_prefsKeyOrder);
    final savedHidden = prefs.getStringList(_prefsKeyHidden);

    List<String> finalOrder = [];

    if (savedOrder != null && savedOrder.isNotEmpty) {
      finalOrder = List.from(savedOrder);

      // Eksikleri ekle
      for (final id in DashboardWidgets.defaultOrder) {
        if (!finalOrder.contains(id)) {
          finalOrder.add(id);
        }
      }

      // Fazlalıkları çıkar
      finalOrder.removeWhere(
        (id) => !DashboardWidgets.defaultOrder.contains(id),
      );
    } else {
      finalOrder = DashboardWidgets.defaultOrder;
    }

    state = state.copyWith(order: finalOrder, hiddenIds: savedHidden ?? []);
  }

  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyOrder, state.order);
    await prefs.setStringList(_prefsKeyHidden, state.hiddenIds);
  }

  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<String>.from(state.order);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    state = state.copyWith(order: items);
    _saveLayout();
  }

  void toggleVisibility(String id) {
    final hidden = List<String>.from(state.hiddenIds);
    if (hidden.contains(id)) {
      hidden.remove(id);
    } else {
      hidden.add(id);
    }
    state = state.copyWith(hiddenIds: hidden);
    _saveLayout();
  }

  void resetLayout() {
    state = state.copyWith(order: DashboardWidgets.defaultOrder, hiddenIds: []);
    _saveLayout();
  }
}

final dashboardLayoutProvider =
    NotifierProvider<DashboardLayoutNotifier, DashboardLayoutState>(() {
      return DashboardLayoutNotifier();
    });
