import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_header.dart';
import '../providers/bot_create_provider.dart';
import '../../backtest/providers/backtest_provider.dart';
import '../../wallet/providers/wallet_provider.dart';

class BotCreateWizardScreen extends ConsumerStatefulWidget {
  const BotCreateWizardScreen({super.key});

  @override
  ConsumerState<BotCreateWizardScreen> createState() =>
      _BotCreateWizardScreenState();
}

class _BotCreateWizardScreenState extends ConsumerState<BotCreateWizardScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _intervalMap = {
    '1m': '1 Dakika',
    '3m': '3 Dakika',
    '5m': '5 Dakika',
    '15m': '15 Dakika',
    '30m': '30 Dakika',
    '1h': '1 Saat',
    '2h': '2 Saat',
    '4h': '4 Saat',
    '6h': '6 Saat',
    '8h': '8 Saat',
    '12h': '12 Saat',
    '1d': '1 Gün',
    '3d': '3 Gün',
    '1w': '1 Hafta',
    '1M': '1 Ay',
  };

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default values if any
    final state = ref.read(botCreateProvider);
    _amountController.text = state.amount.toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();

    _searchController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final state = ref.read(botCreateProvider);
    final notifier = ref.read(botCreateProvider.notifier);

    // Validation before proceeding
    if (state.currentStep == 0 && state.selectedSymbol == null) {
      toastification.show(
        context: context,
        title: const Text('Lütfen bir coin seçin'),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    if (state.currentStep == 1 && state.selectedStrategyId == null) {
      toastification.show(
        context: context,
        title: const Text('Lütfen bir strateji seçin'),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    if (state.currentStep == 2) {
      // Save config values
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        toastification.show(
          context: context,
          title: const Text('Geçerli bir tutar girin'),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }
      notifier.updateConfig(
        amount: amount,
        // stopLoss, takeProfit, and trailingStopDistance are updated live
      );
    }

    if (state.currentStep < 3) {
      notifier.nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    final state = ref.read(botCreateProvider);
    final notifier = ref.read(botCreateProvider.notifier);

    if (state.currentStep > 0) {
      notifier.previousStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _createBot() async {
    final notifier = ref.read(botCreateProvider.notifier);
    final success = await notifier.createBot();

    if (success && mounted) {
      toastification.show(
        context: context,
        title: const Text('Bot başarıyla oluşturuldu'),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(botCreateProvider).error;
      toastification.show(
        context: context,
        title: Text(error ?? 'Bir hata oluştu'),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(botCreateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Yeni Bot Oluştur',
        onBackPressed: _previousPage,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (state.currentStep + 1) / 4,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSymbolSelectionStep(state),
                _buildStrategySelectionStep(state),
                _buildConfigurationStep(state),
                _buildReviewStep(state),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                if (state.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Geri'),
                    ),
                  ),
                if (state.currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: state.isLoading
                        ? null
                        : (state.currentStep == 3 ? _createBot : _nextPage),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: state.isLoading
                            ? null
                            : const LinearGradient(
                                colors: [AppColors.primary, Color(0xFFE6C200)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: state.isLoading
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: state.isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: state.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  state.currentStep == 3
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.currentStep == 3
                                      ? 'Oluştur'
                                      : 'Devam Et',
                                  style: GoogleFonts.inter(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolSelectionStep(BotCreateState state) {
    final symbolsAsync = ref.watch(availableSymbolsProvider);
    final notifier = ref.read(botCreateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hangi coinde işlem yapacaksınız?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Coin ara (örn. BTC)',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: symbolsAsync.when(
              data: (symbols) {
                final filtered = symbols
                    .where(
                      (s) => s.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      ),
                    )
                    .toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final symbol = filtered[index];
                    final isSelected = state.selectedSymbol == symbol;

                    return GestureDetector(
                      onTap: () => notifier.selectSymbol(symbol),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                symbol.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              symbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategySelectionStep(BotCreateState state) {
    final notifier = ref.read(botCreateProvider.notifier);
    final strategiesAsync = ref.watch(strategiesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hangi stratejiyi kullanacaksınız?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: strategiesAsync.when(
              data: (allStrategies) {
                final strategies = allStrategies
                    .where(
                      (s) =>
                          s.category.toLowerCase() == 'simulation' ||
                          s.category.toLowerCase() == 'both',
                    )
                    .toList();

                if (strategies.isEmpty) {
                  return const Center(
                    child: Text(
                      'Uygun strateji bulunamadı',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: strategies.length,
                  itemBuilder: (context, index) {
                    final strategy = strategies[index];
                    final isSelected = state.selectedStrategyId == strategy.id;

                    return GestureDetector(
                      onTap: () => notifier.selectStrategy(strategy.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.05),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    strategy.name,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strategy.description,
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationStep(BotCreateState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bot Ayarları',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Investment Amount Section
          Consumer(
            builder: (context, ref, child) {
              final walletAsync = ref.watch(walletDetailsProvider);
              final availableBalance = walletAsync.when(
                data: (wallet) => wallet.availableBalance,
                loading: () => 0.0,
                error: (_, __) => 0.0,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'YATIRIM TUTARI (USDT)',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Kullanılabilir: \$${availableBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '\$',
                          style: GoogleFonts.robotoMono(
                            color: Colors.white38,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.robotoMono(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: '0.00',
                              hintStyle: TextStyle(color: Colors.white10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPercentageButton(availableBalance, 0.25, '% 25'),
                      const SizedBox(width: 8),
                      _buildPercentageButton(availableBalance, 0.50, '% 50'),
                      const SizedBox(width: 8),
                      _buildPercentageButton(availableBalance, 0.75, '% 75'),
                      const SizedBox(width: 8),
                      _buildPercentageButton(availableBalance, 1.00, '% 100'),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Interval Dropdown
          // Time Interval Section
          Text(
            'ZAMAN DİLİMİ',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.9,
                    builder: (_, controller) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Zaman Dilimi Seçin',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                controller: controller,
                                padding: const EdgeInsets.only(bottom: 24),
                                children: _intervalMap.entries.map((entry) {
                                  final value = entry.key;
                                  final text = entry.value;
                                  final isSelected = state.interval == value;
                                  return InkWell(
                                    onTap: () {
                                      ref
                                          .read(botCreateProvider.notifier)
                                          .updateConfig(interval: value);
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 24,
                                      ),
                                      color: isSelected
                                          ? AppColors.primary.withValues(
                                              alpha: 0.1,
                                            )
                                          : null,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            text,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white,
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check,
                                              color: AppColors.primary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _intervalMap[state.interval] ?? state.interval,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Risk Management Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceLight,
                  AppColors.surfaceLight.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RİSK YÖNETİMİ (OPSİYONEL)',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stop Loss
                CheckboxListTile(
                  value: state.stopLoss != null,
                  onChanged: (value) {
                    if (value == true) {
                      ref
                          .read(botCreateProvider.notifier)
                          .updateConfig(stopLoss: 2.5);
                    } else {
                      ref
                          .read(botCreateProvider.notifier)
                          .updateConfig(clearStopLoss: true);
                    }
                  },
                  activeColor: AppColors.primary,
                  checkColor: Colors.black,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Stop Loss',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Zararı durdurmak için seviye belirleyin',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),

                if (state.stopLoss != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Zarar Durdurma Oranı',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '%${state.stopLoss!.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white10,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: state.stopLoss!,
                            min: 0.5,
                            max: 50.0,
                            divisions: 99,
                            onChanged: (value) {
                              ref
                                  .read(botCreateProvider.notifier)
                                  .updateConfig(stopLoss: value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(color: Colors.white10),

                // Take Profit
                CheckboxListTile(
                  value: state.takeProfit != null,
                  onChanged: (value) {
                    if (value == true) {
                      ref
                          .read(botCreateProvider.notifier)
                          .updateConfig(takeProfit: 5.0);
                    } else {
                      ref
                          .read(botCreateProvider.notifier)
                          .updateConfig(clearTakeProfit: true);
                    }
                  },
                  activeColor: AppColors.success,
                  checkColor: Colors.black,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Take Profit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Kârı almak için hedef belirleyin',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),

                if (state.takeProfit != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kar Alma Oranı',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '%${state.takeProfit!.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.success,
                            inactiveTrackColor: Colors.white10,
                            thumbColor: AppColors.success,
                            overlayColor: AppColors.success.withValues(
                              alpha: 0.2,
                            ),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: state.takeProfit!,
                            min: 0.5,
                            max: 100.0,
                            divisions: 199,
                            onChanged: (value) {
                              ref
                                  .read(botCreateProvider.notifier)
                                  .updateConfig(takeProfit: value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Trailing Stop Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceLight,
                  AppColors.surfaceLight.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TRAILING STOP (OPSİYONEL)',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  value: state.isTrailingStop,
                  onChanged: (value) {
                    final isEnabled = value ?? false;
                    ref
                        .read(botCreateProvider.notifier)
                        .updateConfig(
                          isTrailingStop: isEnabled,
                          trailingStopDistance: isEnabled ? 1.0 : null,
                          clearTrailingStopDistance: !isEnabled,
                        );
                  },
                  activeColor: AppColors.primary,
                  checkColor: Colors.black,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.timeline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Trailing Stop Kullan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Kar arttıkça stop seviyesini yukarı taşır',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),

                if (state.isTrailingStop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Takip Mesafesi',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '%${(state.trailingStopDistance ?? 1.0).toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white10,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: state.trailingStopDistance ?? 1.0,
                            min: 0.5,
                            max: 10.0,
                            divisions: 19,
                            onChanged: (value) {
                              ref
                                  .read(botCreateProvider.notifier)
                                  .updateConfig(trailingStopDistance: value);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fiyat yükseldikçe stop seviyesi de otomatik olarak yükselir. Böylece kârınız korunur ve maksimum kazanç hedeflenir.',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(BotCreateState state) {
    final strategiesAsync = ref.watch(strategiesProvider);

    // Get strategy name from ID
    String strategyName = state.selectedStrategyId ?? '-';
    strategiesAsync.whenData((strategies) {
      final strategy = strategies
          .where((s) => s.id == state.selectedStrategyId)
          .firstOrNull;
      if (strategy != null) {
        strategyName = strategy.name;
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Özet ve Onay',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryItem('Coin', state.selectedSymbol ?? '-'),
                  _buildSummaryItem('Strateji', strategyName),
                  _buildSummaryItem(
                    'Zaman Aralığı',
                    _intervalMap[state.interval] ?? state.interval,
                  ),
                  _buildSummaryItem('Yatırım Tutarı', '${state.amount} USDT'),
                  const Divider(color: Colors.white10),
                  _buildSummaryItem(
                    'Stop Loss',
                    state.stopLoss != null
                        ? '%${state.stopLoss!.toStringAsFixed(1)}'
                        : 'Kapalı',
                    isSecondary: state.stopLoss == null,
                  ),
                  _buildSummaryItem(
                    'Take Profit',
                    state.takeProfit != null
                        ? '%${state.takeProfit!.toStringAsFixed(1)}'
                        : 'Kapalı',
                    isSecondary: state.takeProfit == null,
                  ),
                  _buildSummaryItem(
                    'Trailing Stop',
                    state.isTrailingStop ? 'Aktif' : 'Pasif',
                    isSecondary: !state.isTrailingStop,
                  ),
                  if (state.isTrailingStop)
                    _buildSummaryItem(
                      'Takip Mesafesi',
                      '%${state.trailingStopDistance?.toStringAsFixed(1) ?? '0'}',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    bool isSecondary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSecondary ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageButton(
    double availableBalance,
    double percentage,
    String label,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          final amount = availableBalance * percentage;
          _amountController.text = amount.toStringAsFixed(2);
          ref.read(botCreateProvider.notifier).updateConfig(amount: amount);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
