import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/notification/controller/notification_controller.dart';
import 'package:face_recognition_attendance/features/notification/model/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  @override
  NotificationController get controller =>
      Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>()
          : Get.put(NotificationController());

  IconData _iconForType(String type) {
    if (type.contains('leave')) return Icons.beach_access_rounded;
    if (type.contains('overtime')) return Icons.access_time_rounded;
    if (type.contains('permission')) return Icons.how_to_reg_rounded;
    if (type.contains('suggestion')) return Icons.lightbulb_outline_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _colorForType(String type) {
    if (type.contains('approved')) return RequestColors.approvedStatus;
    if (type.contains('rejected')) return RequestColors.danger;
    if (type.contains('leave')) return RequestColors.gold;
    if (type.contains('overtime')) return const Color(0xFF7C3AED);
    if (type.contains('permission')) return RequestColors.primary;
    return RequestColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RequestColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RequestColors.textPrimary, size: 20),
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
            if (controller.unreadCount.value == 0) return const SizedBox.shrink();
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
                  child: const Icon(Icons.notifications_off_outlined, color: RequestColors.primary, size: 32),
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
                  style: TextStyle(fontSize: 13, color: RequestColors.textSecondary),
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
              final color = _colorForType(notif.notifType);
              final icon = _iconForType(notif.notifType);

              return Material(
                color: notif.isRead ? Colors.white : const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (!notif.isRead) controller.markAsRead(notif.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notif.isRead ? Colors.black.withValues(alpha: 0.04) : RequestColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
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
                                notif.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: RequestColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (notif.senderName.isNotEmpty)
                                    Text(
                                      'From: ${notif.senderName}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: RequestColors.textSecondary,
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
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
