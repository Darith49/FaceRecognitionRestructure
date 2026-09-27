import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Interactive Attendance Hero Card displaying real-time clock, Cambodia date,
/// Morning & Afternoon session statuses, worked hours progress, and adjustment request.
class AttendanceHeroCard extends StatelessWidget {
  const AttendanceHeroCard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: appleCardDecoration(context: context, radius: 20),
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                Icon(
                  FluentIcons.clock_24_regular,
                  color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: Text(
                          DateText.clock(controller.now.value),
                          key: ValueKey(DateText.clock(controller.now.value)),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Text(
                        DateText.fullDate(controller.now.value),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _GoalBadge(controller: controller),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // ─── 2 Attendance Sessions ──────────────────────────────────────────
          Obx(
            () => Column(
              children: [
                // Session 1 Tile (Morning)
                _SessionTile(
                  sessionNumber: 1,
                  sessionName: 'MORNING'.tr,
                  icon: FluentIcons.weather_sunny_24_filled,
                  iconColor: const Color(0xFFF59E0B),
                  checkInTime: controller.session1CheckInText,
                  checkOutTime: controller.session1CheckOutText,
                  scheduledIn: controller.session1SchedIn.value,
                  scheduledOut: controller.session1SchedOut.value,
                  statusText: controller.session1StatusText,
                  isActive: controller.isSession1Active,
                  isDone: controller.isSession1Done,
                ),

                const SizedBox(height: 10),

                // Session 2 Tile (Afternoon)
                _SessionTile(
                  sessionNumber: 2,
                  sessionName: 'AFTERNOON'.tr,
                  icon: FluentIcons.weather_moon_24_filled,
                  iconColor: const Color(0xFF6366F1),
                  checkInTime: controller.session2CheckInText,
                  checkOutTime: controller.session2CheckOutText,
                  scheduledIn: controller.session2SchedIn.value,
                  scheduledOut: controller.session2SchedOut.value,
                  statusText: controller.session2StatusText,
                  isActive: controller.isSession2Active,
                  isDone: controller.isSession2Done,
                ),

                const SizedBox(height: 12),

                // Total Hours Summary Banner with Progress Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: controller.goalProgress >= 1.0
                        ? RequestColors.approvedStatus.withValues(alpha: 0.08)
                        : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF5F5F7)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FluentIcons.timer_24_regular,
                                size: 16,
                                color: controller.goalProgress >= 1.0
                                    ? RequestColors.approvedStatus
                                    : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'TOTAL HOURS WORKED'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            controller.totalHoursText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: controller.goalProgress >= 1.0
                                  ? RequestColors.approvedStatus
                                  : RequestColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: controller.goalProgress,
                          minHeight: 6,
                          backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            controller.goalProgress >= 1.0
                                ? RequestColors.approvedStatus
                                : RequestColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(controller.goalProgress * 100).toInt()}% ${'of 8.0h goal'.tr}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                            ),
                          ),
                          Text(
                            controller.remainingGoalText == 'Done!'
                                ? 'Goal Reached!'.tr
                                : '${controller.remainingGoalText} ${'remaining'.tr}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: controller.goalProgress >= 1.0
                                  ? RequestColors.approvedStatus
                                  : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Request Time Adjustment button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.request),
              icon: const Icon(FluentIcons.note_edit_24_regular, size: 20),
              label: Text('Request Time Adjustment'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkText : RequestColors.textPrimary,
                side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'GOAL'.tr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${controller.goalHours.toStringAsFixed(1)} ${'hrs'.tr}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: RequestColors.approvedStatus,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.sessionNumber,
    required this.sessionName,
    required this.icon,
    required this.iconColor,
    required this.checkInTime,
    required this.checkOutTime,
    required this.scheduledIn,
    required this.scheduledOut,
    required this.statusText,
    required this.isActive,
    required this.isDone,
  });

  final int sessionNumber;
  final String sessionName;
  final IconData icon;
  final Color iconColor;
  final String checkInTime;
  final String checkOutTime;
  final String scheduledIn;
  final String scheduledOut;
  final String statusText;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeBg;
    Color badgeText;
    if (isDone) {
      badgeBg = RequestColors.approvedStatus.withValues(alpha: 0.12);
      badgeText = RequestColors.approvedStatus;
    } else if (statusText == 'Absent') {
      badgeBg = RequestColors.danger.withValues(alpha: 0.12);
      badgeText = RequestColors.danger;
    } else if (isActive && checkInTime != '-- : --') {
      badgeBg = RequestColors.primary.withValues(alpha: 0.12);
      badgeText = RequestColors.primary;
    } else {
      badgeBg = isDark ? AppColors.darkBorder : const Color(0xFFF0F0F2);
      badgeText = RequestColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? RequestColors.primary.withValues(alpha: 0.35)
              : (isDark ? AppColors.darkBorder : const Color(0xFFEBECEF)),
          width: isActive ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    '${'SESSION'.tr} $sessionNumber • ${sessionName.tr}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? RequestColors.primary
                          : (isDark ? AppColors.darkText : RequestColors.textPrimary),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText.tr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SessionStatItem(
                  label: 'CHECK IN'.tr,
                  value: checkInTime,
                  subLabel: '${'Scheduled'.tr} $scheduledIn',
                  isFilled: checkInTime != '-- : --',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              ),
              Expanded(
                child: _SessionStatItem(
                  label: 'CHECK OUT'.tr,
                  value: checkOutTime,
                  subLabel: '${'Scheduled'.tr} $scheduledOut',
                  isFilled: checkOutTime != '-- : --',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionStatItem extends StatelessWidget {
  const _SessionStatItem({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.isFilled,
  });

  final String label;
  final String value;
  final String subLabel;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: RequestColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isFilled
                  ? (isDark ? AppColors.darkText : RequestColors.textPrimary)
                  : const Color(0xFF8E8E93),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: const TextStyle(
              fontSize: 11,
              color: RequestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
