import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/error/error_handler.dart';
import 'package:mobile/core/providers/paginated_provider.dart';
import 'package:mobile/features/bots/providers/bot_provider.dart';
import 'package:mobile/features/bots/models/bot_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BotDetailScreen extends ConsumerStatefulWidget {
  final String botId;

  const BotDetailScreen({super.key, required this.botId});

  @override
  ConsumerState<BotDetailScreen> createState() => _BotDetailScreenState();
}

class _BotDetailScreenState extends ConsumerState<BotDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  // Bot logları state (widget-level pagination yönetimi)
  PaginatedState<BotLog>? _logsState;
  bool _isLogsLoading = true;
  Object? _logsError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialLogs();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLogs() async {
    try {
      final botService = ref.read(botServiceProvider);
      final result = await botService.getBotLogs(
        widget.botId,
        page: 1,
        pageSize: 50,
      );
      if (mounted) {
        setState(() {
          _logsState = PaginatedState<BotLog>(
            items: result.items,
            currentPage: 1,
            pageSize: 50,
            totalCount: result.totalCount,
            hasMore: result.hasMore,
          );
          _isLogsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logsError = e;
          _isLogsLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    final current = _logsState;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    setState(() {
      _logsState = current.copyWith(isLoadingMore: true);
    });

    try {
      final botService = ref.read(botServiceProvider);
      final nextPage = current.currentPage + 1;
      final result = await botService.getBotLogs(
        widget.botId,
        page: nextPage,
        pageSize: 50,
      );

      if (mounted) {
        setState(() {
          _logsState = current.copyWith(
            items: [...current.items, ...result.items],
            currentPage: nextPage,
            totalCount: result.totalCount,
            hasMore: result.hasMore,
            isLoadingMore: false,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _logsState = current.copyWith(isLoadingMore: false, error: e);
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _loadMoreLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final botAsync = ref.watch(botDetailProvider(widget.botId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'İşlem Detayları',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
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
          SafeArea(
            child: botAsync.when(
              data: (bot) => _buildContent(context, ref, bot),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bot.symbol,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    _buildStatusChip(bot.status),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Tutar', '\$${bot.amount}'),
                    _buildStatItem(
                      'Giriş',
                      bot.entryPrice > 0 ? '\$${bot.entryPrice}' : '-',
                    ),
                    _buildStatItem(
                      'PNL',
                      '\$${bot.pnl.toStringAsFixed(2)}',
                      color: bot.pnl >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ],
                ),
                // Stop Button inside Header Card
                if (bot.status == 'Running' ||
                    bot.status == 'WaitingForEntry') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _stopBot(ref, context),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Durdur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Bot Configuration Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bot Ayarları',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          Text(
            'İşlem Kayıtları', // Changed from 'Geçmiş İşlemler'
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          Builder(
            builder: (context) {
              if (_isLogsLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  ),
                );
              }

              if (_logsError != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Log yüklenemedi: $_logsError',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }

              final logsState = _logsState;
              if (logsState == null || logsState.items.isEmpty) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 48,
                        color: Colors.white10,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Henüz log kaydı yok",
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms);
              }

              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logsState.items.length,
                    itemBuilder: (context, index) {
                      final log = logsState.items[index];
                      final isInfo =
                          log.logLevel == 'INFO' || log.logLevel == 'Info';
                      final isError =
                          log.logLevel == 'ERROR' || log.logLevel == 'Error';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isInfo
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.2)
                                        : isError
                                        ? const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.2)
                                        : const Color(
                                            0xFF3B82F6,
                                          ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.logLevel,
                                    style: TextStyle(
                                      color: isInfo
                                          ? const Color(0xFF10B981)
                                          : isError
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF3B82F6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(log.timestamp),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                      ).animate().fadeIn(delay: (50 * index).ms).slideX();
                    },
                  ),
                  if (logsState.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ),
                  if (!logsState.hasMore && logsState.items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Tüm loglar yüklendi',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: color ?? Colors.white,
            fontSize: 20,
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
