import 'package:face_recognition_attendance/config/bindings/initial_binding.dart';
import 'package:face_recognition_attendance/config/localization/app_translations.dart';
import 'package:face_recognition_attendance/config/routes/app_pages.dart';
import 'package:face_recognition_attendance/config/theme/app_theme.dart';
import 'package:face_recognition_attendance/core/services/language_service.dart';
import 'package:face_recognition_attendance/core/services/theme_service.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyApp extends StatelessWidget {
  final String? initialRoute;
  final UserModel? initialUser;

  const MyApp({
    super.key,
    this.initialRoute,
    this.initialUser,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final themeService = Get.find<ThemeService>();

    return GetMaterialApp(
      title: 'Face Attendance App',
      debugShowCheckedModeBanner: false,

      // Theme Configuration (Light & Dark)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,

      // Localization Configuration
      translations: AppTranslations(),
      locale: languageService.locale,
      fallbackLocale: const Locale('en', 'US'),

      initialBinding: InitialBinding(initialUser: initialUser),
      initialRoute: initialRoute ?? AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
