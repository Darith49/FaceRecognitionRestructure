import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/core/widgets/app_avatar.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  @override
  NotificationController get controller =>
      Get.isRegistered<NotificationController>()
      ? Get.find<NotificationController>()
      : Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RequestColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: RequestColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: RequestColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Obx(() {
            if (controller.unreadCount.value == 0)
              return const SizedBox.shrink();
            return TextButton(
              onPressed: () => controller.markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: RequestColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: RequestColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    color: RequestColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You will be notified about request updates and approvals here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: RequestColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = controller.notifications[index];

              return Material(
                color: notif.isRead ? Colors.white : const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (!notif.isRead) controller.markAsRead(notif.id);
                    final type = notif.notifType.toLowerCase();
                    final title = notif.title.toLowerCase();
                    final refId = notif.refId;

                    // 1. Suggestion -> Suggestion Detail or Status
                    if (type.contains('suggestion') ||
                        title.contains('suggestion')) {
                      if (refId != null && refId.isNotEmpty) {
                        Get.toNamed(
                          AppRoutes.suggestionDetail,
                          arguments: refId,
                        );
                      } else {
                        Get.toNamed(
                          AppRoutes.suggestion,
                          arguments: {'tab': 1},
                        );
                      }
                      return;
                    }

                    // 2. Leave Request / Approved / Rejected -> Leave Detail
                    if (type.contains('leave') || title.contains('leave')) {
                      if (refId != null && refId.isNotEmpty) {
                        Get.toNamed(AppRoutes.leaveDetail, arguments: refId);
                      } else {
                        Get.toNamed(AppRoutes.leave, arguments: {'tab': 1});
                      }
                      return;
                    }

                    // 3. Permission -> Permission Request Detail
                    if (type.contains('permission') ||
                        title.contains('permission')) {
                      if (refId != null && refId.isNotEmpty) {
                        Get.toNamed(AppRoutes.requestDetail, arguments: refId);
                      } else {
                        Get.toNamed(
                          AppRoutes.permission,
                          arguments: {'tab': 1},
                        );
                      }
                      return;
                    }

                    // 4. Overtime -> Overtime Detail
                    if (type.contains('overtime') ||
                        title.contains('overtime')) {
                      if (refId != null && refId.isNotEmpty) {
                        Get.toNamed(AppRoutes.overtimeDetail, arguments: refId);
                      } else {
                        Get.toNamed(AppRoutes.overtime, arguments: {'tab': 1});
                      }
                      return;
                    }

                    // Fallback
                    Get.toNamed(AppRoutes.request);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notif.isRead
                            ? Colors.black.withValues(alpha: 0.04)
                            : RequestColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAvatar(
                          profileUrl: notif.senderProfileUrl,
                          name: notif.senderName.isNotEmpty
                              ? notif.senderName
                              : 'System',
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sender name
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.senderName.isNotEmpty
                                          ? notif.senderName
                                          : 'System',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                        color: RequestColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: const BoxDecoration(
                                        color: RequestColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: RequestColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notif.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: RequestColors.textSecondary,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    notif.timeAgo,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: RequestColors.textSecondary,
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
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
