import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/features/clock_screen/controller/clock_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:face_recognition_attendance/features/myteam_screen/controller/myteam_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:face_recognition_attendance/features/request_screen/controller/request_screen_controller.dart';
import 'package:face_recognition_attendance/features/schedule_screen/controller/schedule_controller.dart';
import 'package:get/get.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<ClockController>(() => ClockController(), fenix: true);
    Get.lazyPut<RequestScreenController>(() => RequestScreenController(), fenix: true);
    Get.lazyPut<MyTeamController>(() => MyTeamController(), fenix: true);
    Get.lazyPut<ScheduleController>(() => ScheduleController(), fenix: true);
    // NotificationController registered globally so unread badge works on all tabs
    Get.lazyPut<NotificationController>(() => NotificationController(), fenix: true);
  }
}


