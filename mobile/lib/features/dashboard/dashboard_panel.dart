import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/sensitive_text.dart';
import 'models/dashboard_stats.dart';
import 'providers/dashboard_provider.dart';
import 'providers/dashboard_layout_provider.dart';
import '../wallet/providers/wallet_provider.dart';
import '../wallet/wallet_screen.dart';
import '../bots/bot_list_screen.dart';
import '../bots/providers/bot_provider.dart';
import '../bots/models/bot_model.dart';
import '../reports/reports_screen.dart';
import '../market_analysis/market_analysis_screen.dart';

class DashboardPanel extends ConsumerWidget {
  const DashboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final layoutState = ref.watch(dashboardLayoutProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // ignore: unused_result
        ref.refresh(dashboardStatsProvider);
      },
      child: statsAsync.when(
        data: (stats) => _buildLayout(context, ref, stats, layoutState),
        error: (err, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Text(
                'Hata: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    DashboardLayoutState layoutState,
  ) {
    if (layoutState.isEditing) {
      // --- EDIT MODE ---
      // Edit modunda tüm widgetları ALT ALTA listeliyoruz (tek sütun).
      // Bu sayede sürükleyip bırakmak çok daha kolay ve tutarlı oluyor.
      // ReorderableListView doğal olarak bunu destekler.

      final items = <Widget>[];

      for (final id in layoutState.order) {
        // Edit modunda gizli olsa bile gösteriyoruz (opacity ile)
        items.add(_buildEditItem(context, ref, stats, id, layoutState));
      }

      return ReorderableListView(
        padding: const EdgeInsets.all(16),
        onReorder: (oldIndex, newIndex) {
          ref
              .read(dashboardLayoutProvider.notifier)
              .reorder(oldIndex, newIndex);
        },
        physics: const AlwaysScrollableScrollPhysics(),
        children: items,
      );
    } else {
      // --- VIEW MODE ---
      // Normal modda "Masonry" benzeri basit bir grid mantığı kuruyoruz.
      // Widgetları sırasıyla alıyoruz:
      // - Eğer widget LARGE ise -> Tek satırda tam genişlikte çiziyoruz.
      // - Eğer widget SMALL ise -> Bir sonrakine bakıyoruz.
      //   - Sonraki de SMALL'sa -> Yan yana çiziyoruz (Row).
      //   - Sonraki LARGE veya yoksa -> Tek başına çiziyoruz (ama yine de dengeli dursun diye).

      final viewItems = <Widget>[];
      final visibleIds = layoutState.order
          .where((id) => !layoutState.hiddenIds.contains(id))
          .toList();

      for (int i = 0; i < visibleIds.length; i++) {
        final id = visibleIds[i];
        final isLarge = DashboardWidgets.isLarge(id);

        if (isLarge) {
          // Large widget: Tam genişlik
          viewItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWidgetById(context, ref, stats, id),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          );
        } else {
          // Small widget
          // Bir sonraki eleman var mı ve o da small mu?
          if (i + 1 < visibleIds.length) {
            final nextId = visibleIds[i + 1];
            if (!DashboardWidgets.isLarge(nextId)) {
              // İkisini yan yana koy
              viewItems.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildWidgetById(context, ref, stats, id),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildWidgetById(context, ref, stats, nextId),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              );
              i++; // Sonraki elemanı da işledik, atla
              continue;
            }
          }

          // Yanına koyacak small bulamadık, tek başına koy (Expanded içinde değil, Row içinde Expanded olarak duralım ki structure bozulmasın, veya direkt tam genişlik mi?)
          // Genelde tek kalan small widget tam genişlikte (Large gibi) görünse daha şık olur.
          viewItems.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWidgetById(context, ref, stats, id),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          );
        }
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: viewItems,
      );
    }
  }

  Widget _buildEditItem(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    String id,
    DashboardLayoutState layoutState,
  ) {
    final isHidden = layoutState.hiddenIds.contains(id);
    final widget = _buildWidgetById(context, ref, stats, id);

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Sol Taraf: Widget Önizlemesi (Küçültülmüş ve Orantılı)
          Expanded(
            child: Opacity(
              opacity: isHidden ? 0.4 : 1.0,
              child: IgnorePointer(
                ignoring: true, // İçeriğe tıklanamasın
                child: SizedBox(
                  height: 60, // Sabit yükseklik ile hizala
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      // Orijinal genişliğe yakın bir değer veriyoruz ki
                      // FittedBox onu sığdırmak için orantılı küçültsün.
                      width: MediaQuery.of(context).size.width - 40,
                      child: widget,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dikey Ayırıcı Çizgi
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Sağ Taraf: Kontrol Butonları

          // Göz İkonu
          IconButton(
            icon: Icon(
              isHidden ? Icons.visibility_off : Icons.visibility,
              color: isHidden ? AppColors.textSecondary : AppColors.primary,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ref.read(dashboardLayoutProvider.notifier).toggleVisibility(id);
            },
          ),

          const SizedBox(width: 16),

          // Sürükleme Tutamacı
          ReorderableDragStartListener(
            index: layoutState.order.indexOf(id),
            child: const Icon(
              Icons.drag_handle,
              color: Colors.white70,
              size: 26,
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildWidgetById(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    String id,
  ) {
    switch (id) {
      case DashboardWidgets.quickActions:
        return _buildQuickActions(context);
      case DashboardWidgets.winRate:
        return _buildWinRateCard(context, ref, stats);
      case DashboardWidgets.totalPnl:
        return _buildTotalPnlCard(context, ref, stats);
      case DashboardWidgets.avgTradePnl:
        return _buildStatCard(
          title: 'Ort. İşlem Kârı',
          value: '\$${stats.avgTradePnL.toStringAsFixed(2)}',
          icon: Icons.show_chart,
          color: stats.avgTradePnL >= 0
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          isSensitive: true,
        );
      case DashboardWidgets.botBalance:
        return Consumer(
          builder: (context, ref, child) {
            final walletAsync = ref.watch(walletDetailsProvider);
            final walletDetails = walletAsync.asData?.value;
            final lockedBalance = walletDetails?.lockedBalance ?? 0.0;
            return _buildStatCard(
              title: 'Mevcut Bot Bakiyesi',
              value: '\$${lockedBalance.toStringAsFixed(2)}',
              icon: Icons.savings,
              color: const Color(0xFFF59E0B),
              isSensitive: true,
            );
          },
        );
      case DashboardWidgets.activeBots:
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BotListScreen()),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final botListAsync = ref.watch(paginatedBotListProvider);
              final activeBotCount =
                  botListAsync.asData?.value.items
                      .where(
                        (b) =>
                            b.status == 'Running' ||
                            b.status == 'WaitingForEntry',
                      )
                      .length ??
                  0;

              return _buildStatCard(
                title: 'Aktif İşlemler',
                value: '$activeBotCount adet bot aktif işlemde',
                icon: Icons.smart_toy,
                color: Colors.white,
              );
            },
          ),
        );
      case DashboardWidgets.bestPair:
        return Consumer(
          builder: (context, ref, child) {
            final walletAsync = ref.watch(walletDetailsProvider);
            final freeBalance =
                walletAsync.asData?.value.availableBalance ?? 0.0;

            return _buildStatCard(
              title: 'Kullanılabilir Bakiye',
              value: '\$${freeBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF8B5CF6), // Violet - Modern ve şık
              isSensitive: true,
            );
          },
        );
      case DashboardWidgets.dailyProfit:
        return _buildStatCard(
          title: 'Bugünkü Kazanç',
          value: '+\$0.00', // Placeholder
          icon: Icons.calendar_today,
          color: const Color(0xFF10B981),
          isSensitive: true,
        );
      case DashboardWidgets.totalInvest:
        return Consumer(
          builder: (context, ref, child) {
            final botListAsync = ref.watch(paginatedBotListProvider);
            final totalInvested =
                botListAsync.asData?.value.items
                    .map((b) => b.amount)
                    .fold(0.0, (sum, amount) => sum + amount) ??
                0.0;

            return _buildStatCard(
              title: 'Toplam Yatırım',
              value: '\$${totalInvested.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF3B82F6),
              isSensitive: true,
            );
          },
        );
      case DashboardWidgets.bestBot:
        return _buildBestBotCard(context, ref, stats);
      default:
        // Eğer tanınmayan bir ID varsa (versiyon uyumsuzluğu vs) boş dön
        return const SizedBox.shrink();
    }
  }

  // --- New Feature Widgets ---

  Widget _buildQuickActions(BuildContext context) {
    // Statik eylemler listesi
    final actions = [
      {
        'label': 'Yeni Bot',
        'icon': Icons.smart_toy,
        'color': AppColors.primary,
      },
      {
        'label': 'Cüzdan',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'label': 'Geçmiş',
        'icon': Icons.history,
        'color': const Color(0xFFF59E0B),
      },
      {
        'label': 'Analiz',
        'icon': Icons.analytics,
        'color': const Color(0xFF10B981),
      },
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: () {
              if (action['label'] == 'Yeni Bot') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BotListScreen()),
                );
              } else if (action['label'] == 'Cüzdan') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              } else if (action['label'] == 'Geçmiş') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              } else if (action['label'] == 'Analiz') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MarketAnalysisScreen(),
                  ),
                );
              }
            },
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWinRateCard(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
  ) {
    // Mock data yerine gerçek stats kullanıyoruz ama stats genellikle 0 gelebilir
    // Biraz görsellik katmak için
    final winRate = stats.winRate; // 0.0 - 100.0 arası
    final totalTrades = stats.totalTrades;
    final wins = stats.winningTrades;
    final losses = stats.losingTrades;

    // Renk belirleme
    Color rateColor = const Color(0xFF10B981); // Yeşil
    if (winRate < 40) {
      rateColor = const Color(0xFFEF4444); // Kırmızı
    } else if (winRate < 60) {
      rateColor = const Color(0xFFF59E0B); // Sarı
    }

    return Container(
      padding: const EdgeInsets.all(20),
      // Diğer kartlarla aynı dekorasyon
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol: Dairesel Grafik
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: winRate / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: rateColor,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${winRate.toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Sağ: Detaylar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAŞARI ORANI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniBadge('T: $totalTrades', Colors.blueGrey),
                    const SizedBox(width: 6),
                    _buildMiniBadge('W: $wins', const Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    _buildMiniBadge('L: $losses', const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // --- Widget Builders (Complex Ones) ---

  Widget _buildTotalPnlCard(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final walletAsync = ref.watch(walletDetailsProvider);
        final walletDetails = walletAsync.asData?.value;

        final unrealizedPnl = walletDetails?.totalPnl ?? 0.0;
        final netPnl = stats.totalPnl + unrealizedPnl;
        final isNetPnlPositive = netPnl >= 0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          ),
          child: _buildStatCard(
            title: 'Toplam Kâr/Zarar',
            value: '\$${netPnl.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: isNetPnlPositive
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            isLarge: true,
            isSensitive: true,
          ),
        );
      },
    );
  }

  Widget _buildBestBotCard(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final botListAsync = ref.watch(paginatedBotListProvider);
        final bots = botListAsync.asData?.value.items ?? [];

        Bot? bestBot;
        if (bots.isNotEmpty) {
          bestBot = bots.reduce(
            (curr, next) => curr.pnl > next.pnl ? curr : next,
          );
        }

        final bestVal = (bestBot != null && bestBot.pnl > 0)
            ? '+\$${bestBot.pnl.toStringAsFixed(2)} (${bestBot.symbol})'
            : '-';

        return _buildStatCard(
          title: 'En Çok Kazandıran Bot',
          value: bestVal,
          icon: Icons.emoji_events,
          color: const Color(0xFFF59E0B),
          isSensitive: true,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLarge = false,
    bool isSensitive = false,
  }) {
    final isPnlCard = title == 'Toplam Kâr/Zarar';

    // Modern Dark & Gradient Tasarım
    // PnL kartı için özel vurgulu gradient, diğerleri için soft yüzey
    final gradient = isPnlCard
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: value.contains('-')
                ? [
                    const Color(0xFF450A0A), // Koyu Kırmızı
                    const Color(0xFF1F1F1F), // Neredeyse Siyah
                  ]
                : [
                    const Color(0xFF064E3B), // Koyu Yeşil
                    const Color(0xFF1F1F1F), // Neredeyse Siyah
                  ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceLight.withValues(alpha: 0.9),
              AppColors.surfaceLight.withValues(alpha: 0.4),
            ],
          );

    return Container(
      constraints: BoxConstraints(minHeight: isLarge ? 140 : 110),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28), // Daha yuvarlak köşeler
        border: Border.all(
          // İnce, zarif bir kenarlık (Stroke)
          color: isPnlCard
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          // Hafif bir glow veya derinlik efekti
          BoxShadow(
            color: isPnlCard
                ? color.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Arka Plan Dekoru (Watermark İkon) - İsteğe bağlı, kartın sağ altına çok silik ikon
          Positioned(
            right: -10,
            bottom: -10,
            child: Transform.rotate(
              angle: -0.2, // Hafif eğik
              child: Icon(
                icon,
                size: 80,
                color: color.withValues(alpha: 0.03), // Çok çok silik
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Üst Kısım: İkon ve Başlık
              Row(
                children: [
                  // İkon Kutusu (Glass Effect)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),

                  // Başlık
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Değer
              isSensitive
                  ? SensitiveText(
                      value,
                      style: GoogleFonts.outfit(
                        // Rakamlar için daha modern font
                        fontSize: isLarge ? 38 : (value.length > 10 ? 20 : 26),
                        fontWeight: FontWeight.w700,
                        color: isPnlCard ? Colors.white : AppColors.textPrimary,
                        height: 1.0,
                      ),
                    )
                  : Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: isLarge ? 38 : (value.length > 10 ? 20 : 26),
                        fontWeight: FontWeight.w700,
                        color: isPnlCard ? Colors.white : AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),

              // PnL Kartı için Alt Bilgi
              if (isPnlCard) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        value.contains('-')
                            ? Icons.trending_down
                            : Icons.trending_up,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Toplam Bakiye',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
