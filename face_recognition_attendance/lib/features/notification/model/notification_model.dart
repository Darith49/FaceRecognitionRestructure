import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:get/get.dart';

class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String notifType;
  final String? refId;
  final String senderName;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.notifType,
    this.refId,
    required this.senderName,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      notifType: json['notif_type']?.toString() ?? 'general',
      refId: json['ref_id']?.toString(),
      senderName: json['sender_name']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      notifType: notifType,
      refId: refId,
      senderName: senderName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${'m ago'.tr}';
    if (diff.inHours < 24) return '${diff.inHours}${'h ago'.tr}';
    if (diff.inDays < 7) return '${diff.inDays}${'d ago'.tr}';
    return DateText.monthShortDay(createdAt);
  }
}
