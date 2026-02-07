import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Yeni Backtest',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Parite ve Strateji'),
              const SizedBox(height: 12),

              // Symbol Input
              TextFormField(
                controller: _symbolController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Parite (Örn: BTCUSDT)'),
                validator: (value) =>
                    value!.isEmpty ? 'Parite gereklidir' : null,
              ),
              const SizedBox(height: 16),

              // Strategy Dropdown
              strategiesAsync.when(
                data: (strategies) {
                  // Select first if none selected
                  if (_selectedStrategyId == null && strategies.isNotEmpty) {
                    _selectedStrategyId = strategies.first.id;
                  }

                  return InputDecorator(
                    decoration: _inputDecoration('Strateji'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStrategyId,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        items: strategies
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
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text(
                  'Stratejiler yüklenemedi: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),

              // Interval Dropdown
              InputDecorator(
                decoration: _inputDecoration('Zaman Aralığı'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedInterval,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: _intervals
                        .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedInterval = val!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Ayarlar'),
              const SizedBox(height: 12),

              // Initial Balance
              TextFormField(
                controller: _initialBalanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Başlangıç Bakiyesi (\$)'),
                validator: (value) =>
                    value!.isEmpty ? 'Bakiye gereklidir' : null,
              ),
              const SizedBox(height: 16),

              // Date Range
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
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white54,
                    size: 16,
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
              const SizedBox(height: 32),

              // Run Button
              ElevatedButton(
                onPressed: isLoading ? null : _runBacktest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Testi Başlat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
    );
  }

  void _runBacktest() {
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
            content: Text('Lütfen strateji seçin'),
            backgroundColor: Colors.red,
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
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFF59E0B),
                  onPrimary: Colors.black,
                  surface: Color(0xFF1E293B),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF59E0B),
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }
}
