import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/bot_provider.dart';
import 'models/bot_model.dart';

class BotListScreen extends ConsumerStatefulWidget {
  const BotListScreen({super.key});

  @override
  ConsumerState<BotListScreen> createState() => _BotListScreenState();
}

class _BotListScreenState extends ConsumerState<BotListScreen> {
  String _selectedTab = 'Aktif Botlar';
  String _activeFilter = 'Hepsi';

  @override
  Widget build(BuildContext context) {
    final botListAsync = ref.watch(botListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const AppHeader(title: 'Botlarım', showBackButton: false),
      body: botListAsync.when(
        data: (bots) {
          final activeBots = bots
              .where(
                (b) => b.status == 'Running' || b.status == 'WaitingForEntry',
              )
              .toList();
          final historyBots = bots
              .where((b) => b.status == 'Stopped' || b.status == 'Completed')
              .toList();

          final inPositionCount = activeBots
              .where((b) => b.status == 'Running')
              .length;
          final waitingCount = activeBots
              .where((b) => b.status == 'WaitingForEntry')
              .length;

          List<Bot> displayedBots = [];
          if (_selectedTab == 'Aktif Botlar') {
            if (_activeFilter == 'Hepsi') {
              displayedBots = activeBots;
            } else if (_activeFilter == 'Pozisyonda') {
              displayedBots = activeBots
                  .where((b) => b.status == 'Running')
                  .toList();
            } else if (_activeFilter == 'Sinyal Bekleniyor') {
              displayedBots = activeBots
                  .where((b) => b.status == 'WaitingForEntry')
                  .toList();
            }
          } else {
            displayedBots = historyBots;
          }

          return Column(
            children: [
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        'Aktif Botlar',
                        _selectedTab == 'Aktif Botlar',
                        count: activeBots.length,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        'Geçmiş',
                        _selectedTab == 'Geçmiş',
                        count: historyBots.length,
                      ),
                    ),
                  ],
                ),
              ),

              // Filters
              if (_selectedTab == 'Aktif Botlar')
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip('Hepsi', activeBots.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pozisyonda', inPositionCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sinyal Bekleniyor', waitingCount),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: displayedBots.isEmpty
                    ? Center(
                        child: Text(
                          'Bot bulunamadı',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.refresh(botListProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedBots.length,
                          itemBuilder: (context, index) {
                            return _BotCardItem(
                              bot: displayedBots[index],
                              onStop: () =>
                                  _showStopConfirmation(displayedBots[index]),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Hata: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, {int? count}) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = title;
        _activeFilter = 'Hepsi';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: label == 'Pozisyonda'
                    ? AppColors.success
                    : label == 'Sinyal Bekleniyor'
                    ? AppColors.primary
                    : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopConfirmation(Bot bot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Botu Durdur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${bot.symbol} botunu durdurmak istediğinize emin misiniz? Açık pozisyonlar piyasa fiyatından kapatılacaktır.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(botServiceProvider).stopBot(bot.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Durdur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotCardItem extends StatefulWidget {
  final Bot bot;
  final VoidCallback onStop;

  const _BotCardItem({required this.bot, required this.onStop});

  @override
  State<_BotCardItem> createState() => _BotCardItemState();
}

class _BotCardItemState extends State<_BotCardItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bot = widget.bot;
    final isPositive = bot.pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Text(
                      bot.symbol.isNotEmpty ? bot.symbol.substring(0, 1) : '?',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bot.symbol,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(bot.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusLabel(bot.status),
                            style: GoogleFonts.inter(
                              color: _getStatusColor(
                                bot.status,
                              ).withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPositive ? '+' : ''}${bot.pnl.toStringAsFixed(2)}\$',
                      style: GoogleFonts.inter(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${bot.pnlPercent < 0 ? '-' : ''}%${bot.pnlPercent.abs().toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ROI',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: _buildSmallChip(
                          bot.strategyName.toUpperCase().contains('STRATEGY-')
                              ? bot.strategyName.toUpperCase().replaceFirst(
                                  'STRATEGY-',
                                  '',
                                )
                              : bot.strategyName.toUpperCase(),
                          color: Colors.white.withValues(alpha: 0.05),
                          textColor: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildSmallChip(
                        bot.interval.toUpperCase(),
                        color: AppColors.primary.withValues(alpha: 0.1),
                        textColor: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      _buildSmallChip(
                        '${bot.amount.toInt()}\$',
                        color: Colors.white.withValues(alpha: 0.03),
                        textColor: Colors.white38,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    _buildMinimalAction(
                      icon: Icons.show_chart_rounded,
                      onTap: () => _openTradingView(bot.symbol),
                    ),
                    const SizedBox(width: 6),
                    _buildMinimalAction(
                      icon: Icons.stop_rounded,
                      color: AppColors.error.withValues(alpha: 0.1),
                      iconColor: AppColors.error,
                      onTap: widget.onStop,
                    ),
                    const SizedBox(width: 6),
                    _buildMinimalAction(
                      icon: Icons.keyboard_arrow_right_rounded,
                      onTap: () => context.push('/bots/${bot.id}'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                onExpansionChanged: (value) =>
                    setState(() => _isExpanded = value),
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(
                  'İŞLEM KAYITLARI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                trailing: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white12,
                  size: 20,
                ),
                children: [
                  if (bot.logs != null && bot.logs!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: bot.logs!.take(3).map((log) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  _formatTime(log.timestamp),
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(
    String label, {
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: textColor.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalAction({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Future<void> _openTradingView(String symbol) async {
    try {
      // 1. Try to open directly in the TradingView App using custom scheme
      final appUrl = Uri.parse('tradingview://chart?symbol=BINANCE:$symbol');

      // Attempt to launch the app scheme
      final bool launchedApp = await launchUrl(
        appUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launchedApp) {
        // 2. Fallback to Browser if app is not installed or doesn't support the scheme
        final webUrl = Uri.parse(
          'https://tr.tradingview.com/chart/RbphTzbt/?symbol=BINANCE:$symbol',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // 3. Last fallback: try browser directly if first attempt threw error
      try {
        final webUrl = Uri.parse(
          'https://tr.tradingview.com/chart/RbphTzbt/?symbol=BINANCE:$symbol',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalNonBrowserApplication);
      } catch (innerError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TradingView açılamadı')),
          );
        }
      }
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Running':
        return 'POZİSYONDA';
      case 'WaitingForEntry':
        return 'BEKLİYOR';
      case 'Stopped':
        return 'DURDU';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Running':
        return const Color(0xFF10B981);
      case 'WaitingForEntry':
        return const Color(0xFFF59E0B);
      case 'Stopped':
        return const Color(0xFFF43F5E);
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }
}
