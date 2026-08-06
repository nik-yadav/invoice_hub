import 'package:flutter/material.dart';

/// Centralized color palette for Transport Invoice Pro.
/// Supports both Light and Dark Material 3 color schemes.
class AppColors {
  AppColors._();

  // Brand Primary Palette
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryDark = Color(0xFF1E293B); // Slate Dark

  // Brand Accent (Transport / Freight Highlight)
  static const Color accentAmber = Color(0xFFD97706); // Warm Amber
  static const Color accentGold = Color(0xFFF59E0B); // Bright Gold

  // Secondary Palette
  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color secondaryCyan = Color(0xFF06B6D4);

  // Neutral Palette - Light Mode
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textDisabledLight = Color(0xFF94A3B8);

  // Neutral Palette - Dark Mode
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF151C2C);
  static const Color surfaceVariantDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF64748B);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  //Others
  static const Color emerald = Color(0xFF50C878);
}
