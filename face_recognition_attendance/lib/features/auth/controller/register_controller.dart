import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/services/firebase_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  final fullnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final employeeIdController = TextEditingController();

  final Rx<UserRole> selectedRole = UserRole.employee.obs;

  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  void selectRole(UserRole role) {
    selectedRole.value = role;
  }

  Future<void> register() async {
    final fullname = fullnameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final empId = employeeIdController.text.trim();

    // Validation
    if (fullname.isEmpty) {
      _showError('Full name is required');
      return;
    }

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _firebaseService.register(
        fullname: fullname,
        email: email,
        password: password,
        role: selectedRole.value,
        employeeId: empId.isNotEmpty ? empId : null,
      );

      // Save user session
      final token = await _firebaseService.getIdToken(forceRefresh: true);
      final firebaseUser = _firebaseService.getCurrentUser();

      await SecureStorageService().saveUserSession(
        uid: user.uid,
        email: user.email,
        accessToken: token ?? '',
        refreshToken: firebaseUser?.refreshToken,
        userData: user.toJson(),
      );

      // Sync user into LoginController if active
      if (Get.isRegistered<LoginController>()) {
        final loginCtrl = Get.find<LoginController>();
        loginCtrl.currentuser.value = user;
        loginCtrl.hasFaceRegistered.value = user.hasFaceRegistered;
      }

      Get.snackbar(
        'Account Created',
        'Welcome, ${user.fullname}! Your ${userRoleToString(user.role).toUpperCase()} account is ready.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );

      // Navigate to app home
      Get.offAllNamed(AppRoutes.navigation);
    } catch (e) {
      final msg = _friendlyError(e);
      errorMessage.value = msg;
      _showError(msg);
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Registration Failed',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) {
      return 'That email address is already in use by another account.';
    }
    if (msg.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return msg;
  }

  @override
  void onClose() {
    fullnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    employeeIdController.dispose();
    super.onClose();
  }
}
