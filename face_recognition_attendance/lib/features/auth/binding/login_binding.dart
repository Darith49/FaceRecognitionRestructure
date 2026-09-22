import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:get/get.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginController>()) {
      Get.put<LoginController>(
        LoginController(),
        permanent: true,
      );
    }
  }
}
