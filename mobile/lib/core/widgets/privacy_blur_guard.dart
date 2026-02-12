import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/privacy_provider.dart';

class PrivacyBlurGuard extends ConsumerStatefulWidget {
  final Widget child;
  final bool enabled;

  const PrivacyBlurGuard({super.key, required this.child, this.enabled = true});

  @override
  ConsumerState<PrivacyBlurGuard> createState() => _PrivacyBlurGuardState();
}

class _PrivacyBlurGuardState extends ConsumerState<PrivacyBlurGuard>
    with WidgetsBindingObserver {
  bool _shouldBlur = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;

    // Blur özelliğinin provider'dan açık olup olmadığını kontrol et
    final isBlurEnabled = ref.read(privacyProvider).isAppBlurEnabled;
    if (!isBlurEnabled) return;

    setState(() {
      _shouldBlur =
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden;
      // hidden durumu Android 14+ bazı durumlarda ve iOS'ta görev değişimi sırasında önemli olabilir
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_shouldBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
