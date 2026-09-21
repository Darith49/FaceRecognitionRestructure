import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ============== LIGHT THEME TEXT THEME ==============
  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.lightText,
      height: 1.2,
    ),
    displayMedium: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.lightText,
      height: 1.2,
    ),
    headlineLarge: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.lightText,
      height: 1.3,
    ),
    headlineMedium: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
      height: 1.3,
    ),
    titleLarge: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
      height: 1.4,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
      height: 1.4,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
      height: 1.4,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.lightText,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.lightText,
      height: 1.5,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.lightTextSecondary,
      height: 1.5,
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.lightText,
      height: 1.4,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.lightTextSecondary,
      height: 1.4,
    ),
    labelSmall: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.lightTextSecondary,
      height: 1.4,
    ),
  );

  // ============== DARK THEME TEXT THEME ==============
  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.darkText,
      height: 1.2,
    ),
    displayMedium: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.darkText,
      height: 1.2,
    ),
    headlineLarge: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.darkText,
      height: 1.3,
    ),
    headlineMedium: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
      height: 1.3,
    ),
    titleLarge: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
      height: 1.4,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
      height: 1.4,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
      height: 1.4,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.darkText,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.darkText,
      height: 1.5,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.darkTextSecondary,
      height: 1.5,
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.darkText,
      height: 1.4,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextSecondary,
      height: 1.4,
    ),
    labelSmall: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextSecondary,
      height: 1.4,
    ),
  );

  // ============== CUSTOM BUTTON STYLES ==============
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ============== HELPER METHODS ==============
  /// Get status badge text style
  static const TextStyle statusBadgeText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Get attendance status color based on status type
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'early_leave':
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}
