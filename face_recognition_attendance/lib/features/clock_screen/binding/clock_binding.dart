import 'package:face_recognition_attendance/features/clock_screen/controller/clock_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:get/get.dart';

class ClockBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
    }
    Get.lazyPut<ClockController>(() => ClockController());
  }
}
