import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/features/bots/providers/bot_provider.dart';
import 'package:mobile/features/bots/models/bot_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/providers/market_data_provider.dart';

class BotDetailScreen extends ConsumerStatefulWidget {
  final String botId;

  const BotDetailScreen({super.key, required this.botId});

  @override
  ConsumerState<BotDetailScreen> createState() => _BotDetailScreenState();
}

class _BotDetailScreenState extends ConsumerState<BotDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentLogPage = 1;
  static const int _logPageSize = 10;
  int _expandedIndex = 0; // 0: Settings, 1: Chart, 2: Logs

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botAsync = ref.watch(botDetailProvider(widget.botId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Bot Detayı',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: botAsync.when(
                    data: (bot) => _buildContent(context, ref, bot),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Bot bot) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Always visible)
          _buildHeaderCard(context, ref, bot),
          const SizedBox(height: 16),

          // 1. Bot Settings Accordion
          _buildAccordionItem(
            index: 0,
            title: 'Bot Ayarları',
            icon: Icons.settings_suggest_rounded,
            content: Column(
              children: [
                _buildConfigRow(
                  'Strateji',
                  _formatStrategyName(bot.strategyName),
                  Icons.psychology_rounded,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildConfigRow(
                  'Zaman Aralığı',
                  _formatInterval(bot.interval),
                  Icons.schedule_rounded,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildConfigRow(
                  'Giriş Tarihi',
                  bot.entryDate != null ? _formatDateTime(bot.entryDate!) : '-',
                  Icons.login_rounded,
                  valueColor: bot.entryDate != null
                      ? Colors.white
                      : Colors.white38,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildConfigRow(
                  'Çıkış Tarihi',
                  bot.exitDate != null ? _formatDateTime(bot.exitDate!) : '-',
                  Icons.logout_rounded,
                  valueColor: bot.exitDate != null
                      ? Colors.white
                      : Colors.white38,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildConfigRow(
                  'Stop Loss',
                  bot.stopLoss != null
                      ? '%${bot.stopLoss!.toStringAsFixed(1)}'
                      : 'Kapalı',
                  Icons.arrow_downward_rounded,
                  valueColor: bot.stopLoss != null
                      ? const Color(0xFFEF4444)
                      : Colors.white38,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildConfigRow(
                  'Take Profit',
                  bot.takeProfit != null
                      ? '%${bot.takeProfit!.toStringAsFixed(1)}'
                      : 'Kapalı',
                  Icons.arrow_upward_rounded,
                  valueColor: bot.takeProfit != null
                      ? const Color(0xFF10B981)
                      : Colors.white38,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildConfigRow(
                  'Trailing Stop',
                  bot.isTrailingStop ? 'Aktif' : 'Pasif',
                  Icons.trending_up_rounded,
                  valueColor: bot.isTrailingStop
                      ? const Color(0xFF3B82F6)
                      : Colors.white38,
                ),
                if (bot.isTrailingStop && bot.trailingStopDistance != null) ...[
                  const Divider(color: Colors.white10, height: 24),
                  _buildConfigRow(
                    'Takip Mesafesi',
                    '%${bot.trailingStopDistance!.toStringAsFixed(1)}',
                    Icons.straighten_rounded,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Bot Logs Accordion
          _buildAccordionItem(
            index: 1,
            title: 'İşlem Kayıtları',
            icon: Icons.terminal_rounded,
            content: Builder(
              builder: (context) {
                final logsAsync = ref.watch(
                  botLogsProvider((
                    botId: widget.botId,
                    page: _currentLogPage,
                    pageSize: _logPageSize,
                  )),
                );

                return logsAsync.when(
                  data: (result) {
                    if (result.items.isEmpty) {
                      return Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: const Text(
                          "Henüz log kaydı yok",
                          style: TextStyle(color: Colors.white38),
                        ),
                      );
                    }
                    final totalPages = (result.totalCount / _logPageSize)
                        .ceil();
                    return Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: result.items.length,
                          itemBuilder: (context, index) {
                            final log = result.items[index];
                            final isInfo =
                                log.logLevel == 'INFO' ||
                                log.logLevel == 'Info';
                            final isError =
                                log.logLevel == 'ERROR' ||
                                log.logLevel == 'Error';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.white05),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        log.logLevel.toUpperCase(),
                                        style: TextStyle(
                                          color: isInfo
                                              ? const Color(0xFF10B981)
                                              : isError
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF3B82F6),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(log.timestamp),
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    log.message,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (totalPages > 1) _buildPagination(totalPages),
                      ],
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
                  error: (err, stack) => Center(
                    child: Text(
                      'Hata: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAccordionItem({
    required int index,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final isExpanded = _expandedIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () =>
                setState(() => _expandedIndex = isExpanded ? -1 : index),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isExpanded ? AppColors.primary : Colors.white54,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isExpanded ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: isExpanded
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: 200.ms,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: isExpanded ? AppColors.primary : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeInOut,
            child: SizedBox(
              width: double.infinity,
              height: isExpanded ? null : 0,
              child: Visibility(
                visible: isExpanded,
                maintainState: false, // Lazy loading için false yapıldı
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, WidgetRef ref, Bot bot) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: bot.pnl >= 0
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : const Color(0xFFEF4444).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bot.symbol,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getCurrentPrice(ref, bot),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'USD',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(bot.status),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tutar',
                  '\$${bot.amount.toStringAsFixed(1)}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Giriş',
                  bot.entryPrice > 0
                      ? '\$${bot.entryPrice.toStringAsFixed(2)}'
                      : '-',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'PNL',
                  '${bot.pnl >= 0 ? '+' : ''}\$${bot.pnl.toStringAsFixed(2)}',
                  color: bot.pnl >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          if (bot.status == 'Running' || bot.status == 'WaitingForEntry') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _analyzeStrategy(context, bot),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF8B5CF6,
                      ).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_fix_high_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Analiz',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _stopBot(ref, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stop_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Durdur',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getCurrentPrice(WidgetRef ref, Bot bot) {
    final livePrices = ref.watch(liveMarketDataProvider);
    return livePrices.when(
      data: (prices) {
        final sanitizedSymbol = bot.symbol.replaceAll('/', '');
        try {
          final pair = prices.firstWhere(
            (p) => p.symbol.replaceAll('/', '') == sanitizedSymbol,
          );
          return '\$${pair.price.toStringAsFixed(2)}';
        } catch (_) {
          return '-';
        }
      },
      loading: () => '...',
      error: (_, _) => '-',
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: GoogleFonts.plusJakartaSans(
            color: color ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'Running':
        color = const Color(0xFF10B981);
        text = 'Çalışıyor';
        break;
      case 'WaitingForEntry':
        color = const Color(0xFF3B82F6);
        text = 'Bekliyor';
        break;
      case 'Stopped':
        color = const Color(0xFF94A3B8);
        text = 'Durdu';
        break;
      default:
        color = const Color(0xFF94A3B8);
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _stopBot(WidgetRef ref, BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Botu Durdur',
      'Botu durdurmak istediğinize emin misiniz? Durdurma işlemi yapıldığında işlemi geri alamazsınız.',
    );

    if (confirmed != true) return;

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bot durduruluyor...')));
      }

      await ref.read(botServiceProvider).stopBot(widget.botId);

      // Refresh bot details
      ref.invalidate(botDetailProvider(widget.botId));
      ref.invalidate(paginatedBotListProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bot durduruldu')));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _analyzeStrategy(BuildContext context, Bot bot) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_fix_high_rounded,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Strateji Doktoru',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisItem(
              'RSI Ayarı',
              'Mevcut RSI periyodu (14) biraz yavaş kalıyor. 9 veya 7 periyodunu denemek daha fazla sinyal yakalamanı sağlayabilir.',
              Icons.speed_rounded,
              const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 16),
            _buildAnalysisItem(
              'Stop Loss',
              'Son 10 işlemin 4 tanesi %1.5 stop loss ile kapanmış. Piyasa volatil, SL oranını %2.5\'e çekmek erken kapanmaları önleyebilir.',
              Icons.shield_outlined,
              const Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            _buildAnalysisItem(
              'Başarı Oranı',
              'Mevcut başarı oranın %65. Bu strateji trend piyasalarında daha iyi çalışıyor.',
              Icons.trending_up_rounded,
              const Color(0xFF10B981),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Öneriler stratejiye uygulandı! (Simülasyon)'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Önerileri Uygula'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            onTap: _currentLogPage > 1
                ? () => setState(() => _currentLogPage--)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  final pageNum = index + 1;
                  if (totalPages > 7) {
                    if (pageNum != 1 &&
                        pageNum != totalPages &&
                        (pageNum < _currentLogPage - 2 ||
                            pageNum > _currentLogPage + 2)) {
                      if (pageNum == _currentLogPage - 3 ||
                          pageNum == _currentLogPage + 3) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '...',
                            style: TextStyle(color: Colors.white24),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  }
                  return _buildPageNumber(pageNum);
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
            onTap: _currentLogPage < totalPages
                ? () => setState(() => _currentLogPage++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? Colors.white10 : AppColors.white05,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white10,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPageNumber(int pageNum) {
    final isSelected = _currentLogPage == pageNum;
    return GestureDetector(
      onTap: () => setState(() => _currentLogPage = pageNum),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            pageNum.toString(),
            style: GoogleFonts.inter(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Evet',
              style: TextStyle(color: Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}:${localDate.second.toString().padLeft(2, '0')}';
  }

  Widget _buildConfigRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white54, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatInterval(String interval) {
    const intervalMap = {
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
    return intervalMap[interval] ?? interval;
  }

  String _formatStrategyName(String strategyId) {
    const strategyMap = {
      'strategy-golden-rose': 'Altın Kesişim Trendi',
      'strategy-sma111': 'SMA 111',
      'strategy-rsi-scalper': 'RSI Skalper',
      'strategy-macd-cross': 'MACD Kesişim',
      'strategy-bollinger': 'Bollinger Bandı',
      'strategy-market-buy': 'Hemen Al',
    };
    return strategyMap[strategyId] ?? strategyId;
  }

  String _formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}.${localDate.month.toString().padLeft(2, '0')}.${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }
}
