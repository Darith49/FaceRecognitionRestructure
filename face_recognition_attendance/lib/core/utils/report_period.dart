import 'package:face_recognition_attendance/core/utils/date_text.dart';

/// A date range chosen in the "Download Report" dialog.
/// `start` and `end` are dates only (no time) and BOTH are included.
class ReportPeriod {
  const ReportPeriod({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;

  /// Shown on the report, e.g. "September 2026" or "2026-09-01 to 2026-09-20".
  final String label;

  /// 1st day .. last day of the month that contains [now].
  factory ReportPeriod.thisMonth([DateTime? now]) {
    final today = now ?? DateTime.now();
    return ReportPeriod._month(today.year, today.month);
  }

  /// 1st day .. last day of the month before [now].
  factory ReportPeriod.lastMonth([DateTime? now]) {
    final today = now ?? DateTime.now();
    // DateTime rolls month 0 back to December of the previous year.
    return ReportPeriod._month(today.year, today.month - 1);
  }

  factory ReportPeriod.custom(DateTime from, DateTime to) {
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    return ReportPeriod(
      start: start,
      end: end,
      label: '${DateText.ymd(start)} to ${DateText.ymd(end)}',
    );
  }

  factory ReportPeriod._month(int year, int month) {
    // Day 0 of the next month = the last day of this month.
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    return ReportPeriod(
      start: start,
      end: end,
      label: DateText.monthYear(start),
    );
  }

  bool contains(DateTime date) {
    final day = _dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// 2026-09-01_to_2026-09-30 (used in the PDF file name)
  String get fileSuffix => '${DateText.ymd(start)}_to_${DateText.ymd(end)}';

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
