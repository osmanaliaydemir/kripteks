import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/theme/app_colors.dart';

class NetworkStatusBanner extends ConsumerStatefulWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  ConsumerState<NetworkStatusBanner> createState() =>
      _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends ConsumerState<NetworkStatusBanner> {
  bool _wasOffline = false;
  bool _showOnlineBanner = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(connectionStatusProvider);

    // Listen for status changes to trigger animations/timers
    ref.listen(connectionStatusProvider, (previous, next) {
      next.whenData((status) {
        if (status == ConnectionStatus.offline) {
          setState(() {
            _wasOffline = true;
            _showOnlineBanner = false;
          });
          _timer?.cancel();
        } else if (status == ConnectionStatus.online && _wasOffline) {
          setState(() {
            _showOnlineBanner = true;
            _wasOffline = false;
          });
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showOnlineBanner = false;
              });
            }
          });
        }
      });
    });

    return Stack(
      children: [
        widget.child,
        statusAsync.when(
          data: (status) {
            if (status == ConnectionStatus.offline) {
              return _buildBanner(
                context,
                color: AppColors.error,
                icon: Icons.wifi_off,
                message: 'İnternet bağlantısı yok',
              );
            } else if (_showOnlineBanner) {
              return _buildBanner(
                context,
                color: AppColors.success,
                icon: Icons.wifi,
                message: 'Bağlantı tekrar sağlandı',
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String message,
  }) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: color,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
