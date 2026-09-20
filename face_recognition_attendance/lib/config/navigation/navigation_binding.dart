import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:face_recognition_attendance/features/schedule_screen/controller/schedule_controller.dart';
import 'package:get/get.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<ScheduleController>(() => ScheduleController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
