import 'dart:typed_data';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:get/get.dart';

/// Pending = shown in "Pending", Approved / Rejected = shown in "History".
enum LeaveStatus { pending, approved, rejected }

extension LeaveStatusLabel on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending'.tr;
      case LeaveStatus.approved:
        return 'Approved'.tr;
      case LeaveStatus.rejected:
        return 'Rejected'.tr;
    }
  }
}

/// Helper to format 24h string "09:30:00" to "09:30 AM"
String _formatTimeStr(String timeStr) {
  try {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final isPm = hour >= 12;
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      final mStr = minute.toString().padLeft(2, '0');
      return '$h12:$mStr ${isPm ? 'PM' : 'AM'}';
    }
  } catch (_) {}
  return timeStr;
}

/// Day-type chips shown on the "Request Leave" form.
const List<String> kLeaveDayTypes = [
  'Section 1 (Morning)',
  'Section 2 (Afternoon)',
  'Full Day',
];

/// One leave request (a draft still being filled in, or a submitted one).
class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.fromDate,
    required this.toDate,
    required this.dayType,
    required this.reason,
    required this.status,
    this.session = 1,
    this.leaveMode = 'full_section',
    this.earlyLeaveTime,
    this.reviewNotes,
    this.reviewerName,
    this.fromTime,
    this.toTime,
    this.hasAttachment = false,
    this.attachmentName,
    this.attachmentBytes,
    this.attachmentSize,
    this.attachmentPath,
  });

  final String id;
  final String fullName;
  final String employeeId;
  final DateTime fromDate;
  final DateTime toDate;

  /// Target session: 1 = Section 1, 2 = Section 2, 0 = Full Day / Both
  final int session;

  /// 'full_section' or 'early_leave'
  final String leaveMode;

  /// Stored time string e.g. "09:30:00"
  final String? earlyLeaveTime;

  /// Text representation
  final String dayType;
  final String reason;
  final LeaveStatus status;
  final String? reviewNotes;
  final String? reviewerName;

  /// Optional from/to time if custom range
  final DateTime? fromTime;
  final DateTime? toTime;

  final bool hasAttachment;
  final String? attachmentName;
  final Uint8List? attachmentBytes;
  final int? attachmentSize;
  final String? attachmentPath;

  /// Inclusive number of calendar days covered by this request.
  int get dayCount => toDate.difference(fromDate).inDays + 1;

  /// Fri Sep 11 2026 or Fri Sep 11 2026 → Mon Sep 14 2026
  String get dateRangeLabel {
    final from = DateText.monthShortDay(fromDate);
    final to = DateText.monthShortDay(toDate);
    return from == to ? from : '$from  →  $to';
  }

  /// Label shown on card: "Section 1 • Leave early at 09:30 AM" or "Section 1 (07:00 – 11:00 AM)"
  String get scheduleLabel {
    if (session == 1) {
      if (leaveMode == 'early_leave' && earlyLeaveTime != null && earlyLeaveTime!.isNotEmpty) {
        return '${'Section 1'.tr} • ${'Leave Early'.tr} ${_formatTimeStr(earlyLeaveTime!)}';
      }
      return '${'Section 1'.tr} (${'Morning'.tr}: 07:00 – 11:00 AM)';
    } else if (session == 2) {
      if (leaveMode == 'early_leave' && earlyLeaveTime != null && earlyLeaveTime!.isNotEmpty) {
        return '${'Section 2'.tr} • ${'Leave Early'.tr} ${_formatTimeStr(earlyLeaveTime!)}';
      }
      return '${'Section 2'.tr} (${'Afternoon'.tr}: 01:00 – 05:00 PM)';
    } else if (session == 0) {
      return 'Full Day (Both Sections)'.tr;
    }
    if (dayType == 'Time' && fromTime != null && toTime != null) {
      return '${DateText.time(fromTime!)} - ${DateText.time(toTime!)}';
    }
    return dayType.tr;
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status']?.toString() ?? 'pending').toLowerCase();
    final LeaveStatus status;
    if (statusStr == 'approved') {
      status = LeaveStatus.approved;
    } else if (statusStr == 'rejected') {
      status = LeaveStatus.rejected;
    } else {
      status = LeaveStatus.pending;
    }

    final from = DateTime.tryParse(json['from_date']?.toString() ?? '') ?? DateTime.now();
    final to = DateTime.tryParse(json['to_date']?.toString() ?? '') ?? from;
    final attachUrl = json['attachment']?.toString() ?? json['attachment_url']?.toString();

    int sessionVal = 1;
    if (json['session'] != null) {
      sessionVal = int.tryParse(json['session'].toString()) ?? 1;
    } else {
      final leaveType = json['leave_type']?.toString().toLowerCase() ?? '';
      if (leaveType.contains('morning') || leaveType.contains('section_1')) {
        sessionVal = 1;
      } else if (leaveType.contains('afternoon') || leaveType.contains('section_2')) {
        sessionVal = 2;
      } else if (leaveType.contains('full')) {
        sessionVal = 0;
      }
    }

    final modeVal = json['leave_mode']?.toString() ?? 'full_section';
    final earlyTimeVal = json['early_leave_time']?.toString() ?? json['from_time']?.toString();

    return LeaveRequest(
      id: json['id']?.toString() ?? '',
      fullName: json['employee_name']?.toString() ?? '',
      employeeId: json['employee_id_code']?.toString() ?? json['employee_code']?.toString() ?? '',
      fromDate: from,
      toDate: to,
      session: sessionVal,
      leaveMode: modeVal,
      earlyLeaveTime: earlyTimeVal,
      dayType: json['day_type']?.toString() ?? json['leave_type']?.toString() ?? 'Section 1 (Morning)',
      reason: json['reason']?.toString() ?? '',
      status: status,
      reviewNotes: json['review_notes']?.toString(),
      reviewerName: json['reviewer_name']?.toString(),
      hasAttachment: attachUrl != null && attachUrl.isNotEmpty,
      attachmentPath: attachUrl,
    );
  }
}
