import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final AuthController authController;

  LoginController(this.authController);

  //Form Controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //UI State
  final isPasswordHidden = true.obs;
  final rememberMe = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
