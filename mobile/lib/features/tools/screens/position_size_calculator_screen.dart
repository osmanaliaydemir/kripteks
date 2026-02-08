import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';

class PositionSizeCalculatorScreen extends StatefulWidget {
  const PositionSizeCalculatorScreen({super.key});

  @override
  State<PositionSizeCalculatorScreen> createState() =>
      _PositionSizeCalculatorScreenState();
}

class _PositionSizeCalculatorScreenState
    extends State<PositionSizeCalculatorScreen> {
  final _balanceController = TextEditingController();
  final _riskPercentController = TextEditingController();
  final _entryPriceController = TextEditingController();
  final _stopLossPriceController = TextEditingController();

  double _positionSize = 0;
  double _riskAmount = 0;
  double _units = 0;

  void _calculate() {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final riskPercent = double.tryParse(_riskPercentController.text) ?? 0;
    final entry = double.tryParse(_entryPriceController.text) ?? 0;
    final stop = double.tryParse(_stopLossPriceController.text) ?? 0;

    if (balance > 0 &&
        riskPercent > 0 &&
        entry > 0 &&
        stop > 0 &&
        entry != stop) {
      final riskAmt = balance * (riskPercent / 100);
      final stopLossDist = (entry - stop).abs();
      final unts = riskAmt / stopLossDist;

      setState(() {
        _riskAmount = riskAmt;
        _units = unts;
        _positionSize = unts * entry;
      });
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _riskPercentController.dispose();
    _entryPriceController.dispose();
    _stopLossPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Pozisyon Büyüklüğü',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMainResultCard(),
            const SizedBox(height: 32),
            _buildInputGrid(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Hesapla',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'İdeal Pozisyon Büyüklüğü',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_positionSize.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniResult(
                'Risk Tutarı',
                '\$${_riskAmount.toStringAsFixed(2)}',
              ),
              Container(width: 1, height: 30, color: Colors.white12),
              _buildMiniResult('Alım Miktarı', _units.toStringAsFixed(4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniResult(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildInputGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Hesap Bakiyesi',
                _balanceController,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Risk Oranı (%)',
                _riskPercentController,
                Icons.warning_amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Giriş Fiyatı',
                _entryPriceController,
                Icons.login,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Stop Fiyatı',
                _stopLossPriceController,
                Icons.cancel_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          onChanged: (_) => _calculate(),
        ),
      ],
    );
  }
}
