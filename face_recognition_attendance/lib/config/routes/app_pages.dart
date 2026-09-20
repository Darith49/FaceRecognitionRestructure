import 'package:face_recognition_attendance/config/navigation/navigation_binding.dart';
import 'package:face_recognition_attendance/config/navigation/navigation_screen.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/features/auth/binding/login_binding.dart';
import 'package:face_recognition_attendance/features/auth/view/login_screen.dart';
import 'package:face_recognition_attendance/features/clock_screen/binding/clock_binding.dart';
import 'package:face_recognition_attendance/features/clock_screen/view/clock_screen.dart';
import 'package:face_recognition_attendance/features/permission_screen/binding/permission_binding.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:face_recognition_attendance/features/permission_screen/view/permission_screen.dart';
import 'package:face_recognition_attendance/features/permission_screen/view/request_permission_screen.dart';
import 'package:face_recognition_attendance/features/permission_screen/view/session_list_screen.dart';
import 'package:face_recognition_attendance/features/request_information_screen/view/request_detail_screen.dart';
import 'package:face_recognition_attendance/features/request_information_screen/view/request_information_screen.dart';
import 'package:face_recognition_attendance/features/request_information_screen/view/request_list_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
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

    // ---------- Task 4 : Clock, Request Information, Permission ----------
    GetPage(
      name: AppRoutes.clock,
      page: () => const ClockScreen(),
      binding: ClockBinding(),
    ),

    // The Request page opened on top of another page (it has a back arrow).
    GetPage(
      name: AppRoutes.request,
      page: () => const RequestScreen(showBackButton: true),
    ),

    GetPage(
      name: AppRoutes.requestInformation,
      page: () => const RequestInformationScreen(),
    ),

    GetPage(
      name: AppRoutes.requestUnauthorized,
      page: () => const RequestListScreen(status: RequestStatus.pending),
      binding: PermissionBinding(),
    ),

    GetPage(
      name: AppRoutes.requestAuthorized,
      page: () => const RequestListScreen(status: RequestStatus.approved),
      binding: PermissionBinding(),
    ),

    GetPage(
      name: AppRoutes.requestDetail,
      page: () => const RequestDetailScreen(),
      binding: PermissionBinding(),
    ),

    GetPage(
      name: AppRoutes.permission,
      page: () => const PermissionScreen(),
      binding: PermissionBinding(),
    ),

    GetPage(
      name: AppRoutes.requestPermission,
      page: () => const RequestPermissionScreen(),
      binding: PermissionBinding(),
    ),

    GetPage(
      name: AppRoutes.permissionSessions,
      page: () => const SessionListScreen(),
      binding: PermissionBinding(),
    ),
  ];
}
