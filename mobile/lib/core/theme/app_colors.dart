import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Color
  static const Color primary = Color(0xFFF59E0B); // Amber-500
  static const Color primaryDark = Color(0xFFD97706); // Amber-700
  static const Color primaryTransparent = Color(0x40F59E0B);

  // Backgrounds
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF0F172A);
  static const Color surfaceLight = Color(
    0xFF1E293B,
  ); // Often used for cards/inputs as seen in logs

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary =
      Colors.white38; // Used for unselected items
  static const Color textDisabled = Colors.white24; // Used for hints

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color investment = Color(0xFFF43F5E); // Rose
  static const Color binance = Color(0xFFF3BA2F); // Binance Yellow
  static const Color purple = Color(0xFF8B5CF6); // Purple

  // Dark Variants (for gradients)
  static const Color successDark = Color(0xFF064E3B);
  static const Color errorDark = Color(0xFF7F1D1D);
  static const Color investmentDark = Color(0xFF9F1239); // Rose-800

  // Utilities
  static const Color white05 = Color(0x0DFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white38 = Color(
    0x61FFFFFF,
  ); // Similar to textSecondary/icon disabled

  // Gradients
  static const Color border = white20;
  static const Color transparent = Colors.transparent;
}
