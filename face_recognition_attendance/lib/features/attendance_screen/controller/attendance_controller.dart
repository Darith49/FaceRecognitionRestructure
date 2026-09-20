import 'package:face_recognition_attendance/features/attendance_screen/model/attendance_record.dart';
import 'package:get/get.dart';

/// TODO: set to false (and load the records from Firestore) when the backend is ready.
/// While it is true, example records are added so the page can be tested.
const bool _useSampleData = true;

class AttendanceController extends GetxController {
  final RxList<AttendanceRecord> records = <AttendanceRecord>[].obs;

  /// Selected filters.
  final RxString department = kDepartments.first.obs;

  /// 0 = all months, 1-12 = January-December.
  final RxInt month = 0.obs;

  /// 0 = all years, otherwise the chosen year.
  final RxInt year = 0.obs;

  /// Years in the Year dropdown: this year and the 3 years before it.
  final List<int> years = List<int>.generate(
    4,
    (index) => DateTime.now().year - index,
  );

  @override
  void onInit() {
    super.onInit();
    _loadSampleRecords();
  }

  /// How many sessions of [type] match the selected Department, Month and Year.
  int countOf(AttendanceType type) {
    final selectedDepartment = department.value;
    final selectedMonth = month.value;
    final selectedYear = year.value;

    return records
        .where(
          (record) =>
              record.type == type &&
              record.department == selectedDepartment &&
              (selectedMonth == 0 || record.date.month == selectedMonth) &&
              (selectedYear == 0 || record.date.year == selectedYear),
        )
        .length;
  }

  void _loadSampleRecords() {
    if (!_useSampleData) return;

    final engineering = kDepartments[0];
    final accounting = kDepartments[1];

    records.assignAll([
      AttendanceRecord(
        department: engineering,
        date: DateTime(2026, 9, 3),
        schedule: '07:45-09:15',
        type: AttendanceType.absent,
      ),
      AttendanceRecord(
        department: engineering,
        date: DateTime(2026, 9, 10),
        schedule: '09:30-11:00',
        type: AttendanceType.absent,
      ),
      AttendanceRecord(
        department: engineering,
        date: DateTime(2026, 9, 11),
        schedule: '13:00-14:30',
        type: AttendanceType.waive,
      ),
      AttendanceRecord(
        department: engineering,
        date: DateTime(2026, 9, 7),
        schedule: '07:45-09:15',
        type: AttendanceType.absentWithPermission,
      ),
      AttendanceRecord(
        department: engineering,
        date: DateTime(2026, 8, 20),
        schedule: '14:45-16:15',
        type: AttendanceType.absent,
      ),
      AttendanceRecord(
        department: engineering,
        date: DateTime(2026, 8, 25),
        schedule: '07:45-09:15',
        type: AttendanceType.absentWithPermission,
      ),
      AttendanceRecord(
        department: accounting,
        date: DateTime(2026, 9, 4),
        schedule: '09:30-11:00',
        type: AttendanceType.absent,
      ),
      AttendanceRecord(
        department: accounting,
        date: DateTime(2026, 9, 15),
        schedule: '13:00-14:30',
        type: AttendanceType.waive,
      ),
    ]);
  }
}
