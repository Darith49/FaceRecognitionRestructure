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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'auth_register_title'.tr.isNotEmpty && 'auth_register_title'.tr != 'auth_register_title'
                          ? 'auth_register_title'.tr
                          : 'Create Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.darkText : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'auth_register_subtitle'.tr.isNotEmpty && 'auth_register_subtitle'.tr != 'auth_register_subtitle'
                          ? 'auth_register_subtitle'.tr
                          : 'Sign up with your credentials and select your organizational role',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ==================== SECTION 1: ROLE SELECTION ====================
              _buildSectionHeader(
                title: 'auth_select_role'.tr.isNotEmpty && 'auth_select_role'.tr != 'auth_select_role'
                    ? 'auth_select_role'.tr
                    : 'Select Organizational Role',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              Obx(() => Column(
                    children: [
                      _buildRoleOption(
                        role: UserRole.ceo,
                        title: 'CEO / Executive',
                        description: 'Full corporate authority, analytics, and executive panels',
                        icon: Icons.workspace_premium_rounded,
                        color: const Color(0xFFE5A93C),
                        isSelected: controller.selectedRole.value == UserRole.ceo,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildRoleOption(
                        role: UserRole.admin,
                        title: 'System Administrator',
                        description: 'Company-wide system settings, branch & employee provisioning',
                        icon: Icons.admin_panel_settings_rounded,
                        color: const Color(0xFF6366F1),
                        isSelected: controller.selectedRole.value == UserRole.admin,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildRoleOption(
                        role: UserRole.manager,
                        title: 'Department Manager',
                        description: 'Department operations, shift planning, and request approvals',
                        icon: Icons.manage_accounts_rounded,
                        color: const Color(0xFF0071E3),
                        isSelected: controller.selectedRole.value == UserRole.manager,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildRoleOption(
                        role: UserRole.leader,
                        title: 'Team Leader',
                        description: 'Team attendance supervision and daily operational approvals',
                        icon: Icons.groups_rounded,
                        color: const Color(0xFF10B981),
                        isSelected: controller.selectedRole.value == UserRole.leader,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildRoleOption(
                        role: UserRole.employee,
                        title: 'Employee',
                        description: 'Biometric face attendance, leave & overtime requests, schedule',
                        icon: Icons.badge_rounded,
                        color: const Color(0xFF0EA5E9),
                        isSelected: controller.selectedRole.value == UserRole.employee,
                        isDark: isDark,
                      ),
                    ],
                  )),

              const SizedBox(height: 24),

              // ==================== SECTION 2: PERSONAL DETAILS ====================
              _buildSectionHeader(
                title: 'Personal & Account Info',
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

              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

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

              const SizedBox(height: 24),

              // ==================== SECTION 3: ASSIGNMENT ====================
              _buildSectionHeader(
                title: 'Branch & Department',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // Branch Selector
              Obx(() {
                final bList = controller.branches;
                if (bList.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel(label: 'Branch Location', isDark: isDark),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.canvasParchment,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.hairline,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: controller.selectedBranchId.value,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                          ),
                          items: bList.map((b) {
                            final bId = (b['id'] as num?)?.toInt() ?? 1;
                            return DropdownMenuItem<int>(
                              value: bId,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    size: 18,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      b['name']?.toString() ?? 'Headquarters',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? AppColors.darkText : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.selectedBranchId.value = val;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              // Department Selector
              Obx(() {
                final dList = controller.departments;
                if (dList.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel(label: 'Department', isDark: isDark),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.canvasParchment,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.hairline,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: controller.selectedDeptId.value,
                          isExpanded: true,
                          dropdownColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                          ),
                          items: dList.map((d) {
                            final dId = (d['id'] as num?)?.toInt() ?? 1;
                            return DropdownMenuItem<int>(
                              value: dId,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.apartment_rounded,
                                    size: 18,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      d['name']?.toString() ?? 'Department',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? AppColors.darkText : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.selectedDeptId.value = val;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              // ==================== SECTION 4: SECURITY ====================
              _buildSectionHeader(
                title: 'Security',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

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

              const SizedBox(height: 16),

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

              const SizedBox(height: 32),

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

              const SizedBox(height: 20),

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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required bool isDark}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
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

  Widget _buildRoleOption({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => controller.selectRole(role),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.primary.withValues(alpha: 0.08))
              : (isDark ? AppColors.darkSurface : AppColors.canvasParchment),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.hairline),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.white : AppColors.primary)
                              : (isDark ? AppColors.darkText : AppColors.ink),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SELECTED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.inkMuted48,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.hairline),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
