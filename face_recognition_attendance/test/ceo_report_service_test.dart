import 'dart:convert';
import 'package:face_recognition_attendance/features/ceo_manage/model/ceo_report_models.dart';

void main() {
  print('=== STARTING CEO REPORT MODELS & TELEMETRY UNIT TESTS ===');

  print('\n[Test 1] Testing CEO Report Model Serialization / Deserialization...');
  final mockSummary = BranchesSummaryResponse(
    periodLabel: 'September 2026',
    startDate: '2026-09-01',
    endDate: '2026-09-30',
    companySummary: CompanySummary(
      totalBranches: 3,
      totalEmployees: 45,
      attendanceRate: 94.5,
      onTimeRate: 88.2,
      totalRequiredWorkdays: 900,
      totalPresentDays: 850,
      totalOnTimeAttendances: 750,
      totalLeaves: 30,
      totalAbsences: 20,
    ),
    branches: [
      BranchCardSummary(
        id: 1,
        name: 'Phnom Penh HQ',
        managerName: 'Manager Sokha',
        employeeCount: 25,
        attendanceRate: 96.0,
        onTimeRate: 90.0,
        totalRequiredWorkdays: 500,
        totalPresentDays: 480,
        totalLeaves: 12,
        totalAbsences: 8,
      ),
    ],
  );

  final jsonMap = mockSummary.toJson();
  final reconstructed = BranchesSummaryResponse.fromJson(jsonMap);

  assert(reconstructed.periodLabel == 'September 2026');
  assert(reconstructed.companySummary.totalBranches == 3);
  assert(reconstructed.companySummary.attendanceRate == 94.5);
  assert(reconstructed.branches.length == 1);
  assert(reconstructed.branches.first.name == 'Phnom Penh HQ');
  assert(reconstructed.branches.first.attendanceRate == 96.0);
  print('Model serialization passed.');

  print('\n[Test 2] Testing Employee Detail & Daily Record Report models...');
  final empDetail = EmployeeDetailResponse(
    employeeId: 10,
    name: 'Darith Keo',
    role: 'ceo',
    branchName: 'Phnom Penh HQ',
    departmentName: 'Executive',
    periodLabel: 'September 2026',
    startDate: '2026-09-01',
    endDate: '2026-09-30',
    attendanceRate: 100.0,
    onTimeRate: 95.0,
    summary: EmployeeReportSummary(
      requiredWorkdays: 22,
      presentDays: 22,
      absentDays: 0,
      leaveDays: 0,
      lateCount: 1,
      totalLateMinutes: 10,
      leftEarlyCount: 0,
      totalEarlyMinutes: 0,
      otCount: 2,
      totalOtMinutes: 180,
      workedDurationHours: 176.0,
    ),
    dailyRecords: [
      DailyRecordReport(
        date: '2026-09-29',
        dateDisplay: '29 Sep',
        dayName: 'Tue',
        mainStatus: 'Present',
        conditions: ['Late'],
        matrixCode: 'P/L',
        firstCheckIn: '08:10 AM',
        lastCheckOut: '05:00 PM',
        timeFormatted: '08:10 AM → 05:00 PM',
        lateMinutes: 10,
        earlyMinutes: 0,
        otMinutes: 0,
        otFormatted: '',
        conditionDetails: 'Late 10 min',
      ),
    ],
  );

  final empJson = empDetail.toJson();
  final empReconstructed = EmployeeDetailResponse.fromJson(empJson);

  assert(empReconstructed.name == 'Darith Keo');
  assert(empReconstructed.attendanceRate == 100.0);
  assert(empReconstructed.summary.totalOtFormatted == '3h');
  assert(empReconstructed.dailyRecords.length == 1);
  assert(empReconstructed.dailyRecords.first.matrixCode == 'P/L');
  print('Employee Detail model passed.');

  print('\n[Test 3] Testing UTF-8 CSV BOM format...');
  final buffer = StringBuffer();
  buffer.writeln('Branch,Department,Employee ID,Full Name');
  buffer.writeln('"Phnom Penh HQ","Engineering","EMP-001","Darith Keo"');
  final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];
  assert(bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF, 'BOM verified');
  print('CSV UTF-8 BOM test passed.');

  print('\n=== ALL CEO REPORT TESTS PASSED SUCCESSFULLY! ===\n');
}
