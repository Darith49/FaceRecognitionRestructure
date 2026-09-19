import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:get/get.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(
        Get.find<AuthController>(),
      ),
    );
  }
}
