import 'dart:typed_data';
import 'package:face_recognition_attendance/core/utils/date_text.dart';

/// Pending = shown in "Pending", Approved = shown in "History".
enum LeaveStatus { pending, approved }

extension LeaveStatusLabel on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
    }
  }
}

/// Day-type chips shown on the "Request Leave" form.
/// 'Time' lets the user pick a custom from/to time instead of a full day.
const List<String> kLeaveDayTypes = ['Full Day', 'Morning', 'Afternoon', 'Time'];

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

  /// One of [kLeaveDayTypes].
  final String dayType;
  final String reason;
  final LeaveStatus status;

  /// Only set when [dayType] is 'Time'.
  final DateTime? fromTime;
  final DateTime? toTime;

  final bool hasAttachment;
  final String? attachmentName;
  final Uint8List? attachmentBytes;
  final int? attachmentSize;
  final String? attachmentPath;

  /// Inclusive number of calendar days covered by this request.
  int get dayCount => toDate.difference(fromDate).inDays + 1;

  /// Fri Sep 11 2026  or  Fri Sep 11 2026 → Mon Sep 14 2026
  String get dateRangeLabel {
    final from = DateText.monthShortDay(fromDate);
    final to = DateText.monthShortDay(toDate);
    return from == to ? from : '$from  →  $to';
  }

  /// "Full Day" / "Morning" / "Afternoon" / "05:00 PM - 06:00 PM"
  String get scheduleLabel {
    if (dayType == 'Time' && fromTime != null && toTime != null) {
      return '${DateText.time(fromTime!)} - ${DateText.time(toTime!)}';
    }
    return dayType;
  }
}
