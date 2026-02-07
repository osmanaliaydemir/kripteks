import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers/wallet_provider.dart';
import 'models/wallet_model.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletDetailsProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Cüzdan',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletDetailsProvider);
          ref.invalidate(walletTransactionsProvider);
        },
        color: const Color(0xFFF59E0B),
        backgroundColor: const Color(0xFF1E293B),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              walletAsync.when(
                data: (wallet) => _buildBalanceCard(wallet),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                ),
                error: (err, _) => _buildErrorState(err.toString()),
              ),
              const SizedBox(height: 24),

              // Transactions Title
              Text(
                'İşlem Geçmişi',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Transactions List
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Henüz işlem yok',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildTransactionItem(transactions[index])
                            .animate()
                            .fadeIn(delay: (100 * index).ms)
                            .slideX(begin: 0.2, end: 0),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  ),
                ),
                error: (err, _) => Text(
                  'Hata: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WalletDetails wallet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Toplam Varlık',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${wallet.currentBalance.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Kullanılabilir',
                  wallet.availableBalance,
                  const Color(0xFF10B981),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _buildBalanceItem(
                  'Bloke (Botlarda)',
                  wallet.lockedBalance,
                  Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBalanceItem(
            'Aktif PNL',
            wallet.totalPnl,
            wallet.totalPnl >= 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            isPnl: true,
          ),
        ],
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildBalanceItem(
    String label,
    double amount,
    Color color, {
    bool isPnl = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '${isPnl && amount > 0 ? "+" : ""}\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    IconData icon;
    Color color;
    Color iconBgColor;
    String prefix = '';
    String defaultTitle = '';

    // Determine config based on type
    switch (tx.type) {
      case TransactionType.Deposit:
        icon = Icons.arrow_downward;
        color = const Color(0xFF10B981);
        iconBgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        prefix = '+';
        defaultTitle = 'Yatırma';
        break;
      case TransactionType.Withdraw:
        icon = Icons.arrow_upward;
        color = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        prefix = '-';
        defaultTitle = 'Çekme';
        break;
      case TransactionType.BotInvestment:
        // Red/Pinkish for Investment (Money Out)
        icon = Icons.north_east; // Arrow Up-Right
        color = Colors
            .white; // Text color listed as white in screenshot for negative
        iconBgColor = const Color(
          0xFFF43F5E,
        ).withValues(alpha: 0.1); // Rose-500 bg
        // If amount is already negative, don't add another '-'
        prefix = '';
        defaultTitle = 'Otomatik Alım';
        break;
      case TransactionType.BotReturn:
        // Green for Return (Money In)
        icon = Icons.south_west; // Arrow Down-Left
        color = const Color(0xFF10B981); // Emerald
        iconBgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        prefix = '+';
        defaultTitle = 'Bot Kapatıldı';
        break;
      case TransactionType.Fee:
        icon = Icons.remove;
        color = Colors.white70;
        iconBgColor = Colors.white10;
        prefix = '-';
        defaultTitle = 'İşlem Ücreti';
        break;
    }

    // Use description from API if available and robust, otherwise use default title
    // If description is just the enum name (e.g. "BotInvestment"), use default title
    String title = tx.description;
    if (title.isEmpty ||
        title == 'BotInvestment' ||
        title == 'BotReturn' ||
        title == 'Deposit' ||
        title == 'Withdraw') {
      title = defaultTitle;
    }

    // Icon Color override
    Color iconColor = (tx.type == TransactionType.BotInvestment)
        ? const Color(0xFFF43F5E)
        : (tx.type == TransactionType.BotReturn)
        ? const Color(0xFF10B981)
        : color;

    // Amount Color: Green for positive, White for negative (BotInvestment is negative flow)
    Color amountColor = (prefix == '+')
        ? const Color(0xFF10B981)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm:ss').format(tx.createdAt),
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${tx.amount.toStringAsFixed(2)}',
                style: GoogleFonts.jetBrainsMono(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'USDT',
                style: GoogleFonts.inter(
                  color: amountColor.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
