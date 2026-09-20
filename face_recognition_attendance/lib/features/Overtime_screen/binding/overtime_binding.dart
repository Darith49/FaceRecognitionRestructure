import 'package:face_recognition_attendance/features/overtime_screen/controller/overtime_controller.dart';
import 'package:get/get.dart';

/// Both Overtime pages (list + request form) share ONE controller,
/// so a request submitted on the form shows up on the list right away.
class OvertimeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OvertimeController>()) {
      Get.put<OvertimeController>(OvertimeController(), permanent: true);
    }
  }
}
