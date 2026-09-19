import 'package:face_recognition_attendance/config/navigation/navigation_binding.dart';
import 'package:face_recognition_attendance/config/navigation/navigation_screen.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/features/auth/binding/login_binding.dart';
import 'package:face_recognition_attendance/features/auth/view/login_screen.dart';
import 'package:get/get.dart';

class AppPages {

  static final INITIAL = AppRoutes.login;

  static final routes = [
    GetPage(
      name: AppRoutes.navigation,
      page: () => NavigationScreen(),
      binding: NavigationBinding(),
    ),

    GetPage(
      name: AppRoutes.login,
      page: () => LoginScreen(),
      binding: LoginBinding(),
    ),
  ];
}
