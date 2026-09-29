import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:face_recognition_attendance/features/ceo_manage/model/ceo_report_models.dart';
import 'package:face_recognition_attendance/features/ceo_manage/service/ceo_report_service.dart';
import 'package:face_recognition_attendance/features/ceo_manage/view/widgets/month_year_picker_sheet.dart';

class CeoManageController extends GetxController {
  final CeoReportService _service = CeoReportService();

  final RxBool isLoading = false.obs;
  final RxBool isExporting = false.obs;

  // Period Selection
  final RxString selectedPeriod = 'this_month'.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final RxInt selectedMonth = DateTime.now().month.obs;

  // Data
  final Rxn<BranchesSummaryResponse> branchesSummary = Rxn<BranchesSummaryResponse>();

  // Branch Detail
  final RxBool isBranchDetailLoading = false.obs;
  final Rxn<BranchDetailResponse> branchDetail = Rxn<BranchDetailResponse>();

  // Employee Detail
  final RxBool isEmployeeDetailLoading = false.obs;
  final Rxn<EmployeeDetailResponse> employeeDetail = Rxn<EmployeeDetailResponse>();

  @override
  void onInit() {
    super.onInit();
    fetchBranchesSummary();
  }

  String get periodDisplayLabel {
    switch (selectedPeriod.value) {
      case 'this_month':
        return 'This Month';
      case 'select_month':
        return _formatMonthName(selectedMonth.value, selectedYear.value);
      case 'last_3_months':
        return 'Last 3 Months';
      case 'last_6_months':
        return 'Last 6 Months';
      case 'this_year':
        return 'This Year (${selectedYear.value})';
      default:
        return 'This Month';
    }
  }

  String _formatMonthName(int month, int year) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final mName = (month >= 1 && month <= 12) ? months[month - 1] : 'Month $month';
    return '$mName $year';
  }

  Future<void> setPeriod(String period, BuildContext context) async {
    if (period == 'select_month') {
      final res = await MonthYearPickerSheet.show(
        context: context,
        initialYear: selectedYear.value,
        initialMonth: selectedMonth.value,
      );
      if (res != null) {
        selectedYear.value = res['year']!;
        selectedMonth.value = res['month']!;
        selectedPeriod.value = 'select_month';
        await fetchBranchesSummary();
      }
    } else {
      selectedPeriod.value = period;
      await fetchBranchesSummary();
    }
  }

  Future<void> fetchBranchesSummary() async {
    try {
      isLoading.value = true;
      final res = await _service.getBranchesSummary(
        period: selectedPeriod.value,
        year: selectedYear.value,
        month: selectedMonth.value,
      );
      branchesSummary.value = res;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load branch reports: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBranchDetail(int branchId) async {
    try {
      isBranchDetailLoading.value = true;
      final res = await _service.getBranchDetail(
        branchId: branchId,
        period: selectedPeriod.value,
        year: selectedYear.value,
        month: selectedMonth.value,
      );
      branchDetail.value = res;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load branch detail: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isBranchDetailLoading.value = false;
    }
  }

  Future<void> fetchEmployeeDetail(int employeeId) async {
    try {
      isEmployeeDetailLoading.value = true;
      final res = await _service.getEmployeeDetail(
        employeeId: employeeId,
        period: selectedPeriod.value,
        year: selectedYear.value,
        month: selectedMonth.value,
      );
      employeeDetail.value = res;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load employee attendance: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isEmployeeDetailLoading.value = false;
    }
  }

  // Export All Branches to Excel & Open
  Future<void> exportAllBranches() async {
    try {
      isExporting.value = true;
      Get.showSnackbar(
        const GetSnackBar(
          message: 'Generating Excel report for all branches...',
          duration: Duration(seconds: 2),
        ),
      );

      final periodTag = selectedPeriod.value == 'select_month'
          ? '${selectedYear.value}_${selectedMonth.value}'
          : selectedPeriod.value;
      final filename = 'Attendance_Report_All_Branches_$periodTag.csv';

      await _service.downloadAndOpenFile(
        scope: 'all',
        period: selectedPeriod.value,
        year: selectedYear.value,
        month: selectedMonth.value,
        defaultFilename: filename,
      );
    } catch (e) {
      Get.snackbar(
        'Export Failed',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // Share All Branches Excel
  Future<void> shareAllBranches() async {
    try {
      isExporting.value = true;
      final periodTag = selectedPeriod.value == 'select_month'
          ? '${selectedYear.value}_${selectedMonth.value}'
          : selectedPeriod.value;
      final filename = 'Attendance_Report_All_Branches_$periodTag.csv';

      await _service.shareExcelFile(
        scope: 'all',
        period: selectedPeriod.value,
        year: selectedYear.value,
        month: selectedMonth.value,
        defaultFilename: filename,
      );
    } catch (e) {
      Get.snackbar(
        'Share Failed',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // Export Single Branch
  Future<void> exportBranch(int branchId, String branchName) async {
    try {
      isExporting.value = true;
      final periodTag = selectedPeriod.value == 'select_month'
          ? '${selectedYear.value}_${selectedMonth.value}'
          : selectedPeriod.value;
      final filename = 'Attendance_Report_${branchName}_$periodTag.csv';

      await _service.downloadAndOpenFile(
        scope: 'branch',
        branchId: branchId,
        period: selectedPeriod.value,
        year: selectedYear.value,
        month: selectedMonth.value,
        defaultFilename: filename,
      );
    } catch (e) {
      Get.snackbar(
        'Export Failed',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  // Share Single Branch
  Future<void> shareBranch(int branchId, String branchName) async {
    try {
      isExporting.value = true;
      final periodTag = selectedPeriod.value == 'select_month'
          ? '${selectedYear.value}_${selectedMonth.value}'
          : selectedPeriod.value;
      final filename = 'Attendance_Report_${branchName}_$periodTag.csv';

      await _service.shareExcelFile(
        scope: 'branch',
        branchId: branchId,
        period: selectedPeriod.value,
        year: selectedYear.value,
        month: selectedMonth.value,
        defaultFilename: filename,
      );
    } catch (e) {
      Get.snackbar(
        'Share Failed',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }
}
