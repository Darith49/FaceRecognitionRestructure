import 'package:face_recognition_attendance/app.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/services/language_service.dart';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Liquid Glass Engine (pre-warms fragment shaders)
  await LiquidGlassWidgets.initialize();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Core Services
  Get.put<LanguageService>(LanguageService(), permanent: true);

  // Initialize Local Standalone Database & Auth
  await LocalDatabaseService().init();
  await LocalAuthService().init();

  // Fast session check for instant launch
  final secureStorage = SecureStorageService();
  final rememberMe = await secureStorage.getRememberMe();

  if (!rememberMe) {
    await LocalAuthService().logout();
    await secureStorage.clearSession();
  }

  final hasSavedSession = await secureStorage.hasValidSession();
  final currentUser = LocalAuthService().getCurrentUser();
  final bool isLoggedIn = rememberMe && (currentUser != null || hasSavedSession);

  UserModel? initialUser;
  if (isLoggedIn) {
    final cachedData = await secureStorage.getCachedUserData();
    if (cachedData != null) {
      try {
        initialUser = UserModel.fromJson(cachedData);
      } catch (_) {}
    }
  }

  final initialRoute = isLoggedIn ? AppRoutes.navigation : AppRoutes.login;

  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      respectSystemAccessibility: true,
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassThemeData.simple(
        blur: 14,
        thickness: 25,
        quality: GlassQuality.standard,
      ),
      child: MyApp(
        initialRoute: initialRoute,
        initialUser: initialUser,
      ),
    ),
  );
}
