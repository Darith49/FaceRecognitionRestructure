import 'package:face_recognition_attendance/app.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/services/language_service.dart';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/core/services/sqlite_sync_service.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Liquid Glass Engine (pre-warms fragment shaders)
  await LiquidGlassWidgets.initialize();

  // Initialize GetStorage with all required containers
  await GetStorage.init();
  await GetStorage.init('face_attendance_local_db');
  await GetStorage.init('face_attendance_auth');

  // Initialize Core Services
  Get.put<LanguageService>(LanguageService(), permanent: true);

  // Initialize Local Standalone Database & Auth
  await LocalDatabaseService().init();
  await LocalAuthService().init();

  // Connect to persistent SQLite backend if available and pull disk state
  await SqliteSyncService().init();

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
        // Refresh with latest persistent vault data from SQLite
        final vault = LocalDatabaseService().getUserAccountData(initialUser.email);
        if (vault != null) {
          initialUser = initialUser.copyWith(
            profileUrl: vault['profile_picture'] ?? initialUser.profileUrl,
            hasFaceRegistered: vault['has_face_registered'] == true || initialUser.hasFaceRegistered,
            faceTemplates: vault['face_templates'] != null
                ? (vault['face_templates'] is List
                    ? (vault['face_templates'] as List).map((e) => (e as num).toDouble()).toList()
                    : null)
                : initialUser.faceTemplates,
            faceJpg: vault['face_jpg'] ?? initialUser.faceJpg,
          );
        }
        LocalAuthService().setCurrentUserFromModel(initialUser);
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
