import 'package:face_recognition_attendance/core/permissions/permission_service.dart';
import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController());
    Get.put<PermissionService>(PermissionService());
  }
}
