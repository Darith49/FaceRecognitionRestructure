import 'package:face_recognition_attendance/features/auth/controller/forgotpassword_controller.dart';
import 'package:get/get.dart';

class ForgotpassowrdBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotpasswordController>(() => ForgotpasswordController());
  }
}
