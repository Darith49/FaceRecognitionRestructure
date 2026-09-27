import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full Executive Action Panel & Live Telemetry for CEO and Executive Admin.
class CeoActionPanel extends StatelessWidget {
  final HomeController controller;

  const CeoActionPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 0. Executive Attendance Card ───
          _CeoAttendanceCard(controller: controller),

          const SizedBox(height: 16),

          // ─── 1. Quick Stats Summary (3 Metric Cards) ───
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _CeoStatCard(
                    icon: FluentIcons.building_bank_24_regular,
                    color: const Color(0xFF0F766E),
                    label: 'Branches'.tr,
                    count: controller.branchController.branches.length,
                    onTap: () => Get.toNamed(AppRoutes.branchList),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => _CeoStatCard(
                    icon: FluentIcons.building_multiple_24_regular,
                    color: const Color(0xFF1D4ED8),
                    label: 'Departments'.tr,
                    count: controller.departmentController.departments.length,
                    onTap: () => Get.toNamed(AppRoutes.departmentList),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => _CeoStatCard(
                    icon: FluentIcons.people_team_24_regular,
                    color: const Color(0xFFB45309),
                    label: 'Employees'.tr,
                    count: controller.employeeController.employees.length,
                    onTap: () => Get.toNamed(AppRoutes.employeeList),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── 1.5. CEO Control Panel Entry Card ───
          InkWell(
            onTap: () => Get.toNamed(AppRoutes.ceoPanel),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(FluentIcons.sparkle_24_filled, color: Colors.white, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CEO Control Panel'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Full telemetry, biometric controls & organization oversight'.tr,
                          style: const TextStyle(fontSize: 11, color: Color(0xFFDDD6FE)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(FluentIcons.chevron_right_24_regular, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── 2. Administrative Action Tiles ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: appleCardDecoration(context: context, radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      FluentIcons.shield_badge_24_regular,
                      color: RequestColors.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CEO Management'.tr,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkText
                                  : RequestColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quick administrative actions'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : RequestColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : null,
                ),
                const SizedBox(height: 14),

                // 1. Create Branch
                _CeoActionTile(
                  icon: FluentIcons.building_bank_link_24_regular,
                  iconBg: const Color(0xFF0F766E),
                  title: 'Create Branch'.tr,
                  subtitle: 'Set up branch location & GPS geofence'.tr,
                  onTap: () async {
                    final result = await Get.toNamed(AppRoutes.createBranch);
                    if (result == true) {
                      controller.refreshAdminOverview();
                    }
                  },
                ),
                const SizedBox(height: 10),

                // 2. Create Department
                _CeoActionTile(
                  icon: FluentIcons.building_multiple_24_regular,
                  iconBg: const Color(0xFF1D4ED8),
                  title: 'Create Department'.tr,
                  subtitle: 'Add department to an existing branch'.tr,
                  onTap: () async {
                    final result = await Get.toNamed(
                      AppRoutes.createDepartment,
                    );
                    if (result == true) {
                      controller.refreshAdminOverview();
                    }
                  },
                ),
                const SizedBox(height: 10),

                // 3. Create User
                _CeoActionTile(
                  icon: FluentIcons.person_add_24_regular,
                  iconBg: const Color(0xFFB45309),
                  title: 'Create User'.tr,
                  subtitle: 'Invite Manager, Leader, or Employee'.tr,
                  onTap: () async {
                    final result = await Get.toNamed(AppRoutes.createEmployee);
                    if (result == true) {
                      controller.refreshAdminOverview();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── 3. Recent Activity / Created Lists Preview ───
          _RecentCreatedOverview(controller: controller),
        ],
      ),
    );
  }
}

class _CeoAttendanceCard extends StatelessWidget {
  final HomeController controller;

  const _CeoAttendanceCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: appleCardDecoration(context: context, radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(
                  FluentIcons.clock_24_filled,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Executive Attendance'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(() {
                        final state = controller.state.value;
                        String statusDesc;
                        Color statusColor;
                        if (state == CheckState.completed || state == CheckState.checkedOut) {
                          statusDesc = 'All Shifts Recorded'.tr;
                          statusColor = RequestColors.approvedStatus;
                        } else if (state == CheckState.session1CheckedIn || state == CheckState.session2CheckedIn) {
                          statusDesc = 'Clocked In • Shift in progress'.tr;
                          statusColor = RequestColors.primary;
                        } else {
                          statusDesc = 'Ready to Clock In'.tr;
                          statusColor = RequestColors.textSecondary;
                        }
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusDesc,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.clock),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: RequestColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Full View'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: RequestColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          FluentIcons.chevron_right_24_regular,
                          size: 16,
                          color: RequestColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppColors.darkBorder : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Obx(() {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S SHIFT'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: RequestColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S1: ${controller.session1SchedIn.value} - ${controller.session1SchedOut.value}  •  S2: ${controller.session2SchedIn.value} - ${controller.session2SchedOut.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'WORKED'.tr,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                          ),
                        ),
                        Text(
                          controller.totalHoursText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Obx(() {
              final state = controller.state.value;
              final hasFace = controller.hasFaceRegistered;
              final isDone = state == CheckState.completed || state == CheckState.checkedOut;

              Color btnColor;
              String btnText;
              IconData btnIcon;

              if (!hasFace) {
                btnColor = const Color(0xFF7C3AED);
                btnText = 'Register Face First'.tr;
                btnIcon = FluentIcons.camera_24_filled;
              } else if (isDone) {
                btnColor = RequestColors.approvedStatus;
                btnText = 'Completed for Today'.tr;
                btnIcon = FluentIcons.checkmark_circle_24_filled;
              } else {
                switch (state) {
                  case CheckState.session1NotCheckedIn:
                  case CheckState.notCheckedIn:
                  case CheckState.session2NotCheckedIn:
                    btnColor = RequestColors.primary;
                    btnText = '${'Clock In'.tr} (${controller.buttonSubtext})';
                    btnIcon = FluentIcons.door_arrow_left_24_regular;
                    break;
                  case CheckState.session1CheckedIn:
                  case CheckState.checkedIn:
                  case CheckState.session2CheckedIn:
                    btnColor = RequestColors.danger;
                    btnText = '${'Clock Out'.tr} (${controller.buttonSubtext})';
                    btnIcon = FluentIcons.sign_out_24_regular;
                    break;
                  default:
                    btnColor = RequestColors.primary;
                    btnText = 'Clock In'.tr;
                    btnIcon = FluentIcons.door_arrow_left_24_regular;
                }
              }

              return Material(
                color: btnColor,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: isDone ? null : () => controller.onMainButtonPressed(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(btnIcon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          btnText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CeoStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _CeoStatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: AppColors.darkBorder, width: 0.5) : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CeoActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CeoActionTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.darkSurfaceElevated
          : RequestColors.softSurface.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(icon, color: iconBg, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FluentIcons.chevron_right_24_regular,
                size: 18,
                color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCreatedOverview extends StatelessWidget {
  final HomeController controller;

  const _RecentCreatedOverview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Recent Branches Card ───
        Obx(() {
          final branches = controller.branchController.branches;
          if (branches.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: appleCardDecoration(context: context, radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FluentIcons.building_bank_24_regular,
                          size: 20,
                          color: Color(0xFF0F766E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created Branches'.tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.branchList),
                      child: Text(
                        'View All'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: RequestColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 8,
                  color: isDark ? AppColors.darkBorder : null,
                ),
                ...branches.take(3).map(
                      (b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                FluentIcons.location_24_regular,
                                size: 20,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${'Radius'.tr}: ${b.radius.toInt()}m ${'geofence'.tr}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${b.employeeCount} ${'staff'.tr}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          );
        }),

        // ─── Recent Departments Card ───
        Obx(() {
          final departments = controller.departmentController.departments;
          if (departments.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: appleCardDecoration(context: context, radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FluentIcons.building_multiple_24_regular,
                          size: 20,
                          color: Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created Departments'.tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.departmentList),
                      child: Text(
                        'View All'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: RequestColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 8,
                  color: isDark ? AppColors.darkBorder : null,
                ),
                ...departments.take(3).map(
                      (d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                FluentIcons.building_multiple_24_regular,
                                size: 20,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    d.branchName.isNotEmpty ? d.branchName : 'Branch #${d.branchId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${d.employeeCount} ${'staff'.tr}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          );
        }),

        // ─── Recent Users Card ───
        Obx(() {
          final employees = controller.employeeController.employees;
          if (employees.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: appleCardDecoration(context: context, radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FluentIcons.people_team_24_regular,
                          size: 20,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Invited Users'.tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.employeeList),
                      child: Text(
                        'View All'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: RequestColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 8,
                  color: isDark ? AppColors.darkBorder : null,
                ),
                ...employees.take(3).map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: RequestColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                e.fullname.isNotEmpty ? e.fullname[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: RequestColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.fullname,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    e.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: RequestColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                e.role.name.tr.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: RequestColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
