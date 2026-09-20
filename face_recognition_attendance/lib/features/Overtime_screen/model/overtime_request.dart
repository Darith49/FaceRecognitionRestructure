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
}
