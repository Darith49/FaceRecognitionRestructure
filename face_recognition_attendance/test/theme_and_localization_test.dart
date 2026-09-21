import 'package:face_recognition_attendance/config/localization/app_translations.dart';
import 'package:face_recognition_attendance/config/localization/en_us.dart';
import 'package:face_recognition_attendance/config/localization/km_kh.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/config/theme/app_text_styles.dart';
import 'package:face_recognition_attendance/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme System Tests', () {
    test('AppColors brand and semantic colors are defined correctly', () {
      expect(AppColors.primary, const Color(0xFF2563EB));
      expect(AppColors.secondary, const Color(0xFF1F2937));
      expect(AppColors.success, const Color(0xFF059669));
      expect(AppColors.warning, const Color(0xFFD97706));
      expect(AppColors.error, const Color(0xFFDC2626));
      expect(AppColors.info, const Color(0xFF6B7280));
    });

    test('AppTheme light and dark themes have correct brightness and colorScheme', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primary);
      expect(AppTheme.darkTheme.colorScheme.primary, AppColors.primary);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppColors.darkBackground);
    });

    test('AppTextStyles status color helper returns accurate semantic colors', () {
      expect(AppTextStyles.getStatusColor('present'), AppColors.success);
      expect(AppTextStyles.getStatusColor('absent'), AppColors.error);
      expect(AppTextStyles.getStatusColor('early_leave'), AppColors.warning);
      expect(AppTextStyles.getStatusColor('pending'), AppColors.warning);
      expect(AppTextStyles.getStatusColor('unknown'), AppColors.info);
    });
  });

  group('Localization System Tests', () {
    test('AppTranslations provides en_US and km_KH maps', () {
      final translations = AppTranslations();
      expect(translations.keys.containsKey('en_US'), isTrue);
      expect(translations.keys.containsKey('km_KH'), isTrue);
    });

    test('English and Khmer dictionaries have matching keys', () {
      final enKeys = enUS.keys.toSet();
      final kmKeys = kmKH.keys.toSet();

      final missingInKm = enKeys.difference(kmKeys);
      final missingInEn = kmKeys.difference(enKeys);

      expect(missingInKm, isEmpty, reason: 'Keys present in enUS but missing in kmKH');
      expect(missingInEn, isEmpty, reason: 'Keys present in kmKH but missing in enUS');
    });

    test('Core translation keys are non-empty', () {
      for (final entry in enUS.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: 'enUS key ${entry.key} is empty');
      }
      for (final entry in kmKH.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: 'kmKH key ${entry.key} is empty');
      }
    });
  });
}
