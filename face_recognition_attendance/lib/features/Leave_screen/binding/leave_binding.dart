import 'package:face_recognition_attendance/features/leave_screen/controller/leave_controller.dart';
import 'package:get/get.dart';

/// Both Leave pages (list + request form) share ONE controller,
/// so a request submitted on the form shows up on the list right away.
class LeaveBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LeaveController>()) {
      Get.put<LeaveController>(LeaveController(), permanent: true);
    }
  }
}
