import 'dart:typed_data';
import 'package:face_recognition_attendance/core/utils/date_text.dart';

/// Pending = awaiting approval, Approved = confirmed.
enum OvertimeStatus { pending, approved }

extension OvertimeStatusLabel on OvertimeStatus {
  String get label {
    switch (this) {
      case OvertimeStatus.pending:
        return 'Pending';
      case OvertimeStatus.approved:
        return 'Approved';
    }
  }
}

/// One overtime request (submitted).
class OvertimeRequest {
  const OvertimeRequest({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.date,
    required this.fromTime,
    required this.toTime,
    required this.reason,
    required this.status,
    this.hasAttachment = false,
    this.attachmentName,
    this.attachmentBytes,
    this.attachmentSize,
    this.attachmentPath,
  });

  final String id;
  final String fullName;
  final String employeeId;
  final DateTime date;
  final DateTime fromTime;
  final DateTime toTime;
  final String reason;
  final OvertimeStatus status;
  final bool hasAttachment;
  final String? attachmentName;
  final Uint8List? attachmentBytes;
  final int? attachmentSize;
  final String? attachmentPath;

  Duration get duration => toTime.difference(fromTime);

  /// "1 hour" / "1 hour 30 minutes" / "2 hours"
  String get durationLabel {
    final minutes = duration.inMinutes;
    if (minutes <= 0) return '0 minutes';

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('$hours hour${hours == 1 ? '' : 's'}');
    if (remaining > 0) {
      parts.add('$remaining minute${remaining == 1 ? '' : 's'}');
    }
    return parts.join(' ');
  }

  String get timeRangeLabel =>
      '${DateText.time(fromTime)} - ${DateText.time(toTime)}';

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString() ?? 'pending';
    final status = statusStr == 'approved' ? OvertimeStatus.approved : OvertimeStatus.pending;
    final date = DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();

    DateTime parseTime(String? tStr) {
      if (tStr == null || tStr.isEmpty) return date;
      if (tStr.contains('T')) {
        return DateTime.tryParse(tStr) ?? date;
      }
      final parts = tStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? date.hour;
        final m = int.tryParse(parts[1]) ?? date.minute;
        return DateTime(date.year, date.month, date.day, h, m);
      }
      return date;
    }

    final fromTime = parseTime(json['start_time']?.toString());
    final toTime = parseTime(json['end_time']?.toString());
    final attachUrl = json['attachment']?.toString();

    return OvertimeRequest(
      id: json['id']?.toString() ?? '',
      fullName: json['employee_name']?.toString() ?? '',
      employeeId: json['employee_code']?.toString() ?? '',
      date: date,
      fromTime: fromTime,
      toTime: toTime,
      reason: json['reason']?.toString() ?? '',
      status: status,
      hasAttachment: attachUrl != null && attachUrl.isNotEmpty,
      attachmentPath: attachUrl,
    );
  }
}
