import 'package:face_recognition_attendance/core/utils/date_text.dart';

/// Pending = the employee submitted it, no manager/leader/CEO has reviewed it yet.
/// Seen = a manager/leader/CEO reviewed it. Seen suggestions can no longer be edited.
enum SuggestionStatus { pending, seen }

extension SuggestionStatusLabel on SuggestionStatus {
  String get label {
    switch (this) {
      case SuggestionStatus.pending:
        return 'Pending';
      case SuggestionStatus.seen:
        return 'Seen';
    }
  }
}

/// One suggestion submitted by an employee.
class Suggestion {
  const Suggestion({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.message,
    required this.submittedAt,
    required this.status,
  });

  final String id;
  final String fullName;
  final String employeeId;
  final String message;
  final DateTime submittedAt;
  final SuggestionStatus status;

  bool get isPending => status == SuggestionStatus.pending;
  bool get isSeen => status == SuggestionStatus.seen;

  Suggestion copyWith({String? message, SuggestionStatus? status}) {
    return Suggestion(
      id: id,
      fullName: fullName,
      employeeId: employeeId,
      message: message ?? this.message,
      submittedAt: submittedAt,
      status: status ?? this.status,
    );
  }

  /// Monday 2026-09-07
  String get dateLabel => DateText.weekdayYmd(submittedAt);

  /// 07:45 AM
  String get timeLabel => DateText.time(submittedAt);
}
