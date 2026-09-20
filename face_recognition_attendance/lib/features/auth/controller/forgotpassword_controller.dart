import 'package:face_recognition_attendance/core/service/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotpasswordController extends GetxController {
  final emailController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString successMessage = RxnString();

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      errorMessage.value = "Please enter your email";
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    successMessage.value = null;

    try {
      await _firebaseService.resetPassowrd(email: emailController.text.trim());

      successMessage.value =
          'Password reset email sent! Check your inbox to reset your password.';
      emailController.clear();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void backToLogin() {
    Get.back();
  }

    @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
