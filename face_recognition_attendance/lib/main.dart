import 'package:face_recognition_attendance/app.dart';
import 'package:face_recognition_attendance/core/services/language_service.dart';
import 'package:face_recognition_attendance/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      child: const MyApp(),
    ),
  );
}
