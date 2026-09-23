import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/features/notification/model/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool background = false}) async {
    try {
      if (!background) isLoading.value = true;
      final res = await _apiService.get('/notifications/');
      if (res is Map) {
        unreadCount.value = (res['unread_count'] as num?)?.toInt() ?? 0;
        if (res['results'] is List) {
          final list = (res['results'] as List)
              .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          notifications.assignAll(list);
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (!background) isLoading.value = false;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _apiService.post('/notifications/$id/read/');
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !notifications[idx].isRead) {
        notifications[idx] = notifications[idx].copyWith(isRead: true);
        if (unreadCount.value > 0) unreadCount.value--;
      }
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.post('/notifications/mark-all-read/');
      unreadCount.value = 0;
      notifications.assignAll(
        notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }
}
