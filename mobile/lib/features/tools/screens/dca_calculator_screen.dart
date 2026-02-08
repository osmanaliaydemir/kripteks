import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';

class DcaCalculatorScreen extends StatefulWidget {
  const DcaCalculatorScreen({super.key});

  @override
  State<DcaCalculatorScreen> createState() => _DcaCalculatorScreenState();
}

class _DcaCalculatorScreenState extends State<DcaCalculatorScreen> {
  final List<DcaEntry> _entries = [
    DcaEntry(
      priceController: TextEditingController(),
      amountController: TextEditingController(),
    ),
    DcaEntry(
      priceController: TextEditingController(),
      amountController: TextEditingController(),
    ),
  ];

  double _averagePrice = 0;
  double _totalAmount = 0;
  double _totalCost = 0;

  void _calculate() {
    double totalCost = 0;
    double totalAmount = 0;

    for (var entry in _entries) {
      final price = double.tryParse(entry.priceController.text) ?? 0;
      final amount = double.tryParse(entry.amountController.text) ?? 0;
      if (price > 0 && amount > 0) {
        totalCost += (price * amount);
        totalAmount += amount;
      }
    }

    setState(() {
      _totalCost = totalCost;
      _totalAmount = totalAmount;
      _averagePrice = totalAmount > 0 ? totalCost / totalAmount : 0;
    });
  }

  void _addEntry() {
    setState(() {
      _entries.add(
        DcaEntry(
          priceController: TextEditingController(),
          amountController: TextEditingController(),
        ),
      );
    });
  }

  void _removeEntry(int index) {
    if (_entries.length > 1) {
      setState(() {
        _entries[index].priceController.dispose();
        _entries[index].amountController.dispose();
        _entries.removeAt(index);
        _calculate();
      });
    }
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.priceController.dispose();
      entry.amountController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Maliyet (DCA) Hesaplayıcı',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alım Kademeleri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addEntry,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Kademe Ekle'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildEntryRow(index),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Ortalama Maliyet',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_averagePrice.toStringAsFixed(4)}',
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Toplam Adet', _totalAmount.toStringAsFixed(2)),
              _buildSummaryItem(
                'Toplam Maliyet',
                '\$${_totalCost.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEntryRow(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white05),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMiniField('Fiyat', _entries[index].priceController),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMiniField('Miktar', _entries[index].amountController),
          ),
          if (_entries.length > 1)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: () => _removeEntry(index),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
      ),
      onChanged: (_) => _calculate(),
    );
  }
}

class DcaEntry {
  final TextEditingController priceController;
  final TextEditingController amountController;

  DcaEntry({required this.priceController, required this.amountController});
}
