import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Configures light and dark Material 3 themes for Transport Invoice Pro.
class AppTheme {
  AppTheme._();

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondaryTeal,
      onSecondary: Colors.white,
      tertiary: AppColors.accentAmber,
      onTertiary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLight,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: AppTextStyles.lightTextTheme,
      fontFamily: AppTextStyles.fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: UIConstants.elevationNone,
        scrolledUnderElevation: 1.0,
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: UIConstants.elevationLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          side: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacing16,
          vertical: UIConstants.spacing14,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabledLight),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
        border: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: UIConstants.elevationNone,
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing24,
            vertical: UIConstants.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: UIConstants.borderRadiusMedium,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing24,
            vertical: UIConstants.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: UIConstants.borderRadiusMedium,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.backgroundDark,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.secondaryTeal,
      onSecondary: Colors.white,
      tertiary: AppColors.accentGold,
      onTertiary: Colors.black,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: AppTextStyles.darkTextTheme,
      fontFamily: AppTextStyles.fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: UIConstants.elevationNone,
        scrolledUnderElevation: 1.0,
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: AppColors.primaryLight,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: UIConstants.elevationLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          side: const BorderSide(color: AppColors.borderDark, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacing16,
          vertical: UIConstants.spacing14,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabledDark),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: UIConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: UIConstants.elevationNone,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.backgroundDark,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing24,
            vertical: UIConstants.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: UIConstants.borderRadiusMedium,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.spacing24,
            vertical: UIConstants.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: UIConstants.borderRadiusMedium,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
