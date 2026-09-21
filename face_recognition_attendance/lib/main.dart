import 'package:face_recognition_attendance/app.dart';
import 'package:face_recognition_attendance/core/services/language_service.dart';
import 'package:face_recognition_attendance/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Core Services
  Get.put<LanguageService>(LanguageService(), permanent: true);

  // Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}
