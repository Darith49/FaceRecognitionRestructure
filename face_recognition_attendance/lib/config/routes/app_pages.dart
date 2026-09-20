import 'package:face_recognition_attendance/config/navigation/navigation_binding.dart';
import 'package:face_recognition_attendance/config/navigation/navigation_screen.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/features/attendance_screen/binding/attendance_binding.dart';
import 'package:face_recognition_attendance/features/attendance_screen/view/attendance_screen.dart';
import 'package:face_recognition_attendance/features/auth/binding/login_binding.dart';
import 'package:face_recognition_attendance/features/auth/view/login_screen.dart';
import 'package:face_recognition_attendance/features/clock_screen/binding/clock_binding.dart';
import 'package:face_recognition_attendance/features/clock_screen/view/clock_screen.dart';
import 'package:face_recognition_attendance/features/leave_screen/binding/leave_binding.dart';
import 'package:face_recognition_attendance/features/leave_screen/view/leave_detail_screen.dart';
import 'package:face_recognition_attendance/features/leave_screen/view/leave_screen.dart';
import 'package:face_recognition_attendance/features/leave_screen/view/request_leave_screen.dart';
import 'package:face_recognition_attendance/features/overtime_screen/binding/overtime_binding.dart';
import 'package:face_recognition_attendance/features/overtime_screen/view/overtime_detail_screen.dart';
import 'package:face_recognition_attendance/features/overtime_screen/view/overtime_list_screen.dart';
import 'package:face_recognition_attendance/features/overtime_screen/view/request_overtime_screen.dart';
import 'package:face_recognition_attendance/features/permission_screen/binding/permission_binding.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:face_recognition_attendance/features/permission_screen/view/permission_screen.dart';
import 'package:face_recognition_attendance/features/permission_screen/view/request_permission_screen.dart';
import 'package:face_recognition_attendance/features/permission_screen/view/session_list_screen.dart';
import 'package:face_recognition_attendance/features/request_information_screen/view/request_detail_screen.dart';
import 'package:face_recognition_attendance/features/request_information_screen/view/request_information_screen.dart';
import 'package:face_recognition_attendance/features/request_information_screen/view/request_list_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
import 'package:face_recognition_attendance/features/schedule_screen/binding/schedule_binding.dart';
import 'package:face_recognition_attendance/features/schedule_screen/view/schedule_screen.dart';
import 'package:face_recognition_attendance/features/suggestion_screen/binding/suggestion_binding.dart';
import 'package:face_recognition_attendance/features/suggestion_screen/view/suggestion_detail_screen.dart';
import 'package:face_recognition_attendance/features/suggestion_screen/view/suggestion_screen.dart';
import 'package:face_recognition_attendance/features/suggestion_screen/view/suggestion_status_screen.dart';
import 'package:flutter/scheduler.dart';
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

    // ---------- Clock, Request Information, Permission ----------
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

    GetPage(
      name: AppRoutes.attendance,
      page: () => const AttendanceScreen(),
      binding: AttendanceBinding(),
    ),

    // ---------- Leave ----------
    GetPage(
      name: AppRoutes.leave,
      page: () => const LeaveScreen(),
      binding: LeaveBinding(),
    ),

    GetPage(
      name: AppRoutes.requestLeave,
      page: () => const RequestLeaveScreen(),
      binding: LeaveBinding(),
    ),

    GetPage(
      name: AppRoutes.leaveDetail,
      page: () => const LeaveDetailScreen(),
      binding: LeaveBinding(),
    ),

    // ---------- Overtime ----------
    GetPage(
      name: AppRoutes.overtime,
      page: () => const OvertimeListScreen(),
      binding: OvertimeBinding(),
    ),

    GetPage(
      name: AppRoutes.requestOvertime,
      page: () => const RequestOvertimeScreen(),
      binding: OvertimeBinding(),
    ),

    GetPage(
      name: AppRoutes.overtimeDetail,
      page: () => const OvertimeDetailScreen(),
      binding: OvertimeBinding(),
    ),

    // ---------- Suggestion ----------
    GetPage(
      name: AppRoutes.suggestion,
      page: () => const SuggestionScreen(),
      binding: SuggestionBinding(),
    ),

    GetPage(
      name: AppRoutes.suggestionStatus,
      page: () => const SuggestionStatusScreen(),
      binding: SuggestionBinding(),
    ),

    GetPage(
      name: AppRoutes.suggestionDetail,
      page: () => const SuggestionDetailScreen(),
      binding: SuggestionBinding(),
    ),

    // ----------- Schedule -----------
    GetPage(
      name: AppRoutes.schedule,
      page: () => const ScheduleScreen(showBackButton: true),
      binding: ScheduleBinding(),
    ),
  ];
}
