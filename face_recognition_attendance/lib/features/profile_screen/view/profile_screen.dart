import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/widgets/permission_view.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : null;

    return Scaffold(
      backgroundColor: RequestColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'profile_title'.tr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.settings),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  useOwnLayer: true,
                  padding: const EdgeInsets.all(18),
                  child: Obx(() {
                    final user = loginController?.currentuser.value;
                    return Row(
                      children: [
                        // Avatar with online dot
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF7C3AED),
                                    const Color(0xFF9333EA),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _initials(user?.fullname ?? 'User'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: RequestColors.approvedStatus,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullname ?? 'profile_name'.tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: RequestColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (user?.role != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: RequestColors.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user!.role.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: RequestColors.primary,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'profile_email'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: RequestColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: RequestColors.approvedStatus,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Face ID Registered',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: RequestColors.approvedStatus,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // PREFERENCES Section
              _SectionLabel('PREFERENCES'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: RequestColors.primary,
                  title: 'Settings & Language',
                  subtitle: 'English (US) • Notifications',
                  onTap: () => Get.toNamed(AppRoutes.settings),
                ),
              ),

              const SizedBox(height: 28),

              // ROLE-BASED PANEL ACCESS Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ROLE-BASED PANEL ACCESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'All Authorized',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CEO Control Panel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PermissionView(
                  targetPermission: AppPermission.accessCeoPanel,
                  child: _RolePanelCard(
                    title: 'CEO Control Panel',
                    subtitle: 'Full system oversight and executive controls',
                    icon: Icons.auto_awesome_rounded,
                    gradient: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    badgeText: 'ACTIVE',
                    onTap: () => Get.snackbar('CEO Action', 'CEO Panel'),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Manager Portal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PermissionView(
                  targetPermission: AppPermission.accessManagerPanel,
                  child: _RoleListTile(
                    title: 'Manager Portal',
                    subtitle: 'Team management & approval workflows',
                    icon: Icons.admin_panel_settings_rounded,
                    iconColor: RequestColors.primary,
                    onTap: () => Get.snackbar('Manager Action', 'Manager Portal'),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Leader View
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PermissionView(
                  targetPermission: AppPermission.accessLeaderPanel,
                  child: _RoleListTile(
                    title: 'Leader View',
                    subtitle: 'Direct team oversight & task delegation',
                    icon: Icons.supervisor_account_rounded,
                    iconColor: RequestColors.gold,
                    onTap: () => Get.snackbar('Leader Action', 'Leader View'),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Employee Workspace
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PermissionView(
                  targetPermission: AppPermission.accessEmployeePanel,
                  child: _RoleListTile(
                    title: 'Employee Workspace',
                    subtitle: 'Personal dashboard & self-service tools',
                    icon: Icons.person_rounded,
                    iconColor: RequestColors.approvedStatus,
                    onTap: () => Get.snackbar('Employee Action', 'Employee Workspace'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: RequestColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Settings Tile ───────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useOwnLayer: true,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: RequestColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role Panel Card (gradient, for CEO) ─────────────────────────────────────

class _RolePanelCard extends StatelessWidget {
  const _RolePanelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String? badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: Colors.white),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.90),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role List Tile (white card) ─────────────────────────────────────────────

class _RoleListTile extends StatelessWidget {
  const _RoleListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useOwnLayer: true,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: RequestColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
