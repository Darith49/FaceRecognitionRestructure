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
}

/// Departments in the Department dropdown.
/// TODO: load these from Firestore when the backend is ready.
const List<String> kDepartments = [
  'Computer Science and Engineering',
  'Accounting and Finance',
  'Business Administration',
];
