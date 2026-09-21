import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'auth_welcome_back'.tr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'auth_enter_details'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'auth_email'.tr,
                          labelStyle: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          hintText: 'example@gmail.com',
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.only(bottom: 8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Obx(
                      () => Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: controller.passwordController,
                          obscureText: controller.isPasswordHidden.value,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'auth_password'.tr,
                            labelStyle: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            contentPadding: const EdgeInsets.only(
                              bottom: 8,
                              top: 8,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => controller.isPasswordHidden.toggle(),
                              child: Icon(
                                controller.isPasswordHidden.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Obx(
                              () => SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: controller.rememberMe.value,
                                  onChanged: (val) =>
                                      controller.rememberMe.value =
                                          val ?? false,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  activeColor: AppColors.primary,
                                  side: BorderSide(
                                    color: isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'auth_remember_me'.tr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Get.toNamed(AppRoutes.forgotpassword);
                          },
                          child: Text(
                            'auth_forgot_password'.tr,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.login(
                                  email: controller.emailController.text.trim(),
                                  password: controller.passwordController.text
                                      .trim(),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'auth_sign_in'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sign in with Google
                    Obx(() {
                      final isAnyLoading =
                          controller.isLoading.value ||
                          controller.isGoogleLoading.value;
                      final isGoogleLoading = controller.isGoogleLoading.value;

                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: isAnyLoading
                              ? null
                              : () => controller.loginWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                            foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isGoogleLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/login/Google.png",
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'auth_google_sign_in'.tr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkText : AppColors.lightText,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Test Accounts Preview Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAccountRow(
                            'CEO',
                            'sonarseang@gmail.com',
                            '123456',
                            context,
                          ),
                          const Divider(height: 12),
                          _buildAccountRow(
                            'Admin',
                            'admin@gmail.com',
                            '123456',
                            context,
                          ),
                          const Divider(height: 12),
                          _buildAccountRow(
                            'Manager',
                            'manager@gmail.com',
                            '123456',
                            context,
                          ),
                          const Divider(height: 12),
                          _buildAccountRow(
                            'Leader',
                            'leader@gmail.com',
                            '123456',
                            context,
                          ),
                          const Divider(height: 12),
                          _buildAccountRow(
                            'Employee',
                            'employee@gmail.com',
                            '123456',
                            context,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountRow(String role, String email, String password, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            role,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            email,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade800,
            ),
          ),
        ),
        Text(
          password,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
