import 'package:face_recognition_attendance/features/clock_screen/controller/clock_controller.dart';
import 'package:get/get.dart';

class ClockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClockController>(() => ClockController());
  }
}
