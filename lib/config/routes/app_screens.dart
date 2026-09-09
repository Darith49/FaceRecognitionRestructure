import 'package:face_recognition_attendance/config/navigation/navigation_binding.dart';
import 'package:face_recognition_attendance/config/navigation/navigation_screen.dart';
import 'package:get/get.dart';

class AppScreens {
  static final routes = [
    GetPage(
      name: '/',
      page: () => NavigationScreen(),
      binding: NavigationBinding(),
    ),
  ];
}
