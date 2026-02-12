import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class to hold privacy settings
class PrivacyState {
  final bool isBalanceHidden;
  final bool isAppBlurEnabled;

  PrivacyState({this.isBalanceHidden = false, this.isAppBlurEnabled = true});

  PrivacyState copyWith({bool? isBalanceHidden, bool? isAppBlurEnabled}) {
    return PrivacyState(
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
      isAppBlurEnabled: isAppBlurEnabled ?? this.isAppBlurEnabled,
    );
  }
}

class PrivacyNotifier extends Notifier<PrivacyState> {
  @override
  PrivacyState build() {
    _loadPreferences();
    return PrivacyState();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isHidden = prefs.getBool('isBalanceHidden') ?? false;
    // Güvenlik için varsayılan olarak blur açık olsun
    final isBlur = prefs.getBool('isAppBlurEnabled') ?? true;

    state = state.copyWith(isBalanceHidden: isHidden, isAppBlurEnabled: isBlur);
  }

  Future<void> toggleBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.isBalanceHidden;
    await prefs.setBool('isBalanceHidden', newValue);
    state = state.copyWith(isBalanceHidden: newValue);
  }

  Future<void> toggleAppBlur() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.isAppBlurEnabled;
    await prefs.setBool('isAppBlurEnabled', newValue);
    state = state.copyWith(isAppBlurEnabled: newValue);
  }
}

final privacyProvider = NotifierProvider<PrivacyNotifier, PrivacyState>(
  PrivacyNotifier.new,
);
