import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'providers/wallet_provider.dart';
import 'models/wallet_model.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletDetailsProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: AppLocalizations.of(context)!.wallet,
        showBackButton: false,
      ),
      body: Stack(
        children: [
          // Background Gradient (Same as Login)
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
                  colors: [
                    Color(0x40F59E0B), // Amber with transparency
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 30),
            child: RefreshIndicator(
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
                        child: CircularProgressIndicator(
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      error: (err, _) => _buildErrorState(err.toString()),
                    ),
                    const SizedBox(height: 24),

                    // Transactions Title
                    Text(
                      AppLocalizations.of(context)!.transactionHistory,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Transaction Filter Tabs
                    _buildTransactionTabs(),
                    const SizedBox(height: 12),

                    // Transactions List
                    transactionsAsync.when(
                      data: (transactions) {
                        final filteredTransactions = _filterTransactions(
                          transactions,
                        );

                        if (filteredTransactions.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                AppLocalizations.of(context)!.noTransactions,
                                style: const TextStyle(color: Colors.white38),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTransactions.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _buildTransactionItem(filteredTransactions[index])
                                  .animate()
                                  .fadeIn(delay: (100 * index).ms)
                                  .slideX(begin: 0.2, end: 0),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Hata: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildTabButton(AppLocalizations.of(context)!.all, 0),
          const SizedBox(width: 4),
          _buildTabButton(AppLocalizations.of(context)!.deposit, 1),
          const SizedBox(width: 4),
          _buildTabButton(AppLocalizations.of(context)!.withdraw, 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  List<WalletTransaction> _filterTransactions(
    List<WalletTransaction> transactions,
  ) {
    if (_selectedTabIndex == 0) {
      // Hepsi
      return transactions;
    } else if (_selectedTabIndex == 1) {
      // Yatırma (Girişler)
      return transactions
          .where(
            (tx) =>
                tx.type == TransactionType.Deposit ||
                tx.type == TransactionType.BotReturn,
          )
          .toList();
    } else {
      // Çekim (Çıkışlar)
      return transactions
          .where(
            (tx) =>
                tx.type == TransactionType.Withdraw ||
                tx.type == TransactionType.BotInvestment ||
                tx.type == TransactionType.Fee,
          )
          .toList();
    }
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
          Text(
            AppLocalizations.of(context)!.totalBalance,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
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
                  AppLocalizations.of(context)!.available,
                  wallet.availableBalance,
                  const Color(0xFF10B981),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _buildBalanceItem(
                  AppLocalizations.of(context)!.locked,
                  wallet.lockedBalance,
                  Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBalanceItem(
            AppLocalizations.of(context)!.activePnl,
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
        defaultTitle = AppLocalizations.of(context)!.deposit;
        break;
      case TransactionType.Withdraw:
        icon = Icons.arrow_upward;
        color = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        prefix = '-';
        defaultTitle = AppLocalizations.of(context)!.withdraw;
        break;
      case TransactionType.BotInvestment:
        // Red/Pinkish for Investment (Money Out)
        icon = Icons.north_east; // Arrow Up-Right
        color = Colors.white;
        iconBgColor = const Color(
          0xFFF43F5E,
        ).withValues(alpha: 0.1); // Rose-500 bg
        prefix = '';
        defaultTitle = AppLocalizations.of(context)!.botInvestment;
        break;
      case TransactionType.BotReturn:
        // Green for Return (Money In)
        icon = Icons.south_west; // Arrow Down-Left
        color = const Color(0xFF10B981); // Emerald
        iconBgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        prefix = '+';
        defaultTitle = AppLocalizations.of(context)!.botReturn;
        break;
      case TransactionType.Fee:
        icon = Icons.remove;
        color = Colors.white70;
        iconBgColor = Colors.white10;
        prefix = '-';
        defaultTitle = AppLocalizations.of(context)!.fee;
        break;
    }

    String title = tx.description;
    if (title.isEmpty ||
        title == 'BotInvestment' ||
        title == 'BotReturn' ||
        title == 'Deposit' ||
        title == 'Withdraw') {
      title = defaultTitle;
    }

    Color iconColor = (tx.type == TransactionType.BotInvestment)
        ? const Color(0xFFF43F5E)
        : (tx.type == TransactionType.BotReturn)
        ? const Color(0xFF10B981)
        : color;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm:ss').format(tx.createdAt),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(error, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
