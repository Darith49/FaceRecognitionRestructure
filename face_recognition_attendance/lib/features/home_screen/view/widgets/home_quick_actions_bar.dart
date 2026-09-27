import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Quick services shortcuts grid for seamless application access.
class HomeQuickActionsBar extends StatelessWidget {
  const HomeQuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _ActionItem(
        label: 'Leave'.tr,
        icon: FluentIcons.beach_24_regular,
        color: RequestColors.approvedStatus,
        route: AppRoutes.leave,
      ),
      _ActionItem(
        label: 'Overtime'.tr,
        icon: FluentIcons.clock_24_regular,
        color: const Color(0xFF7C3AED),
        route: AppRoutes.overtime,
      ),
      _ActionItem(
        label: 'Permission'.tr,
        icon: FluentIcons.person_available_24_regular,
        color: RequestColors.primary,
        route: AppRoutes.permission,
      ),
      _ActionItem(
        label: 'Suggestion'.tr,
        icon: FluentIcons.lightbulb_24_regular,
        color: RequestColors.gold,
        route: AppRoutes.suggestion,
      ),
      _ActionItem(
        label: 'Schedule'.tr,
        icon: FluentIcons.calendar_ltr_24_regular,
        color: const Color(0xFF0284C7),
        route: AppRoutes.schedule,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'QUICK SERVICES'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: appleCardDecoration(context: context, radius: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: actions.map((item) {
                return GestureDetector(
                  onTap: () => Get.toNamed(item.route),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: isDark ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.color.withValues(alpha: isDark ? 0.30 : 0.20),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: item.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}
