import 'package:face_recognition_attendance/core/utils/date_text.dart';

/// Pending = shown in "Unauthorized", Approved = shown in "Authorized".
enum RequestStatus { pending, approved }

extension RequestStatusLabel on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
    }
  }
}

/// Schedules the user can choose in the "Request Permission" form.
/// TODO: load these from the Schedule feature when it is ready.
const List<String> kSessionSchedules = [
  '07:45-09:15',
  '09:30-11:00',
  '13:00-14:30',
  '14:45-16:15',
];

/// The schedule list, plus [current] when it is not in the list
/// (so a dropdown never gets a value that is missing from its items).
List<String> scheduleOptionsFor(String current) =>
    kSessionSchedules.contains(current)
        ? kSessionSchedules
        : [current, ...kSessionSchedules];

/// One session the user added to the "Request List" but has not submitted yet.
class PermissionSession {
  const PermissionSession({
    required this.date,
    required this.schedule,
    required this.reason,
  });

  final DateTime date;
  final String schedule;
  final String reason;

  /// Same day + same schedule = same session.
  bool isSameSlot(PermissionSession other) =>
      DateText.ymd(date) == DateText.ymd(other.date) &&
      schedule == other.schedule;
}

/// A permission request that was submitted.
class PermissionRequest {
  const PermissionRequest({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.date,
    required this.schedule,
    required this.reason,
    required this.status,
    this.type = 'Permission Request',
    this.authorizedAt,
  });

  final String id;
  final String type;
  final String fullName;
  final String employeeId;
  final DateTime date;
  final String schedule;
  final String reason;
  final RequestStatus status;

  /// When the request was approved (only for approved requests).
  final DateTime? authorizedAt;

  /// Example: 2026-09-07(07:45-09:15)
  String get timeLabel => '${DateText.ymd(date)}($schedule)';

  /// True when the request date is before today. Old requests cannot be changed.
  bool get hasPassed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).isBefore(today);
  }
}
