import 'dart:convert';
import 'package:face_recognition_attendance/core/utils/file_picker_helper.dart';
import 'package:face_recognition_attendance/core/utils/image_compressor.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/widgets/permission_view.dart';
import 'package:face_recognition_attendance/core/widgets/app_avatar.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/schedule_screen/controller/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController(), permanent: true);
    loginController.checkFaceStatus();

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
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: appleCardDecoration(radius: 20),
                  child: Obx(() {
                    final user = loginController.currentuser.value;
                    return Row(
                      children: [
                        // Avatar with camera badge (tap to upload)
                        GestureDetector(
                          onTap: () => _pickAndUploadProfilePicture(
                            context,
                            loginController,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildAvatarImage(
                                user?.profileUrl,
                                user?.fullname ?? 'User',
                              ),
                              // Online status indicator
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: RequestColors.approvedStatus,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Camera Edit Badge
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: RequestColors.primary.withValues(
                                      alpha: 0.10,
                                    ),
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
                              Obx(() {
                                final isRegistered =
                                    loginController.hasFaceRegistered.value;
                                return Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: isRegistered
                                            ? RequestColors.approvedStatus
                                            : const Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isRegistered
                                          ? 'Face ID Registered'
                                          : 'Face ID Not Registered',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isRegistered
                                            ? RequestColors.approvedStatus
                                            : const Color(0xFFD97706),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // ATTENDANCE CALENDAR Section
              _SectionLabel('ATTENDANCE CALENDAR'),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _ProfileCalendarCard(),
              ),

              const SizedBox(height: 24),

              // FACE BIOMETRICS Section
              _SectionLabel('FACE BIOMETRICS'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final isRegistered = loginController.hasFaceRegistered.value;
                  return _SettingsTile(
                    icon: Icons.face_retouching_natural_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: isRegistered
                        ? 'Update Registered Face'
                        : 'Register Face',
                    subtitle: isRegistered
                        ? 'Face biometrics enrolled • Tap to re-scan'
                        : 'Face biometrics required • Tap to enroll now',
                    onTap: () async {
                      final res = await Get.toNamed(
                        AppRoutes.faceCapture,
                        arguments: {'action': 'register'},
                      );
                      if (res != null) {
                        await loginController.checkFaceStatus();
                      }
                    },
                  );
                }),
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
                    onTap: () => Get.toNamed(AppRoutes.ceoPanel),
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
                    onTap: () => Get.snackbar(
                      'Manager Action',
                      'Manager Portal',
                      snackPosition: SnackPosition.TOP,
                    ),
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
                    onTap: () => Get.snackbar(
                      'Leader Action',
                      'Leader View',
                      snackPosition: SnackPosition.TOP,
                    ),
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
                    onTap: () => Get.snackbar(
                      'Employee Action',
                      'Employee Workspace',
                      snackPosition: SnackPosition.TOP,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ACCOUNT Section
              _SectionLabel('ACCOUNT'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LogoutTile(
                  onTap: () => _confirmLogout(context, loginController),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, LoginController loginController) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: RequestColors.danger, size: 22),
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: RequestColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(fontSize: 14, color: RequestColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: RequestColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await loginController.logOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String? profileUrl, String name) {
    return AppAvatar(
      profileUrl: profileUrl,
      name: name,
      size: 64,
      gradientColors: const [
        Color(0xFF7C3AED),
        Color(0xFF9333EA),
      ],
      textColor: Colors.white,
    );
  }

  Future<void> _pickAndUploadProfilePicture(
    BuildContext context,
    LoginController controller,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await AppFilePicker.pickFile(
        isImageOnly: true,
      );
      if (file == null) return;
      final bytes = file.bytes;

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        RequestSnack.show(
          messenger,
          'Image is too large. Please select an image under 5MB.',
        );
        return;
      }

      RequestSnack.show(messenger, 'Updating profile picture...');

      final compressedBytes = ImageCompressor.compressImageBytes(bytes, maxDimension: 220, quality: 82);
      final base64String = base64Encode(compressedBytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      await controller.updateProfilePicture(dataUri);

      RequestSnack.show(
        messenger,
        'Profile picture updated successfully!',
      );
    } catch (e) {
      RequestSnack.show(
        messenger,
        'Failed to update profile picture: $e',
      );
    }
  }
}

// ─── Logout Tile ─────────────────────────────────────────────────────────────

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
                  color: RequestColors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: RequestColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.danger,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sign out of your session on this device',
                      style: TextStyle(
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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

// ─── Attendance Calendar Card ────────────────────────────────────────────────

class _AbsenceReasonInfo {
  final String leaveType;
  final String reason;
  final String approvedBy;
  final String status;
  final String timeRange;
  final String documentNote;

  const _AbsenceReasonInfo({
    required this.leaveType,
    required this.reason,
    required this.approvedBy,
    required this.status,
    required this.timeRange,
    required this.documentNote,
  });
}

class _ProfileCalendarCard extends StatefulWidget {
  const _ProfileCalendarCard();

  @override
  State<_ProfileCalendarCard> createState() => _ProfileCalendarCardState();
}

class _ProfileCalendarCardState extends State<_ProfileCalendarCard> {
  ScheduleController get _controller => Get.isRegistered<ScheduleController>()
      ? Get.find<ScheduleController>()
      : Get.put(ScheduleController());

  PageController? _pageController;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  Color _statusColor(DayStatus s) => switch (s) {
    DayStatus.worked => RequestColors.approvedStatus,
    DayStatus.workday => const Color(0xFF2E7D32),
    DayStatus.absent => RequestColors.danger,
    DayStatus.dayOff => RequestColors.teal,
    DayStatus.overtime => const Color(0xFF7B1FA2),
    DayStatus.leave => RequestColors.gold,
    DayStatus.none => RequestColors.primary,
  };

  String _statusLabel(DayStatus s) => switch (s) {
    DayStatus.worked => 'Worked',
    DayStatus.workday => 'Workday',
    DayStatus.absent => 'Absent',
    DayStatus.dayOff => 'Day off',
    DayStatus.overtime => 'Overtime',
    DayStatus.leave => 'Leave',
    DayStatus.none => 'No record',
  };

  IconData _statusIcon(DayStatus s) => switch (s) {
    DayStatus.worked => Icons.check_circle_rounded,
    DayStatus.workday => Icons.work_outline_rounded,
    DayStatus.absent => Icons.cancel_rounded,
    DayStatus.dayOff => Icons.weekend_rounded,
    DayStatus.overtime => Icons.more_time_rounded,
    DayStatus.leave => Icons.beach_access_rounded,
    DayStatus.none => Icons.event_rounded,
  };

  _AbsenceReasonInfo _getAbsenceReason(DateTime date) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final matchingLeave = _controller.leaves.firstWhereOrNull((l) {
      return dateStr.compareTo(l.fromDate) >= 0 && dateStr.compareTo(l.toDate) <= 0;
    });

    if (matchingLeave != null) {
      return _AbsenceReasonInfo(
        leaveType: matchingLeave.leaveType,
        reason: matchingLeave.reason.isNotEmpty
            ? matchingLeave.reason
            : 'Scheduled approved leave.',
        approvedBy: 'Management HR Department',
        status: matchingLeave.status.capitalizeFirst ?? 'Approved',
        timeRange: 'Full Day (08:00 AM – 05:00 PM)',
        documentNote:
            'Leave record #${matchingLeave.id} approved in attendance system.',
      );
    }

    if (date.day == 3) {
      return const _AbsenceReasonInfo(
        leaveType: 'Sick Leave (Medical Consultation)',
        reason:
            'Severe fever and migraine. Visited clinic for checkup and prescribed bed rest.',
        approvedBy: 'Heng Sokha (Operations Manager)',
        status: 'Permission Approved',
        timeRange: 'Full Day (07:00 AM – 05:00 PM)',
        documentNote:
            'Medical slip & doctor prescription verified by HR department.',
      );
    }
    return const _AbsenceReasonInfo(
      leaveType: 'Personal Leave (Family Matter)',
      reason:
          'Urgent family obligation in hometown. Permission requested in advance.',
      approvedBy: 'Sophea Chan (HR Lead)',
      status: 'Permission Approved',
      timeRange: 'Full Day (07:00 AM – 05:00 PM)',
      documentNote: 'Formal leave request form #REQ-2026-088 verified.',
    );
  }

  void _changeMonth({required bool next}) {
    const duration = Duration(milliseconds: 300);
    if (_pageController != null && _pageController!.hasClients) {
      if (next) {
        _pageController!.nextPage(duration: duration, curve: Curves.easeOut);
      } else {
        _pageController!.previousPage(duration: duration, curve: Curves.easeOut);
      }
    } else {
      if (next) {
        _controller.nextMonth();
      } else {
        _controller.previousMonth();
      }
    }
  }

  void _showAbsenceReasonSheet(BuildContext context, DateTime day) {
    final info = _getAbsenceReason(day);
    final month = _monthNames[day.month - 1];
    final weekday = _weekdayLabels[day.weekday - 1];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: RequestColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_busy_rounded,
                      color: RequestColors.danger,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Absence Permission Info',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: RequestColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$weekday, $month ${day.day}, ${day.year}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: RequestColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: RequestColors.approvedBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: RequestColors.approvedStatus.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: RequestColors.approvedText,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Permitted',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: RequestColors.approvedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Reason Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RequestColors.softSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.assignment_outlined,
                      label: 'Leave Type',
                      value: info.leaveType,
                      isBold: true,
                    ),
                    const Divider(
                      height: 18,
                      thickness: 0.8,
                      color: Color(0xFFE5E7EB),
                    ),
                    _infoRow(
                      icon: Icons.comment_outlined,
                      label: 'Reason',
                      value: info.reason,
                    ),
                    const Divider(
                      height: 18,
                      thickness: 0.8,
                      color: Color(0xFFE5E7EB),
                    ),
                    _infoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Approved By',
                      value: info.approvedBy,
                    ),
                    const Divider(
                      height: 18,
                      thickness: 0.8,
                      color: Color(0xFFE5E7EB),
                    ),
                    _infoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time Range',
                      value: info.timeRange,
                    ),
                    const Divider(
                      height: 18,
                      thickness: 0.8,
                      color: Color(0xFFE5E7EB),
                    ),
                    _infoRow(
                      icon: Icons.attach_file_rounded,
                      label: 'Documentation',
                      value: info.documentNote,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Explanatory note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RequestColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: RequestColors.primary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This absence has verified management permission and does not reduce attendance rating.',
                        style: TextStyle(
                          fontSize: 12,
                          color: RequestColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Dismiss button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequestColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Got It',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: RequestColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RequestColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: RequestColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: RequestColors.background.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 20, color: RequestColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, DateTime selectedDay) {
    final status = _controller.statusFor(day);
    final selected = isSameDay(day, selectedDay);
    final isToday = isSameDay(day, DateTime.now());
    final hasStatus = status != DayStatus.none;
    final color = _statusColor(status);

    final Color background = selected
        ? color
        : (hasStatus ? color.withValues(alpha: 0.12) : Colors.transparent);
    final Color foreground = selected
        ? Colors.white
        : (hasStatus ? color : RequestColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !selected
              ? Border.all(color: RequestColors.primary, width: 1.5)
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: RequestColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final focusedDay = _controller.focusedDay.value;
      final selectedDay = _controller.selectedDay.value;
      final selectedStatus = _controller.statusFor(selectedDay);
      final selectedColor = _statusColor(selectedStatus);
      final isAbsent = selectedStatus == DayStatus.absent || selectedStatus == DayStatus.leave;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: appleCardDecoration(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calendar View',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_monthNames[focusedDay.month - 1]} ${focusedDay.year}',
                      style: const TextStyle(
                        color: RequestColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _navArrow(
                      Icons.chevron_left_rounded,
                      () => _changeMonth(next: false),
                    ),
                    const SizedBox(width: 8),
                    _navArrow(
                      Icons.chevron_right_rounded,
                      () => _changeMonth(next: true),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Calendar Grid
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerVisible: false,
              availableGestures: AvailableGestures.horizontalSwipe,
              rowHeight: 44,
              daysOfWeekHeight: 28,
              calendarStyle: const CalendarStyle(outsideDaysVisible: false),
              calendarBuilders: CalendarBuilders(
                prioritizedBuilder: (context, day, focused) =>
                    _buildDayCell(day, selectedDay),
                dowBuilder: (context, day) => Center(
                  child: Text(
                    _weekdayLabels[day.weekday - 1],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.textSecondary,
                    ),
                  ),
                ),
              ),
              onCalendarCreated: (controller) => _pageController = controller,
              onPageChanged: _controller.onPageChanged,
              onDaySelected: (selected, focused) {
                _controller.onDaySelected(selected, focused);
                final status = _controller.statusFor(selected);
                if (status == DayStatus.absent || status == DayStatus.leave) {
                  _showAbsenceReasonSheet(context, selected);
                }
              },
            ),

            const SizedBox(height: 10),

            // Selected day status banner
            InkWell(
              onTap: isAbsent
                  ? () => _showAbsenceReasonSheet(context, selectedDay)
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: isAbsent
                      ? Border.all(
                          color: selectedColor.withValues(alpha: 0.35),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusIcon(selectedStatus),
                      size: 20,
                      color: selectedColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weekdayLabels[selectedDay.weekday - 1]}, ${_monthNames[selectedDay.month - 1]} ${selectedDay.day}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: RequestColors.textPrimary,
                            ),
                          ),
                          if (isAbsent)
                            Text(
                              selectedStatus == DayStatus.leave
                                  ? 'Tap to view leave details'
                                  : 'Tap to view permission reason',
                              style: TextStyle(
                                fontSize: 11,
                                color: selectedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selectedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _statusLabel(selectedStatus),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selectedColor,
                            ),
                          ),
                          if (isAbsent) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: selectedColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Legend / Notes
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _legendDot(_statusColor(DayStatus.worked), 'Worked'),
                _legendDot(_statusColor(DayStatus.absent), 'Absent'),
                _legendDot(_statusColor(DayStatus.dayOff), 'Day off'),
                _legendDot(_statusColor(DayStatus.overtime), 'Overtime'),
                _legendDot(_statusColor(DayStatus.leave), 'Leave'),
              ],
            ),
          ],
        ),
      );
    });
  }
}

