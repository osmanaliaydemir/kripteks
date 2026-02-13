import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolItem(
        title: 'Kripto Tarayıcı',
        description: 'Fırsatları gerçek zamanlı yakalayın',
        icon: Icons.radar,
        color: const Color(0xFFF59E0B),
        route: '/scanner',
      ),
      _ToolItem(
        title: 'Simülasyon',
        description: 'Stratejilerinizi geçmiş verilerle test edin',
        icon: Icons.history_edu,
        color: const Color(0xFF6366F1),
        route: '/simulation',
      ),
      _ToolItem(
        title: 'Finansal Raporlar',
        description: 'Detaylı performans ve P&L analizi',
        icon: Icons.pie_chart_outline,
        color: Colors.blueAccent,
        route: '/reports',
      ),
      _ToolItem(
        title: 'Akıllı Bildirimler',
        description: 'Fiyat ve özel sinyal alarmları',
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFFEF4444),
        route: '/alerts',
      ),
      _ToolItem(
        title: 'Piyasa Analizi',
        description: 'Teknik analiz, hacim ve trendler',
        icon: Icons.analytics_outlined,
        color: const Color(0xFF10B981),
        route: '/market-analysis',
      ),
      _ToolItem(
        title: 'Piyasa İstihbaratı',
        description: 'Haberler, balina ve arbitraj takibi',
        icon: Icons.psychology_outlined,
        color: Colors.purpleAccent,
        route: '/market-intelligence',
      ),
      _ToolItem(
        title: 'Kripto Akademi',
        description: 'Eğitimler ve analiz rehberleri',
        icon: Icons.school_outlined,
        color: Colors.orangeAccent,
        route: '/academy',
      ),
      _ToolItem(
        title: 'Hesaplayıcılar',
        description: 'Risk, kar ve pozisyon büyüklüğü',
        icon: Icons.calculate_outlined,
        color: const Color(0xFF8B5CF6),
        route: '/calculators',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          'Araçlar',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                          'Finansal özgürlüğünüz için profesyonel araçlar.',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),

            // Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82, // Biraz daha uzun kartlar
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tool = tools[index];
                  return _buildToolCard(context, tool)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                      .scale(begin: const Offset(0.9, 0.9));
                }, childCount: tools.length),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolItem tool) {
    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: tool.color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Glow
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tool.color.withValues(alpha: 0.15),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tool.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tool.icon, color: tool.color, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tool.description,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon (Optional visual cue)
              Positioned(
                bottom: 16,
                right: 16,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.1),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  _ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}
