import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/market_analysis/providers/news_sentiment_provider.dart';
import 'package:mobile/features/market_analysis/providers/market_intelligence_provider.dart';
import 'package:mobile/features/market_analysis/models/news_sentiment.dart';
import 'package:mobile/features/market_analysis/models/market_intelligence_models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketIntelligenceScreen extends ConsumerStatefulWidget {
  const MarketIntelligenceScreen({super.key});

  @override
  ConsumerState<MarketIntelligenceScreen> createState() =>
      _MarketIntelligenceScreenState();
}

class _MarketIntelligenceScreenState
    extends ConsumerState<MarketIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Piyasa İstihbaratı',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Haber & Duygu'),
            Tab(text: 'Balina Takibi'),
            Tab(text: 'Arbitraj'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NewsSentimentTab(),
          _WhaleTrackerTab(),
          _ArbitrageScannerTab(),
        ],
      ),
    );
  }
}

class _NewsSentimentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsFeedProvider('ALL'));
    final sentimentAsync = ref.watch(currentSentimentProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(newsFeedProvider('ALL'));
        ref.invalidate(currentSentimentProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            sentimentAsync.when(
              data: (sentiment) => _buildSentimentSummary(sentiment),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.newspaper_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Önemli Haberler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            newsAsync.when(
              data: (news) => _buildNewsList(context, news),
              loading: () => _buildLoadingNews(),
              error: (e, _) => Center(
                child: Text(
                  'Haberler yüklenemedi: $e',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentSummary(SentimentHistory sentiment) {
    final color = _getSentimentColor(sentiment.score);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Genel Piyasa Duyarlılığı',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sentiment.action,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${(sentiment.score * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sentiment.summary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sentiment.modelCount} AI modeli tarafından analiz edildi.',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(BuildContext context, List<NewsItem> news) {
    if (news.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Haber bulunamadı.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: news.length,
      itemBuilder: (context, index) {
        final item = news[index];
        return _NewsCard(
          item: item,
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildLoadingNews() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Color _getSentimentColor(double score) {
    if (score > 0.3) return AppColors.success;
    if (score < -0.3) return AppColors.error;
    return AppColors.primary;
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.sentimentScore > 0.1
        ? AppColors.success
        : item.sentimentScore < -0.1
        ? AppColors.error
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white05),
      ),
      child: InkWell(
        onTap: () => _launchURL(item.url),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.sentimentScore > 0.1
                          ? 'Boğa'
                          : item.sentimentScore < -0.1
                          ? 'Ayı'
                          : 'Nötr',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(item.publishedAt.toLocal()),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.aiSummary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.aiSummary,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.source_outlined,
                    size: 12,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.source,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _WhaleTrackerTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whaleAsync = ref.watch(whaleTradesProvider(100000));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(whaleTradesProvider(100000)),
      child: whaleAsync.when(
        data: (trades) => _buildWhaleList(context, trades),
        loading: () => _buildWhaleShimmer(),
        error: (e, _) => Center(
          child: Text(
            'Veri alınamadı: $e',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildWhaleShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildWhaleList(BuildContext context, List<WhaleTrade> trades) {
    if (trades.isEmpty) {
      return const Center(
        child: Text(
          'Büyük işlem bulunamadı.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        return _WhaleCard(
          trade: trade,
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}

class _WhaleCard extends StatelessWidget {
  final WhaleTrade trade;
  const _WhaleCard({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isSell = trade.isBuyerMaker;
    final color = isSell ? AppColors.error : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSell ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trade.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isSell ? 'Büyük Satış' : 'Büyük Alım',
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${NumberFormat.compact().format(trade.usdValue)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm:ss').format(trade.timestamp),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWhaleDetail('Fiyat', '\$${trade.price.toStringAsFixed(2)}'),
              _buildWhaleDetail('Miktar', trade.quantity.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhaleDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ArbitrageScannerTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arbitrageAsync = ref.watch(arbitrageOpportunitiesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(arbitrageOpportunitiesProvider),
      child: arbitrageAsync.when(
        data: (opportunities) => _buildArbitrageList(context, opportunities),
        loading: () => _buildArbitrageShimmer(),
        error: (e, _) => Center(
          child: Text(
            'Veri alınamadı: $e',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildArbitrageShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppColors.surface,
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildArbitrageList(
    BuildContext context,
    List<ArbitrageOpportunity> opportunities,
  ) {
    if (opportunities.isEmpty) {
      return const Center(
        child: Text(
          'Fiyat farkı bulunamadı.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: opportunities.length,
      itemBuilder: (context, index) {
        final opp = opportunities[index];
        return _ArbitrageCard(
          opp: opp,
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _ArbitrageCard extends StatelessWidget {
  final ArbitrageOpportunity opp;
  const _ArbitrageCard({required this.opp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                opp.asset,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '%${opp.differencePercent.toStringAsFixed(3)} Fark',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPriceInfo(opp.pair1, opp.price1)),
              const Icon(Icons.compare_arrows_rounded, color: Colors.white24),
              Expanded(
                child: _buildPriceInfo(
                  opp.pair2,
                  opp.price2,
                  cross: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.white05, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Potansiyel Kâr (\$1000 için)',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                '\$${opp.potentialProfitUsd.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(
    String pair,
    double price, {
    CrossAxisAlignment cross = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(pair, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          '\$${price.toStringAsFixed(price < 1 ? 6 : 2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
