import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/features/attendance_screen/model/attendance_record.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AttendanceController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxList<AttendanceRecord> records = <AttendanceRecord>[].obs;
  final RxList<String> departments = <String>[].obs;

  /// Selected filters.
  final RxString department = ''.obs;

  /// 0 = all months, 1-12 = January-December.
  final RxInt month = 0.obs;

  /// 0 = all years, otherwise the chosen year.
  final RxInt year = 0.obs;

  final RxInt absentCount = 0.obs;
  final RxInt waiveCount = 0.obs;
  final RxInt permissionCount = 0.obs;

  final RxBool isLoading = false.obs;

  /// Years in the Year dropdown: this year and the 3 years before it.
  final List<int> years = List<int>.generate(
    4,
    (index) => DateTime.now().year - index,
  );

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    month.value = now.month;
    year.value = now.year;
    fetchDepartmentSummary();
  }

  Future<void> fetchDepartmentSummary() async {
    try {
      isLoading.value = true;
      final queryParams = <String, dynamic>{};
      if (department.value.isNotEmpty) {
        queryParams['department'] = department.value;
      }
      if (month.value > 0) {
        queryParams['month'] = month.value;
      }
      if (year.value > 0) {
        queryParams['year'] = year.value;
      }

      final res = await _apiService.get('/attendance/department-summary/', queryParams: queryParams);
      if (res is Map<String, dynamic>) {
        if (res['departments'] is List) {
          final list = (res['departments'] as List).map((e) => e.toString()).toList();
          departments.assignAll(list);
        }

        if (department.value.isEmpty) {
          final userDept = res['user_department']?.toString();
          if (userDept != null && userDept.isNotEmpty && departments.contains(userDept)) {
            department.value = userDept;
          } else if (departments.isNotEmpty) {
            department.value = departments.first;
          }
        }

        absentCount.value = res['absent_count'] as int? ?? 0;
        waiveCount.value = res['waive_count'] as int? ?? 0;
        permissionCount.value = res['permission_count'] as int? ?? 0;

        if (res['records'] is List) {
          final recs = (res['records'] as List)
              .map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          records.assignAll(recs);
        }
      }
    } catch (e) {
      debugPrint('Error fetching department summary: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// How many sessions of [type] match the selected Department, Month and Year.
  int countOf(AttendanceType type) {
    switch (type) {
      case AttendanceType.absent:
        return absentCount.value;
      case AttendanceType.waive:
        return waiveCount.value;
      case AttendanceType.absentWithPermission:
        return permissionCount.value;
    }
  }
}

