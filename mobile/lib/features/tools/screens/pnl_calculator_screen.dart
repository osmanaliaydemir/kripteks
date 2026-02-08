import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';

class PnlCalculatorScreen extends StatefulWidget {
  const PnlCalculatorScreen({super.key});

  @override
  State<PnlCalculatorScreen> createState() => _PnlCalculatorScreenState();
}

class _PnlCalculatorScreenState extends State<PnlCalculatorScreen> {
  final _entryController = TextEditingController();
  final _exitController = TextEditingController();
  final _amountController = TextEditingController();

  double _pnlAmount = 0;
  double _pnlPercent = 0;
  double _totalValue = 0;

  void _calculate() {
    final entry = double.tryParse(_entryController.text) ?? 0;
    final exit = double.tryParse(_exitController.text) ?? 0;
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (entry > 0 && amount > 0) {
      setState(() {
        _pnlAmount = (exit - entry) * amount;
        _pnlPercent = ((exit - entry) / entry) * 100;
        _totalValue = exit * amount;
      });
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _pnlAmount >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Kar/Zarar Hesaplayıcı',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultCard(isPositive, color),
            const SizedBox(height: 32),
            _buildInputFields(),
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

  Widget _buildResultCard(bool isPositive, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            isPositive ? 'Potansiyel Kâr' : 'Potansiyel Zarar',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? "+" : ""}\$${_pnlAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isPositive ? "+" : ""}${_pnlPercent.toStringAsFixed(2)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Değer',
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                '\$${_totalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _buildTextField('Giriş Fiyatı', _entryController, Icons.login),
        const SizedBox(height: 16),
        _buildTextField('Çıkış Fiyatı (Hedef)', _exitController, Icons.logout),
        const SizedBox(height: 16),
        _buildTextField(
          'Miktar (Adet)',
          _amountController,
          Icons.account_balance_wallet_outlined,
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            hintText: '0.00',
            hintStyle: const TextStyle(color: Colors.white24),
          ),
          onChanged: (_) => _calculate(),
        ),
      ],
    );
  }
}
