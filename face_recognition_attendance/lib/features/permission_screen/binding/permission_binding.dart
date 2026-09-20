import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:get/get.dart';

/// All Permission / Request Information pages share ONE controller,
/// so a request submitted on one page shows up on the others.
class PermissionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PermissionController>()) {
      Get.put<PermissionController>(PermissionController(), permanent: true);
    }
  }
}
