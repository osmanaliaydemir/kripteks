import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _loadingText = 'Başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _startLoadingSequence();
  }

  Future<void> _startLoadingSequence() async {
    // Simüle edilmiş yükleme adımları
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted)
      setState(() => _loadingText = 'Sunucu Bağlantısı Kuruluyor...');

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted)
      setState(() => _loadingText = 'Veriler Senkronize Ediliyor...');

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _loadingText = 'Hazır!');

    await Future.delayed(const Duration(milliseconds: 400));
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    final token = await ref.read(authServiceProvider).getToken();

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow (Tutarlı Tasarım)
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
          ).animate().fadeIn(duration: 1000.ms),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E293B),
                            const Color(0xFF0F172A).withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: -5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.candlestick_chart_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .shimmer(
                      delay: 1000.ms,
                      duration: 1500.ms,
                      color: Colors.white.withValues(alpha: 0.2),
                    )
                    .then()
                    .boxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 60,
                      spreadRadius: 10,
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 40),

                // App Title
                Text(
                  'KRIPTEKS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Yapay Zeka Destekli Algoritmik Ticaret',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 60),

                // Loading Indicator & Text
                SizedBox(
                  height: 60,
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _loadingText,
                          key: ValueKey(_loadingText),
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),

          // Versiyon Bilgisi
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.0 (Beta)',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
            ),
          ).animate().fadeIn(delay: 1000.ms),
        ],
      ),
    );
  }
}
