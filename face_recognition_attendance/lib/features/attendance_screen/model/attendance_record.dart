/// The three kinds of sessions shown on the Attendance page.
enum AttendanceType {
  /// A  - absent without permission
  absent,

  /// W  - waived
  waive,

  /// AP - absent with permission
  absentWithPermission,
}

/// One session that was counted for a department.
class AttendanceRecord {
  const AttendanceRecord({
    required this.department,
    required this.date,
    required this.schedule,
    required this.type,
  });

  final String department;
  final DateTime date;
  final String schedule;
  final AttendanceType type;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    AttendanceType type = AttendanceType.absent;
    final typeStr = (json['type'] ?? '').toString().toLowerCase();
    if (typeStr.contains('waive')) {
      type = AttendanceType.waive;
    } else if (typeStr.contains('permission') || typeStr == 'ap') {
      type = AttendanceType.absentWithPermission;
    }

    DateTime d = DateTime.now();
    if (json['date'] != null) {
      d = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    }

    return AttendanceRecord(
      department: json['department']?.toString() ?? '',
      date: d,
      schedule: json['schedule']?.toString() ?? '',
      type: type,
    );
  }
}

/// Departments in the Department dropdown.
/// TODO: load these from Firestore when the backend is ready.
const List<String> kDepartments = [
  'Computer Science and Engineering',
  'Accounting and Finance',
  'Business Administration',
];
