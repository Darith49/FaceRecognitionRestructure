import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:get/get.dart';

/// Pending = awaiting review, Approved = shown in "Authorized", Rejected = shown in "Unauthorized".
enum RequestStatus { pending, approved, rejected }

extension RequestStatusLabel on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending'.tr;
      case RequestStatus.approved:
        return 'Approved'.tr;
      case RequestStatus.rejected:
        return 'Rejected'.tr;
    }
  }

  String get displayName => label;
}

/// Schedules the user can choose in the "Request Permission" form.
const List<String> kSessionSchedules = ['Section 1', 'Section 2'];

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
    this.employeeUid,
    this.employeeEmail,
    this.employeeRole,
    this.employeeBranch,
    this.employeeDepartment,
    this.reviewNotes,
    this.reviewerName,
    this.createdAt,
  });

  final String id;
  final String type;
  final String fullName;
  final String employeeId;
  final String? employeeUid;
  final String? employeeEmail;
  final String? employeeRole;
  final String? employeeBranch;
  final String? employeeDepartment;
  final DateTime date;
  final String schedule;
  final String reason;
  final RequestStatus status;
  final String? reviewNotes;
  final String? reviewerName;
  final DateTime? createdAt;

  /// When the request was approved (only for approved requests).
  final DateTime? authorizedAt;

  /// Example: 2026-09-07(Section 1)
  String get timeLabel => '${DateText.ymd(date)}($schedule)';

  /// True when the request date is before today. Old requests cannot be changed.
  bool get hasPassed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(date.year, date.month, date.day).isBefore(today);
  }

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toLowerCase() ?? 'pending';
    final status = statusStr == 'approved'
        ? RequestStatus.approved
        : (statusStr == 'rejected'
            ? RequestStatus.rejected
            : RequestStatus.pending);
    final parsedDate =
        DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();
    final authAt = json['reviewed_at'] != null
        ? DateTime.tryParse(json['reviewed_at'].toString())
        : null;

    return PermissionRequest(
      id: json['id']?.toString() ?? '',
      fullName: json['employee_name']?.toString() ?? '',
      employeeId: json['employee_id_code']?.toString() ??
          json['employee_code']?.toString() ??
          json['employee_id']?.toString() ??
          '',
      employeeUid: json['employee_uid']?.toString(),
      employeeEmail: json['employee_email']?.toString(),
      employeeRole: json['employee_role']?.toString(),
      employeeBranch: json['employee_branch']?.toString(),
      employeeDepartment: json['employee_department']?.toString(),
      date: parsedDate,
      schedule: json['schedule_time']?.toString() ??
          json['schedule']?.toString() ??
          'Section ${json['session'] ?? 1}',
      reason: json['reason']?.toString() ?? '',
      status: status,
      authorizedAt: authAt,
      reviewNotes: json['review_notes']?.toString(),
      reviewerName: json['reviewer_name']?.toString(),
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
      'schedule_time': schedule,
      'reason': reason,
      'status': status.name,
      'reviewed_at': authorizedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'reviewer_name': reviewerName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
