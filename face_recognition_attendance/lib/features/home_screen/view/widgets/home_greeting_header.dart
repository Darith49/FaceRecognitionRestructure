import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/app_avatar.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Top header on Home screen displaying user profile, active role chip, greeting, and notification bell.
class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Obx(() {
        final loginController = Get.isRegistered<LoginController>()
            ? Get.find<LoginController>()
            : null;
        final user = loginController?.currentuser.value;
        final role = user?.role.name ?? 'Employee';

        return Row(
          children: [
            // Avatar with online dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppAvatar(
                  profileUrl: user?.profileUrl,
                  name: controller.userName,
                  size: 50,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : RequestColors.primary.withValues(alpha: 0.20),
                    width: 2,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: RequestColors.approvedStatus,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          controller.userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : RequestColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: RequestColors.approvedStatus.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: RequestColors.approvedStatus,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${controller.greeting} • ${'Have a productive day'.tr}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Notification bell
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.notifications),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E5EA), width: 1),
                    ),
                    child: Icon(
                      FluentIcons.alert_24_regular,
                      size: 20,
                      color: isDark ? AppColors.darkText : RequestColors.textSecondary,
                    ),
                  ),
                  Obx(() {
                    final notifCtrl = Get.isRegistered<NotificationController>()
                        ? Get.find<NotificationController>()
                        : Get.put(NotificationController());
                    if (notifCtrl.unreadCount.value == 0) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${notifCtrl.unreadCount.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
