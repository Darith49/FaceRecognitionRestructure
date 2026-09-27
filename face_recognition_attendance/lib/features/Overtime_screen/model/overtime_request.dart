import 'dart:typed_data';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:get/get.dart';

/// Pending = awaiting approval, Approved = confirmed, Rejected = declined.
enum OvertimeStatus { pending, approved, rejected }

extension OvertimeStatusLabel on OvertimeStatus {
  String get label {
    switch (this) {
      case OvertimeStatus.pending:
        return 'Pending'.tr;
      case OvertimeStatus.approved:
        return 'Approved'.tr;
      case OvertimeStatus.rejected:
        return 'Rejected'.tr;
    }
  }

  String get displayName => label;
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
    this.employeeUid,
    this.employeeEmail,
    this.employeeRole,
    this.employeeBranch,
    this.employeeDepartment,
    this.reviewNotes,
    this.reviewerName,
    this.hasAttachment = false,
    this.attachmentName,
    this.attachmentBytes,
    this.attachmentSize,
    this.attachmentPath,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String employeeId;
  final String? employeeUid;
  final String? employeeEmail;
  final String? employeeRole;
  final String? employeeBranch;
  final String? employeeDepartment;
  final DateTime date;
  final DateTime fromTime;
  final DateTime toTime;
  final String reason;
  final OvertimeStatus status;
  final String? reviewNotes;
  final String? reviewerName;
  final bool hasAttachment;
  final String? attachmentName;
  final Uint8List? attachmentBytes;
  final int? attachmentSize;
  final String? attachmentPath;
  final DateTime? createdAt;

  Duration get duration => toTime.difference(fromTime);

  /// "1 hour" / "1 hour 30 minutes" / "2 hours"
  String get durationLabel {
    final minutes = duration.inMinutes;
    if (minutes <= 0) return '0 minutes'.tr;

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('$hours ${hours == 1 ? 'hour'.tr : 'hours'.tr}');
    if (remaining > 0) {
      parts.add('$remaining ${remaining == 1 ? 'minute'.tr : 'minutes'.tr}');
    }
    return parts.join(' ');
  }

  String get timeRangeLabel =>
      '${DateText.time(fromTime)} - ${DateText.time(toTime)}';

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'pending';
    final OvertimeStatus status;
    if (statusStr == 'approved') {
      status = OvertimeStatus.approved;
    } else if (statusStr == 'rejected') {
      status = OvertimeStatus.rejected;
    } else {
      status = OvertimeStatus.pending;
    }
    final date =
        DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();

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

    final fromTimeStr =
        json['from_time']?.toString() ?? json['start_time']?.toString();
    final toTimeStr =
        json['to_time']?.toString() ?? json['end_time']?.toString();
    final fromTime = parseTime(fromTimeStr);
    final toTime = parseTime(toTimeStr);
    final attachUrl =
        json['attachment']?.toString() ?? json['attachment_url']?.toString();

    final employeeId =
        json['employee_id_code']?.toString() ??
        json['employee_code']?.toString() ??
        json['employee_id']?.toString() ??
        '';

    return OvertimeRequest(
      id: json['id']?.toString() ?? '',
      fullName: json['employee_name']?.toString() ?? '',
      employeeId: employeeId,
      employeeUid: json['employee_uid']?.toString(),
      employeeEmail: json['employee_email']?.toString(),
      employeeRole: json['employee_role']?.toString(),
      employeeBranch: json['employee_branch']?.toString(),
      employeeDepartment: json['employee_department']?.toString(),
      date: date,
      fromTime: fromTime,
      toTime: toTime,
      reason: json['reason']?.toString() ?? '',
      status: status,
      reviewNotes: json['review_notes']?.toString(),
      reviewerName: json['reviewer_name']?.toString(),
      hasAttachment: attachUrl != null && attachUrl.isNotEmpty,
      attachmentPath: attachUrl,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_name': fullName,
      'employee_id_code': employeeId,
      'employee_uid': employeeUid,
      'employee_email': employeeEmail,
      'employee_role': employeeRole,
      'employee_branch': employeeBranch,
      'employee_department': employeeDepartment,
      'date': "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'start_time': "${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}:00",
      'end_time': "${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}:00",
      'reason': reason,
      'status': status.name,
      'review_notes': reviewNotes,
      'reviewer_name': reviewerName,
      'attachment_url': attachmentPath,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
