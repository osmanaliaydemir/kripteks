import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/app_header.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const AppHeader(title: 'Araçlar', showBackButton: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildToolCard(
              context,
              title: 'Kripto Tarayıcı',
              description:
                  'Piyasadaki fırsatları gerçek zamanlı tarayın ve sinyalleri yakalayın.',
              icon: Icons.radar,
              color: const Color(0xFFF59E0B),
              onTap: () => context.push('/scanner'),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildToolCard(
                  context,
                  title: 'Simulasyon',
                  description:
                      'Stratejilerinizi geçmiş verilerle test edin ve performansını analiz edin.',
                  icon: Icons.history_edu,
                  color: const Color(0xFF6366F1),
                  onTap: () => context.push('/simulation'),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 50.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildToolCard(
                  context,
                  title: 'Finansal Raporlar',
                  description:
                      'Detaylı performans analizi, kazanç/kayıp grafikleri ve strateji karşılaştırmaları.',
                  icon: Icons.description_outlined,
                  color: Colors.blueAccent,
                  onTap: () => context.push('/reports'),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildToolCard(
                  context,
                  title: 'Akıllı Bildirimler',
                  description: 'Fiyat alarmları ve bot bildirimlerini yönetin.',
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFFEF4444),
                  onTap: () => context.push('/alerts'),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildToolCard(
                  context,
                  title: 'Piyasa Analizi',
                  description:
                      'Trend analizleri, hacim takibi ve teknik göstergelerle piyasayı yorumlayın.',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF10B981),
                  onTap: () => context.push('/market-analysis'),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildToolCard(
                  context,
                  title: 'Piyasa İstihbaratı',
                  description:
                      'Haber duyarlılığı, balina hareketleri ve arbitraj fırsatlarını izleyin.',
                  icon: Icons.psychology_outlined,
                  color: Colors.purpleAccent,
                  onTap: () => context.push('/market-intelligence'),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildToolCard(
                  context,
                  title: 'Kripto Akademi',
                  description:
                      'Eğitimler, indikatör rehberleri ve piyasa analiz teknikleri.',
                  icon: Icons.school_outlined,
                  color: Colors.orangeAccent,
                  onTap: () => context.push('/academy'),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 500.ms)
                .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            _buildToolCard(
                  context,
                  title: 'Hesaplayıcılar',
                  description:
                      'P&L, Pozisyon Büyüklüğü ve DCA hesaplamaları ile riskinizi yönetin.',
                  icon: Icons.calculate_outlined,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/calculators'),
                )
                .animate()
                .fadeIn(duration: 400.ms, delay: 600.ms)
                .slideX(begin: -0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
