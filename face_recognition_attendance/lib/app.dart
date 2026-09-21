import 'package:face_recognition_attendance/config/bindings/initial_binding.dart';
import 'package:face_recognition_attendance/config/localization/app_translations.dart';
import 'package:face_recognition_attendance/config/routes/app_pages.dart';
import 'package:face_recognition_attendance/config/theme/app_theme.dart';
import 'package:face_recognition_attendance/core/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();

    return GetMaterialApp(
      title: 'Face Attendance App',
      debugShowCheckedModeBanner: false,

      // Theme Configuration (Light Theme)
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // Localization Configuration
      translations: AppTranslations(),
      locale: languageService.locale,
      fallbackLocale: const Locale('en', 'US'),

      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
