import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/auth/controller/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkText : AppColors.ink,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Badge & Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'auth_register_title'.tr.isNotEmpty && 'auth_register_title'.tr != 'auth_register_title'
                            ? 'auth_register_title'.tr
                            : 'Create Employee Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign up with your credentials to register as an employee',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==================== PERSONAL & CREDENTIALS ====================
                _buildSectionHeader(
                  title: 'Account Information',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                // Full Name
                _buildInputLabel(
                  label: 'auth_full_name'.tr.isNotEmpty && 'auth_full_name'.tr != 'auth_full_name'
                      ? 'auth_full_name'.tr
                      : 'Full Name',
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: controller.fullnameController,
                  hint: 'e.g. John Doe',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // Email Address
                _buildInputLabel(
                  label: 'auth_email'.tr,
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: controller.emailController,
                  hint: 'name@company.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // Employee ID (Optional)
                _buildInputLabel(
                  label: 'Employee ID (Optional)',
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _buildInputField(
                  controller: controller.employeeIdController,
                  hint: 'Auto-generated if left blank (e.g. EMP-008)',
                  icon: Icons.tag_rounded,
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // Password
                _buildInputLabel(label: 'auth_password'.tr, isDark: isDark),
                const SizedBox(height: 6),
                Obx(() => _buildPasswordField(
                      controller: controller.passwordController,
                      hint: 'At least 6 characters',
                      isHidden: controller.isPasswordHidden.value,
                      onToggle: () => controller.isPasswordHidden.toggle(),
                      isDark: isDark,
                    )),

                const SizedBox(height: 14),

                // Confirm Password
                _buildInputLabel(
                  label: 'auth_confirm_password'.tr.isNotEmpty && 'auth_confirm_password'.tr != 'auth_confirm_password'
                      ? 'auth_confirm_password'.tr
                      : 'Confirm Password',
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                Obx(() => _buildPasswordField(
                      controller: controller.confirmPasswordController,
                      hint: 'Re-enter your password',
                      isHidden: controller.isConfirmPasswordHidden.value,
                      onToggle: () => controller.isConfirmPasswordHidden.toggle(),
                      isDark: isDark,
                    )),

                const SizedBox(height: 28),

                // ==================== SUBMIT BUTTON ====================
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account & Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    )),

                const SizedBox(height: 16),

                // Link back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth_have_account'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () {
                        if (Get.previousRoute.isNotEmpty) {
                          Get.back();
                        } else {
                          Get.offNamed(AppRoutes.login);
                        }
                      },
                      child: Text(
                        'auth_sign_in'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required bool isDark}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: isDark ? AppColors.darkText : AppColors.ink,
      ),
    );
  }

  Widget _buildInputLabel({required String label, required bool isDark}) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.canvasParchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.hairline,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.darkText : AppColors.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.6) : AppColors.inkMuted48.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isHidden,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.canvasParchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.hairline,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isHidden,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? AppColors.darkText : AppColors.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.6) : AppColors.inkMuted48.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
