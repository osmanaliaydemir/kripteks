import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import '../models/bot_create_request_model.dart';
import '../../../core/providers/market_data_provider.dart';
import 'bot_provider.dart';

// ... (rest of imports)

// ... (at the bottom)

final availableSymbolsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  return ref.watch(availablePairsProvider.future);
});

class BotCreateState {
  final int currentStep;
  final String? selectedSymbol;
  final String? selectedStrategyId;
  final double amount;
  final String interval;
  final double? stopLoss;
  final double? takeProfit;
  final bool isTrailingStop;
  final double? trailingStopDistance;
  final bool isLoading;
  final String? error;

  BotCreateState({
    this.currentStep = 0,
    this.selectedSymbol,
    this.selectedStrategyId,
    this.amount = 100,
    this.interval = '1h',
    this.stopLoss,
    this.takeProfit,
    this.isTrailingStop = false,
    this.trailingStopDistance,
    this.isLoading = false,
    this.error,
  });

  BotCreateState copyWith({
    int? currentStep,
    String? selectedSymbol,
    String? selectedStrategyId,
    double? amount,
    String? interval,
    double? stopLoss,
    double? takeProfit,
    bool? isTrailingStop,
    double? trailingStopDistance,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearStopLoss = false,
    bool clearTakeProfit = false,
    bool clearTrailingStopDistance = false,
  }) {
    return BotCreateState(
      currentStep: currentStep ?? this.currentStep,
      selectedSymbol: selectedSymbol ?? this.selectedSymbol,
      selectedStrategyId: selectedStrategyId ?? this.selectedStrategyId,
      amount: amount ?? this.amount,
      interval: interval ?? this.interval,
      stopLoss: clearStopLoss ? null : (stopLoss ?? this.stopLoss),
      takeProfit: clearTakeProfit ? null : (takeProfit ?? this.takeProfit),
      isTrailingStop: isTrailingStop ?? this.isTrailingStop,
      trailingStopDistance: clearTrailingStopDistance
          ? null
          : (trailingStopDistance ?? this.trailingStopDistance),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BotCreateNotifier extends Notifier<BotCreateState> {
  @override
  BotCreateState build() {
    return BotCreateState();
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void selectSymbol(String symbol) {
    state = state.copyWith(selectedSymbol: symbol);
  }

  void selectStrategy(String strategyId) {
    state = state.copyWith(selectedStrategyId: strategyId);
  }

  void updateConfig({
    double? amount,
    String? interval,
    double? stopLoss,
    double? takeProfit,
    bool? isTrailingStop,
    double? trailingStopDistance,
    bool clearStopLoss = false,
    bool clearTakeProfit = false,
    bool clearTrailingStopDistance = false,
  }) {
    state = state.copyWith(
      amount: amount,
      interval: interval,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      isTrailingStop: isTrailingStop,
      trailingStopDistance: trailingStopDistance,
      clearStopLoss: clearStopLoss,
      clearTakeProfit: clearTakeProfit,
      clearTrailingStopDistance: clearTrailingStopDistance,
    );
  }

  Future<bool> createBot() async {
    if (state.selectedSymbol == null || state.selectedStrategyId == null) {
      state = state.copyWith(error: 'Eksik bilgiler var.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final request = BotCreateRequest(
        symbol: state.selectedSymbol!,
        strategyId: state.selectedStrategyId!,
        amount: state.amount,
        interval: state.interval,
        stopLoss: state.stopLoss,
        takeProfit: state.takeProfit,
        isTrailingStop: state.isTrailingStop,
        trailingStopDistance: state.trailingStopDistance,
      );

      final botService = ref.read(botServiceProvider);
      await botService.createBot(request);

      // Refresh bot list
      ref.invalidate(paginatedBotListProvider);

      state = state.copyWith(isLoading: false);
      // Reset after successful creation
      reset();
      return true;
    } catch (e) {
      final errorMessage = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  void reset() {
    state = BotCreateState();
  }
}

final botCreateProvider = NotifierProvider<BotCreateNotifier, BotCreateState>(
  BotCreateNotifier.new,
);
