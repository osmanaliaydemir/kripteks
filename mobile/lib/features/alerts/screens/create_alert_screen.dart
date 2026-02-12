import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/providers/market_data_provider.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';

class CreateAlertScreen extends ConsumerStatefulWidget {
  const CreateAlertScreen({super.key});

  @override
  ConsumerState<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends ConsumerState<CreateAlertScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Common State
  String? _selectedSymbol = 'BTCUSDT';
  bool _isLoading = false;

  // Form State
  AlertType _selectedType = AlertType.price;
  final _valueController = TextEditingController();
  AlertCondition _condition = AlertCondition.above;

  // Technical & Market Movement State
  String _selectedIndicator = 'RSI';
  String _selectedTimeframe = '1h';
  final _periodController = TextEditingController(text: '14'); // For RSI/ATR
  final _thresholdController =
      TextEditingController(); // For Volume/Price Change

  final List<String> _timeframes = ['15m', '1h', '4h', '1d'];
  final List<String> _indicators = ['RSI', 'MACD', 'EMA_CROSS', 'BOLLINGER'];
  final List<String> _marketMovements = [
    'VOLUME_SPIKE',
    'PRICE_CHANGE',
    'VOLATILITY',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedType = AlertType.price;
              break;
            case 1:
              _selectedType = AlertType.technical;
              _selectedIndicator =
                  _indicators.first; // Reset to first technical indicator
              break;
            case 2:
              _selectedType = AlertType.marketMovement;
              _selectedIndicator =
                  _marketMovements.first; // Reset to first market movement
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valueController.dispose();
    _periodController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSymbol == null) return;

    setState(() => _isLoading = true);

    try {
      String? parameters;
      double targetValue = 0;

      // Prepare payload based on Type
      if (_selectedType == AlertType.price) {
        targetValue = double.parse(_valueController.text.replaceAll(',', '.'));
      } else if (_selectedType == AlertType.technical) {
        targetValue =
            double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;

        final paramsMap = <String, dynamic>{};
        if (_selectedIndicator == 'RSI') {
          paramsMap['period'] = int.tryParse(_periodController.text) ?? 14;
        }
        // Add more indicator-specific parameters here if needed
        parameters = jsonEncode(paramsMap);
      } else if (_selectedType == AlertType.marketMovement) {
        targetValue = double.parse(
          _thresholdController.text.replaceAll(',', '.'),
        );
      }

      final request = CreateAlertDto(
        symbol: _selectedSymbol!.toUpperCase(),
        type: _selectedType,
        targetValue: targetValue,
        condition: _condition,
        indicatorName: _selectedType != AlertType.price
            ? _selectedIndicator
            : null,
        timeframe: _selectedType != AlertType.price ? _selectedTimeframe : null,
        parameters: parameters,
      );

      await ref.read(alertsProvider.notifier).createAlert(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarm başarıyla oluşturuldu!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availablePairsAsync = ref.watch(availablePairsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Yeni Alarm Oluştur'),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('PARİTE SEÇİMİ'),
                  const SizedBox(height: 12),
                  availablePairsAsync.when(
                    data: (pairs) {
                      if (_selectedSymbol != null &&
                          !pairs.contains(_selectedSymbol)) {
                        _selectedSymbol = pairs.isNotEmpty ? pairs.first : null;
                      } else if (_selectedSymbol == null && pairs.isNotEmpty) {
                        _selectedSymbol = pairs.first;
                      }
                      return _buildSymbolSelector();
                    },
                    loading: () => const Center(
                      child: LinearProgressIndicator(color: AppColors.primary),
                    ),
                    error: (err, stack) => Text(
                      'Pariteler yüklenemedi',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('ALARM TÜRÜ'),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                  const SizedBox(height: 24),

                  _buildFormContent(),

                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Fiyat'),
          Tab(text: 'Teknik'),
          Tab(text: 'Piyasa'),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    if (_selectedType == AlertType.price) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('KOŞUL VE DEĞER'),
          const SizedBox(height: 12),
          _buildConditionDropdown(),
          const SizedBox(height: 16),
          _buildNumberInput(
            _valueController,
            'Hedef Fiyat',
            icon: Icons.attach_money,
          ),
        ],
      );
    } else if (_selectedType == AlertType.technical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('İNDİKATÖR AYARLARI'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  _indicators
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  _selectedIndicator,
                  (v) => setState(() => _selectedIndicator = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  _timeframes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  _selectedTimeframe,
                  (v) => setState(() => _selectedTimeframe = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedIndicator == 'RSI') ...[
            _buildNumberInput(
              _periodController,
              'Periyot (Varsayılan 14)',
              icon: Icons.timeline,
            ),
            const SizedBox(height: 16),
            _buildConditionDropdown(),
            const SizedBox(height: 16),
            _buildNumberInput(
              _valueController,
              'RSI Değeri (0-100)',
              icon: Icons.numbers,
            ),
          ] else if (_selectedIndicator == 'MACD') ...[
            _buildConditionDropdown(),
            const SizedBox(height: 16),
            _buildNumberInput(
              _valueController,
              'MACD Değeri',
              icon: Icons.numbers,
            ),
          ] else if (_selectedIndicator == 'EMA_CROSS') ...[
            _buildConditionDropdown(),
            const SizedBox(height: 16),
            _buildNumberInput(
              _valueController,
              'EMA Değeri',
              icon: Icons.numbers,
            ),
          ] else if (_selectedIndicator == 'BOLLINGER') ...[
            _buildConditionDropdown(),
            const SizedBox(height: 16),
            _buildNumberInput(
              _valueController,
              'Bollinger Bandı Değeri',
              icon: Icons.numbers,
            ),
          ] else ...[
            const Text(
              'Bu indikatör için varsayılan ayarlar kullanılacak.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ],
      );
    } else {
      // Market Movement
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('FİLTRE AYARLARI'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  _marketMovements
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  _selectedIndicator,
                  (v) => setState(() => _selectedIndicator = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  _timeframes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  _selectedTimeframe,
                  (v) => setState(() => _selectedTimeframe = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNumberInput(
            _thresholdController,
            _selectedIndicator == 'PRICE_CHANGE'
                ? 'Yüzde Değişim (%)'
                : 'Artış Oranı (%)',
            icon: Icons.percent,
          ),
        ],
      );
    }
  }

  Widget _buildDropdown<T>(
    List<DropdownMenuItem<T>> items,
    T value,
    void Function(T?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return _buildDropdown(
      const [
        DropdownMenuItem(
          value: AlertCondition.above,
          child: Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.success, size: 20),
              SizedBox(width: 12),
              Text('Büyükse (>)'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: AlertCondition.below,
          child: Row(
            children: [
              Icon(Icons.trending_down, color: AppColors.error, size: 20),
              SizedBox(width: 12),
              Text('Küçükse (<)'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: AlertCondition.crossOver,
          child: Row(
            children: [
              Icon(Icons.call_made, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text('Yukarı Kesen'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: AlertCondition.crossUnder,
          child: Row(
            children: [
              Icon(Icons.call_received, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text('Aşağı Kesen'),
            ],
          ),
        ),
      ],
      _condition,
      (val) {
        if (val != null) setState(() => _condition = val);
      },
    );
  }

  Widget _buildNumberInput(
    TextEditingController controller,
    String label, {
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon ?? Icons.numbers, color: AppColors.primary),
        labelStyle: const TextStyle(color: Colors.white38),
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
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Değer giriniz';
        if (double.tryParse(value.replaceAll(',', '.')) == null) {
          return 'Geçerli sayı giriniz';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                'Alarm Oluştur',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned(
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

  Widget _buildSymbolSelector() {
    return InkWell(
      onTap: () => _showSymbolSelectionSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.currency_bitcoin_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parite',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedSymbol ?? 'Parite Seçiniz',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  void _showSymbolSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            String searchQuery = '';

            return StatefulBuilder(
              builder: (context, setStateSheet) {
                return Consumer(
                  builder: (context, ref, child) {
                    final pairsAsync = ref.watch(liveMarketDataProvider);
                    return pairsAsync.when(
                      data: (pairs) {
                        final filteredPairs = pairs
                            .where(
                              (pair) => pair.symbol.toLowerCase().contains(
                                searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                        return Column(
                          children: [
                            // Handle Bar
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Header & Close
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Parite Seçiniz',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Search Input
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Ara...',
                                  hintStyle: const TextStyle(
                                    color: Colors.white38,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white38,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.05,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  setStateSheet(() => searchQuery = value);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // List
                            Expanded(
                              child: ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredPairs.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final pair = filteredPairs[index];
                                  final isSelected =
                                      pair.symbol == _selectedSymbol;

                                  return InkWell(
                                    onTap: () {
                                      setState(
                                        () => _selectedSymbol = pair.symbol,
                                      );
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.05,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Checkmark (Left)
                                          if (isSelected)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                right: 12,
                                              ),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),

                                          // Symbol Name
                                          Text(
                                            pair.symbol,
                                            style: GoogleFonts.inter(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),

                                          const Spacer(),

                                          // Price (Right)
                                          Text(
                                            () {
                                              final price = pair.price;
                                              if (price == 0) return '\$0.00';
                                              if (price < 0.00001) {
                                                return '\$${price.toStringAsFixed(8)}';
                                              }
                                              if (price < 0.01) {
                                                return '\$${price.toStringAsFixed(6)}';
                                              }
                                              if (price < 1) {
                                                return '\$${price.toStringAsFixed(4)}';
                                              }
                                              return '\$${price.toStringAsFixed(2)}';
                                            }(),
                                            style: GoogleFonts.inter(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white70,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          'Hata: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
