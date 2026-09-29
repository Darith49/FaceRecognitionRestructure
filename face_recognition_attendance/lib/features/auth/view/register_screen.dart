import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/auth/controller/register_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
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
                            : 'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'auth_register_subtitle'.tr.isNotEmpty && 'auth_register_subtitle'.tr != 'auth_register_subtitle'
                            ? 'auth_register_subtitle'.tr
                            : 'Sign up with your credentials and select your organizational role',
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

                // ==================== SECTION 1: ROLE SELECTION ====================
                _buildSectionHeader(
                  title: 'auth_select_role'.tr.isNotEmpty && 'auth_select_role'.tr != 'auth_select_role'
                      ? 'auth_select_role'.tr
                      : 'Select Organizational Role',
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                // Compact role selector chips
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCompactRoleChip(
                          role: UserRole.ceo,
                          label: 'CEO',
                          icon: Icons.workspace_premium_rounded,
                          accentColor: const Color(0xFFE5A93C),
                          isSelected: controller.selectedRole.value == UserRole.ceo,
                          isDark: isDark,
                        ),
                        _buildCompactRoleChip(
                          role: UserRole.admin,
                          label: 'Admin',
                          icon: Icons.admin_panel_settings_rounded,
                          accentColor: const Color(0xFF6366F1),
                          isSelected: controller.selectedRole.value == UserRole.admin,
                          isDark: isDark,
                        ),
                        _buildCompactRoleChip(
                          role: UserRole.manager,
                          label: 'Manager',
                          icon: Icons.manage_accounts_rounded,
                          accentColor: const Color(0xFF0071E3),
                          isSelected: controller.selectedRole.value == UserRole.manager,
                          isDark: isDark,
                        ),
                        _buildCompactRoleChip(
                          role: UserRole.leader,
                          label: 'Leader',
                          icon: Icons.groups_rounded,
                          accentColor: const Color(0xFF10B981),
                          isSelected: controller.selectedRole.value == UserRole.leader,
                          isDark: isDark,
                        ),
                        _buildCompactRoleChip(
                          role: UserRole.employee,
                          label: 'Employee',
                          icon: Icons.badge_rounded,
                          accentColor: const Color(0xFF0EA5E9),
                          isSelected: controller.selectedRole.value == UserRole.employee,
                          isDark: isDark,
                        ),
                      ],
                    )),

                const SizedBox(height: 10),

                // Dynamic selected role description banner
                Obx(() => _buildRoleDescriptionCard(
                      role: controller.selectedRole.value,
                      isDark: isDark,
                    )),

                const SizedBox(height: 22),

                // ==================== SECTION 2: PERSONAL & CREDENTIALS ====================
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

  Widget _buildCompactRoleChip({
    required UserRole role,
    required String label,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => controller.selectRole(role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.primary.withValues(alpha: 0.1))
              : (isDark ? AppColors.darkSurface : AppColors.canvasParchment),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.hairline),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.primary)
                    : (isDark ? AppColors.darkText : AppColors.ink),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDescriptionCard({required UserRole role, required bool isDark}) {
    String title;
    String desc;
    IconData icon;
    Color color;

    switch (role) {
      case UserRole.ceo:
        title = 'CEO / Executive';
        desc = 'Full corporate oversight, CEO analytics panel, branches & company permissions.';
        icon = Icons.workspace_premium_rounded;
        color = const Color(0xFFE5A93C);
        break;
      case UserRole.admin:
        title = 'System Administrator';
        desc = 'System management, provisioning staff, and assigning branches/departments.';
        icon = Icons.admin_panel_settings_rounded;
        color = const Color(0xFF6366F1);
        break;
      case UserRole.manager:
        title = 'Department Manager';
        desc = 'Department operations, shift oversight, team leave & overtime approvals.';
        icon = Icons.manage_accounts_rounded;
        color = const Color(0xFF0071E3);
        break;
      case UserRole.leader:
        title = 'Team Leader';
        desc = 'Team attendance supervision and daily operational approvals.';
        icon = Icons.groups_rounded;
        color = const Color(0xFF10B981);
        break;
      case UserRole.employee:
        title = 'Employee';
        desc = 'Face biometric attendance check-in, leave & overtime requests, personal logs.';
        icon = Icons.badge_rounded;
        color = const Color(0xFF0EA5E9);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Branch & department will be assigned by CEO / Admin afterwards.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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
