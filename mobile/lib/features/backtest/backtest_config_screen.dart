import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/backtest_provider.dart';
import 'models/backtest_model.dart';
import 'backtest_result_screen.dart';

class BacktestConfigScreen extends ConsumerStatefulWidget {
  const BacktestConfigScreen({super.key});

  @override
  ConsumerState<BacktestConfigScreen> createState() =>
      _BacktestConfigScreenState();
}

class _BacktestConfigScreenState extends ConsumerState<BacktestConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController(text: 'BTCUSDT');
  String? _selectedStrategyId;
  String _selectedInterval = '1h';
  final _initialBalanceController = TextEditingController(text: '1000');

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _intervals = ['15m', '1h', '4h', '1d', '1w'];

  @override
  Widget build(BuildContext context) {
    final strategiesAsync = ref.watch(strategiesProvider);
    final backtestRunState = ref.watch(backtestRunProvider);
    final isLoading = backtestRunState.isLoading;

    // Listen for success to navigate
    ref.listen(backtestRunProvider, (previous, next) {
      if (next.hasValue && next.value != null && !next.isLoading) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BacktestResultScreen(result: next.value!),
          ),
        );
      }
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${next.error}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Simülasyon'),
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 0.8,
                  colors: [AppColors.primaryTransparent, AppColors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('PARİTE VE STRATEJİ'),
                  const SizedBox(height: 12),

                  // Symbol Input
                  TextFormField(
                    controller: _symbolController,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _inputDecoration(
                      'Parite (Örn: BTCUSDT)',
                      Icons.currency_bitcoin_rounded,
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Parite gereklidir' : null,
                  ),
                  const SizedBox(height: 16),

                  // Strategy Dropdown
                  strategiesAsync.when(
                    data: (strategies) {
                      final simulationStrategies = strategies
                          .where(
                            (s) =>
                                s.category == 'simulation' ||
                                s.category == 'both',
                          )
                          .toList();
                      if (_selectedStrategyId == null &&
                          simulationStrategies.isNotEmpty) {
                        _selectedStrategyId = simulationStrategies.first.id;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStrategyId,
                            dropdownColor: AppColors.surfaceLight,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.primary,
                            ),
                            items: simulationStrategies
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedStrategyId = val),
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const LinearProgressIndicator(color: AppColors.primary),
                    error: (err, stack) => Text(
                      'Stratejiler yüklenemedi',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interval & Balance Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedInterval,
                              dropdownColor: AppColors.surfaceLight,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.timer_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              items: _intervals
                                  .map(
                                    (i) => DropdownMenuItem(
                                      value: i,
                                      child: Text(i),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedInterval = val!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _initialBalanceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: _inputDecoration(
                            'Bakiye (\$)',
                            Icons.account_balance_wallet_outlined,
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Bakiye gereklidir' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('TARİH ARALIĞI'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Başlangıç',
                          selectedDate: _startDate,
                          onSelect: (date) => setState(() => _startDate = date),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Bitiş',
                          selectedDate: _endDate,
                          onSelect: (date) => setState(() => _endDate = date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Run Button
                  Hero(
                    tag: 'backtest_btn',
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _runBacktest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Simülasyonu Başlat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  void _runBacktest() {
    print(
      'Backtest: Running with strategy $_selectedStrategyId on ${_symbolController.text}',
    );
    if (_formKey.currentState!.validate() && _selectedStrategyId != null) {
      final request = BacktestRequest(
        symbol: _symbolController.text.toUpperCase(),
        strategyId: _selectedStrategyId!,
        interval: _selectedInterval,
        startDate: _startDate,
        endDate: _endDate,
        initialBalance: double.parse(_initialBalanceController.text),
      );

      ref.read(backtestRunProvider.notifier).runBacktest(request);
    } else {
      if (_selectedStrategyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen bir strateji seçin'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Colors.black,
                surface: AppColors.surfaceLight,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) onSelect(date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        size: 18,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
