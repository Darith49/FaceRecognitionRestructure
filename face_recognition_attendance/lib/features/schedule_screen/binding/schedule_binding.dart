import 'package:face_recognition_attendance/features/schedule_screen/controller/schedule_controller.dart';
import 'package:get/get.dart';

class ScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ScheduleController>(ScheduleController());
  }
}