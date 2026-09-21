import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key, this.showBackButton = false});

  /// false = the "Request" tab of the bottom bar (no back arrow).
  /// true  = opened on top of another page, for example from the Clock screen.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RequestColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: showBackButton ? 24 : 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (showBackButton) ...[
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 28,
                          color: RequestColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        'request_title'.tr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: RequestColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // MANAGEMENT & SERVICES Section
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'MANAGEMENT & SERVICES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  useOwnLayer: true,
                  padding: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ServiceRow(
                        icon: Icons.calendar_today_rounded,
                        iconColor: RequestColors.primary,
                        title: 'My Schedule',
                        onTap: () => Get.toNamed(AppRoutes.schedule),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ServiceRow(
                        icon: Icons.arrow_outward_rounded,
                        iconColor: RequestColors.approvedStatus,
                        title: 'Leave Request',
                        onTap: () => Get.toNamed(AppRoutes.leave),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ServiceRow(
                        icon: Icons.access_time_rounded,
                        iconColor: RequestColors.gold,
                        title: 'Overtime',
                        onTap: () => Get.toNamed(AppRoutes.overtime),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ServiceRow(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Clock Attendance',
                        onTap: () => Get.toNamed(AppRoutes.clock),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ServiceRow(
                        icon: Icons.lightbulb_outline_rounded,
                        iconColor: RequestColors.gold,
                        title: 'Suggestion Box',
                        onTap: () => Get.toNamed(AppRoutes.suggestion),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Permission & Authorization
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  useOwnLayer: true,
                  padding: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Get.toNamed(AppRoutes.permission),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.how_to_reg_rounded,
                              size: 22,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Permission & Authorization',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: RequestColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Request permissions or authorization changes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: RequestColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: RequestColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // REQUEST ACTIVITY Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'REQUEST ACTIVITY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.requestInformation),
                      child: const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: RequestColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  useOwnLayer: true,
                  padding: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ActivityRow(
                        icon: Icons.schedule_rounded,
                        iconColor: RequestColors.gold,
                        title: 'Unauthorized',
                        subtitle: 'Pending review',
                        badgeText: '1 Pending',
                        badgeColor: RequestColors.gold,
                        onTap: () => Get.toNamed(AppRoutes.requestUnauthorized),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ActivityRow(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: RequestColors.approvedStatus,
                        title: 'Authorized',
                        subtitle: 'Completed & archived',
                        badgeText: '14 Total',
                        badgeColor: RequestColors.approvedStatus,
                        onTap: () => Get.toNamed(AppRoutes.requestAuthorized),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Activity Row ────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
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
                      fontSize: 12,
                      color: RequestColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: RequestColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Service Row ─────────────────────────────────────────────────────────────

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: RequestColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: RequestColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
