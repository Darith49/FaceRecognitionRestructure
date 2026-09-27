import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Real-time live presence and subordinate request telemetry widget
/// specifically designed for Team Leaders and Branch Managers.
class SupervisorTeamLiveCard extends StatelessWidget {
  const SupervisorTeamLiveCard({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLeader = controller.isLeader;
    final title = isLeader ? 'Team Today'.tr : 'Branch Presence'.tr;
    final subtitle = isLeader
        ? 'Real-time department staff attendance'.tr
        : 'Live operational facility attendance'.tr;

    return Obx(() {
      final total = controller.teamTotalCount.value;
      final present = controller.teamPresentCount.value;
      final lateCount = controller.teamLateCount.value;
      final absent = controller.teamAbsentCount.value;
      final onLeave = controller.teamOnLeaveCount.value;
      final pending = controller.teamPendingApprovalsCount.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: appleCardDecoration(context: context, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (isLeader ? RequestColors.primary : const Color(0xFF7C3AED)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isLeader ? FluentIcons.people_community_24_regular : FluentIcons.building_multiple_24_regular,
                    color: isLeader ? RequestColors.primary : const Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
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
                // Live Indicator Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RequestColors.approvedStatus.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: RequestColors.approvedStatus,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'LIVE'.tr,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: RequestColors.approvedStatus,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Telemetry Grid
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Present'.tr,
                    count: present.toString(),
                    color: RequestColors.approvedStatus,
                    icon: FluentIcons.checkmark_circle_24_regular,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'Late'.tr,
                    count: lateCount.toString(),
                    color: RequestColors.gold,
                    icon: FluentIcons.clock_alarm_24_regular,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'Absent'.tr,
                    count: absent.toString(),
                    color: RequestColors.danger,
                    icon: FluentIcons.dismiss_circle_24_regular,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'On Leave'.tr,
                    count: onLeave.toString(),
                    color: const Color(0xFF6366F1),
                    icon: FluentIcons.beach_24_regular,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            // Pending Approvals Banner (if any)
            if (pending > 0) ...[
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.request),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: RequestColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: RequestColors.gold.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.alert_badge_24_regular,
                          color: RequestColors.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$pending ${pending == 1 ? "request requires your review".tr : "requests require your review".tr}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                        Icon(
                          FluentIcons.chevron_right_24_regular,
                          size: 16,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0)),
            const SizedBox(height: 10),

            // Quick footer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$total ${'Total Assigned Staff'.tr}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.navigation),
                  child: Text(
                    'Manage Roster'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final String count;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
