import 'dart:convert';
import 'dart:io' show File;
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/features/ceo_manage/model/ceo_report_models.dart';

class CeoReportService {
  final LocalDatabaseService _db = LocalDatabaseService();

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static String _monthName(int m) {
    if (m >= 1 && m <= 12) return _monthNames[m - 1];
    return 'Month $m';
  }

  /// Parses period string and custom year/month into start and end dates.
  static ({DateTime start, DateTime end, String label}) parsePeriod({
    String period = 'this_month',
    int? year,
    int? month,
  }) {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    switch (period.toLowerCase()) {
      case 'select_month':
        final start = DateTime(y, m, 1);
        final lastDay = DateTime(y, m + 1, 0).day;
        final end = DateTime(y, m, lastDay);
        return (start: start, end: end, label: '${_monthName(m)} $y');

      case 'last_3_months':
        final end = DateTime(now.year, now.month + 1, 0);
        final start = DateTime(now.year, now.month - 2, 1);
        return (start: start, end: end, label: 'Last 3 Months');

      case 'last_6_months':
        final end = DateTime(now.year, now.month + 1, 0);
        final start = DateTime(now.year, now.month - 5, 1);
        return (start: start, end: end, label: 'Last 6 Months');

      case 'this_year':
        final start = DateTime(y, 1, 1);
        final end = DateTime(y, 12, 31);
        return (start: start, end: end, label: 'Year $y');

      case 'this_month':
      default:
        final start = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final end = DateTime(now.year, now.month, lastDay);
        return (start: start, end: end, label: '${_monthName(now.month)} ${now.year}');
    }
  }

  /// Fetches branch summary cards and company-wide attendance telemetry
  Future<BranchesSummaryResponse> getBranchesSummary({
    required String period,
    int? year,
    int? month,
  }) async {
    await _db.init();
    final range = parsePeriod(period: period, year: year, month: month);

    final allBranches = _db.getBranches();
    final allEmployees = _db.getEmployees().where((e) {
      final role = (e['role'] ?? '').toString().toLowerCase();
      return role != 'ceo';
    }).toList();

    int compRequired = 0;
    int compPresent = 0;
    int compOnTime = 0;
    int compLeaves = 0;
    int compAbsences = 0;

    final branchCards = <BranchCardSummary>[];

    for (final b in allBranches) {
      final bId = b['id'] is int ? b['id'] : int.tryParse(b['id'].toString()) ?? 0;
      final bName = b['name']?.toString() ?? 'Branch $bId';

      final branchEmps = allEmployees.where((e) {
        final empBranch = e['branch'] != null ? int.tryParse(e['branch'].toString()) : null;
        return empBranch == bId;
      }).toList();

      final manager = branchEmps.firstWhere(
        (e) => (e['role'] ?? '').toString().toLowerCase() == 'manager',
        orElse: () => <String, dynamic>{},
      );
      final managerName = manager['fullname']?.toString() ?? 'No Manager Assigned';

      int branchRequired = 0;
      int branchPresent = 0;
      int branchOnTime = 0;
      int branchLeaves = 0;
      int branchAbsences = 0;

      for (final emp in branchEmps) {
        final empRep = _computeEmployeeReport(emp, range.start, range.end);
        branchRequired += empRep.summary.requiredWorkdays;
        branchPresent += empRep.summary.presentDays;
        branchOnTime += (empRep.summary.presentDays - empRep.summary.lateCount);
        branchLeaves += empRep.summary.leaveDays;
        branchAbsences += empRep.summary.absentDays;
      }

      final branchEligible = branchPresent + branchAbsences;
      final branchAttRate = branchEligible > 0
          ? ((branchPresent / branchEligible) * 100).clamp(0.0, 100.0)
          : 100.0;
      final branchOnTimeRate = branchPresent > 0
          ? ((branchOnTime.clamp(0, branchPresent) / branchPresent) * 100).clamp(0.0, 100.0)
          : 100.0;

      branchCards.add(BranchCardSummary(
        id: bId,
        name: bName,
        managerName: managerName,
        employeeCount: branchEmps.length,
        attendanceRate: branchAttRate,
        onTimeRate: branchOnTimeRate,
        totalRequiredWorkdays: branchRequired,
        totalPresentDays: branchPresent,
        totalLeaves: branchLeaves,
        totalAbsences: branchAbsences,
      ));

      compRequired += branchRequired;
      compPresent += branchPresent;
      compOnTime += branchOnTime;
      compLeaves += branchLeaves;
      compAbsences += branchAbsences;
    }

    final compEligible = compPresent + compAbsences;
    final compAttRate = compEligible > 0
        ? ((compPresent / compEligible) * 100).clamp(0.0, 100.0)
        : 100.0;
    final compOnTimeRate = compPresent > 0
        ? ((compOnTime.clamp(0, compPresent) / compPresent) * 100).clamp(0.0, 100.0)
        : 100.0;

    return BranchesSummaryResponse(
      periodLabel: range.label,
      startDate: range.start.toIso8601String().substring(0, 10),
      endDate: range.end.toIso8601String().substring(0, 10),
      companySummary: CompanySummary(
        totalBranches: allBranches.length,
        totalEmployees: allEmployees.length,
        attendanceRate: compAttRate,
        onTimeRate: compOnTimeRate,
        totalRequiredWorkdays: compRequired,
        totalPresentDays: compPresent,
        totalOnTimeAttendances: compOnTime,
        totalLeaves: compLeaves,
        totalAbsences: compAbsences,
      ),
      branches: branchCards,
    );
  }

  /// Fetches branch detail with employees ordered by role hierarchy:
  /// Manager first, then Leaders, then Employees.
  Future<BranchDetailResponse> getBranchDetail({
    required int branchId,
    required String period,
    int? year,
    int? month,
  }) async {
    await _db.init();
    final range = parsePeriod(period: period, year: year, month: month);

    final allBranches = _db.getBranches();
    final branch = allBranches.firstWhere(
      (b) => (b['id'] is int ? b['id'] : int.tryParse(b['id'].toString())) == branchId,
      orElse: () => {'id': branchId, 'name': 'Branch $branchId'},
    );
    final branchName = branch['name']?.toString() ?? 'Branch $branchId';

    final allEmployees = _db.getEmployees().where((e) {
      final role = (e['role'] ?? '').toString().toLowerCase();
      return role != 'ceo';
    }).toList();

    final branchEmps = allEmployees.where((e) {
      final bVal = e['branch'] != null ? int.tryParse(e['branch'].toString()) : null;
      return bVal == branchId;
    }).toList();

    final manager = branchEmps.firstWhere(
      (e) => (e['role'] ?? '').toString().toLowerCase() == 'manager',
      orElse: () => <String, dynamic>{},
    );
    final managerName = manager['fullname']?.toString() ?? 'No Manager Assigned';

    // Role priority sorting: manager = 0, leader = 1, employee = 2
    int rolePriority(String role) {
      switch (role.toLowerCase()) {
        case 'manager':
          return 0;
        case 'leader':
          return 1;
        default:
          return 2;
      }
    }

    branchEmps.sort((a, b) {
      final rA = rolePriority(a['role']?.toString() ?? '');
      final rB = rolePriority(b['role']?.toString() ?? '');
      if (rA != rB) return rA.compareTo(rB);
      final deptA = a['department_name']?.toString() ?? a['department']?.toString() ?? '';
      final deptB = b['department_name']?.toString() ?? b['department']?.toString() ?? '';
      final deptComp = deptA.toLowerCase().compareTo(deptB.toLowerCase());
      if (deptComp != 0) return deptComp;
      final nameA = a['fullname']?.toString() ?? '';
      final nameB = b['fullname']?.toString() ?? '';
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    int totPresent = 0;
    int totAbsent = 0;
    int totOnTime = 0;
    final empReports = <EmployeeItemReport>[];

    for (final emp in branchEmps) {
      final rep = _computeEmployeeReport(emp, range.start, range.end);
      totPresent += rep.summary.presentDays;
      totAbsent += rep.summary.absentDays;
      totOnTime += (rep.summary.presentDays - rep.summary.lateCount);
      empReports.add(rep);
    }

    final eligible = totPresent + totAbsent;
    final attRate = eligible > 0
        ? ((totPresent / eligible) * 100).clamp(0.0, 100.0)
        : 100.0;
    final onTimeRate = totPresent > 0
        ? ((totOnTime.clamp(0, totPresent) / totPresent) * 100).clamp(0.0, 100.0)
        : 100.0;

    return BranchDetailResponse(
      branchId: branchId,
      branchName: branchName,
      managerName: managerName,
      employeeCount: branchEmps.length,
      periodLabel: range.label,
      startDate: range.start.toIso8601String().substring(0, 10),
      endDate: range.end.toIso8601String().substring(0, 10),
      attendanceRate: attRate,
      onTimeRate: onTimeRate,
      employees: empReports,
    );
  }

  /// Fetches individual employee detailed attendance report and daily records
  Future<EmployeeDetailResponse> getEmployeeDetail({
    required int employeeId,
    required String period,
    int? year,
    int? month,
  }) async {
    await _db.init();
    final range = parsePeriod(period: period, year: year, month: month);

    final allEmployees = _db.getEmployees();
    final emp = allEmployees.firstWhere(
      (e) => (e['id'] is int ? e['id'] : int.tryParse(e['id'].toString())) == employeeId,
      orElse: () => {
        'id': employeeId,
        'fullname': 'Employee #$employeeId',
        'role': 'employee',
      },
    );

    return _computeEmployeeDetailResponse(emp, range.start, range.end, range.label);
  }

  /// Internal calculator for individual employee overview
  EmployeeItemReport _computeEmployeeReport(
    Map<String, dynamic> emp,
    DateTime startDate,
    DateTime endDate,
  ) {
    final detail = _computeEmployeeDetailResponse(emp, startDate, endDate, '');
    return EmployeeItemReport(
      id: detail.employeeId,
      name: detail.name,
      employeeId: emp['employee_id']?.toString() ?? detail.employeeId.toString(),
      role: detail.role,
      department: detail.departmentName,
      profileUrl: detail.profileUrl,
      attendanceRate: detail.attendanceRate,
      onTimeRate: detail.onTimeRate,
      summary: detail.summary,
    );
  }

  /// Calculates complete day-by-day attendance telemetry for an employee
  EmployeeDetailResponse _computeEmployeeDetailResponse(
    Map<String, dynamic> emp,
    DateTime startDate,
    DateTime endDate,
    String periodLabel,
  ) {
    final empId = emp['id'] is int ? emp['id'] : int.tryParse(emp['id'].toString()) ?? 0;
    final fullname = emp['fullname']?.toString() ?? 'Employee #$empId';
    final role = emp['role']?.toString() ?? 'employee';
    final profileUrl = emp['profile_picture']?.toString() ?? emp['profile_url']?.toString();
    final branchName = emp['branch_name']?.toString() ?? 'Headquarters';
    final deptName = emp['department_name']?.toString() ?? 'General';

    // Work schedule parsing
    final workDaysStr = (emp['work_days']?.toString() ?? 'mon,tue,wed,thu,fri').toLowerCase();
    final allowedWeekdays = workDaysStr.split(',').map((w) => w.trim()).toSet();
    const dayMap = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

    // Shift times (default 8:00 AM - 12:00 PM and 1:00 PM - 5:00 PM)
    final s1StartHour = _parseHour(emp['section1_start']?.toString() ?? '08:00:00', defaultHour: 8, defaultMin: 0);

    // Fetch existing attendance records
    final attRecords = _db.getAttendanceRecords(employeeId: empId);
    final attByDate = <String, List<Map<String, dynamic>>>{};
    for (final a in attRecords) {
      final d = a['date']?.toString() ?? '';
      if (d.isNotEmpty) {
        attByDate.putIfAbsent(d, () => []).add(a);
      }
    }

    // Fetch approved requests
    final leaves = _db.getLeaves(employeeId: empId).where((l) => (l['status']?.toString().toLowerCase() ?? '') == 'approved').toList();
    final perms = _db.getPermissions(employeeId: empId).where((p) => (p['status']?.toString().toLowerCase() ?? '') == 'approved').toList();
    final ots = _db.getOvertimes(employeeId: empId).where((o) => (o['status']?.toString().toLowerCase() ?? '') == 'approved').toList();

    int requiredWorkdays = 0;
    int presentDays = 0;
    int absentDays = 0;
    int leaveDays = 0;
    int lateCount = 0;
    int totalLateMinutes = 0;
    int leftEarlyCount = 0;
    int totalEarlyMinutes = 0;
    int otCount = 0;
    int totalOtMinutes = 0;
    double workedHours = 0.0;

    final dailyRecords = <DailyRecordReport>[];
    final today = DateTime.now();
    final todayClean = DateTime(today.year, today.month, today.day);

    var cur = DateTime(startDate.year, startDate.month, startDate.day);
    final endLimit = DateTime(endDate.year, endDate.month, endDate.day);

    while (!cur.isAfter(endLimit)) {
      final dateStr = '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
      final dayCode = dayMap[cur.weekday - 1];
      final isWorkday = allowedWeekdays.contains(dayCode);

      final dayAtts = attByDate[dateStr] ?? [];

      // Check leaves
      bool hasLeave = leaves.any((l) {
        final from = l['from_date']?.toString() ?? '';
        final to = l['to_date']?.toString() ?? from;
        return dateStr.compareTo(from) >= 0 && dateStr.compareTo(to) <= 0;
      }) || perms.any((p) => p['date']?.toString() == dateStr);

      // Check OT
      int dayOtMins = 0;
      for (final ot in ots) {
        if (ot['date']?.toString() == dateStr) {
          final mins = ot['duration_minutes'] != null
              ? int.tryParse(ot['duration_minutes'].toString()) ?? 120
              : 120;
          dayOtMins += mins;
        }
      }
      if (dayOtMins > 0) {
        otCount++;
        totalOtMinutes += dayOtMins;
      }

      bool isPresent = dayAtts.isNotEmpty;
      int dayLateMins = 0;
      int dayEarlyMins = 0;
      String? firstIn;
      String? lastOut;

      if (isPresent) {
        presentDays++;
        final first = dayAtts.first;
        final inTimeStr = first['check_in_time']?.toString();
        if (inTimeStr != null && inTimeStr.isNotEmpty) {
          try {
            final parsedIn = DateTime.parse(inTimeStr);
            firstIn = _formatTime(parsedIn);
            final checkInTotalMin = parsedIn.hour * 60 + parsedIn.minute;
            final targetStartMin = s1StartHour.hour * 60 + s1StartHour.minute;
            if (checkInTotalMin > targetStartMin) {
              dayLateMins = checkInTotalMin - targetStartMin;
              lateCount++;
              totalLateMinutes += dayLateMins;
            }
          } catch (_) {
            firstIn = inTimeStr;
          }
        }

        final last = dayAtts.last;
        final outTimeStr = last['check_out_time']?.toString();
        if (outTimeStr != null && outTimeStr.isNotEmpty) {
          try {
            final parsedOut = DateTime.parse(outTimeStr);
            lastOut = _formatTime(parsedOut);
          } catch (_) {
            lastOut = outTimeStr;
          }
        }
        workedHours += 8.0;
      }

      // Status determination
      String mainStatus;
      final conditions = <String>[];
      final condDetails = <String>[];

      if (isPresent) {
        mainStatus = 'Present';
        if (dayLateMins > 0) {
          conditions.add('Late');
          condDetails.add('Late $dayLateMins min');
        }
        if (dayEarlyMins > 0) {
          conditions.add('Left Early');
          condDetails.add('Left Early $dayEarlyMins min');
        }
        if (dayOtMins > 0) {
          conditions.add('OT');
          final h = dayOtMins ~/ 60;
          final m = dayOtMins % 60;
          condDetails.add('OT ${h > 0 ? '${h}h ' : ''}${m}m');
        }
      } else if (!isWorkday) {
        mainStatus = 'Day Off';
      } else if (hasLeave) {
        mainStatus = 'On Leave';
        leaveDays++;
      } else if (cur.isBefore(todayClean)) {
        mainStatus = 'Absent';
        absentDays++;
      } else {
        mainStatus = 'Scheduled';
      }

      if (isWorkday) {
        requiredWorkdays++;
      }

      String matrixCode = '-';
      if (mainStatus == 'Present') {
        matrixCode = 'P';
        if (dayLateMins > 0) matrixCode += '/L';
        if (dayEarlyMins > 0) matrixCode += '/LE';
        if (dayOtMins > 0) matrixCode += '/OT';
      } else if (mainStatus == 'Absent') {
        matrixCode = 'A';
      } else if (mainStatus == 'On Leave') {
        matrixCode = 'OL';
      } else if (mainStatus == 'Day Off') {
        matrixCode = 'DO';
      }

      final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = weekdayNames[cur.weekday - 1];
      final dateDisplay = '${cur.day} ${_monthNames[cur.month - 1].substring(0, 3)}';

      String timeFormatted = '';
      if (firstIn != null && lastOut != null) {
        timeFormatted = '$firstIn → $lastOut';
      } else if (firstIn != null) {
        timeFormatted = 'In: $firstIn';
      }

      String otFormatted = '';
      if (dayOtMins > 0) {
        final h = dayOtMins ~/ 60;
        final m = dayOtMins % 60;
        otFormatted = '${h > 0 ? '${h}h ' : ''}${m}m';
      }

      dailyRecords.add(DailyRecordReport(
        date: dateStr,
        dateDisplay: dateDisplay,
        dayName: dayName,
        mainStatus: mainStatus,
        conditions: conditions,
        matrixCode: matrixCode,
        firstCheckIn: firstIn,
        lastCheckOut: lastOut,
        timeFormatted: timeFormatted,
        lateMinutes: dayLateMins,
        earlyMinutes: dayEarlyMins,
        otMinutes: dayOtMins,
        otFormatted: otFormatted,
        conditionDetails: condDetails.join(', '),
      ));

      cur = cur.add(const Duration(days: 1));
    }

    final eligible = presentDays + absentDays;
    final attRate = eligible > 0
        ? ((presentDays / eligible) * 100).clamp(0.0, 100.0)
        : 100.0;
    final onTimeDays = (presentDays - lateCount).clamp(0, presentDays);
    final onTimeRate = presentDays > 0
        ? ((onTimeDays / presentDays) * 100).clamp(0.0, 100.0)
        : 100.0;

    return EmployeeDetailResponse(
      employeeId: empId,
      name: fullname,
      role: role,
      profileUrl: profileUrl,
      branchName: branchName,
      departmentName: deptName,
      periodLabel: periodLabel,
      startDate: startDate.toIso8601String().substring(0, 10),
      endDate: endDate.toIso8601String().substring(0, 10),
      attendanceRate: attRate,
      onTimeRate: onTimeRate,
      summary: EmployeeReportSummary(
        requiredWorkdays: requiredWorkdays,
        presentDays: presentDays,
        absentDays: absentDays,
        leaveDays: leaveDays,
        lateCount: lateCount,
        totalLateMinutes: totalLateMinutes,
        leftEarlyCount: leftEarlyCount,
        totalEarlyMinutes: totalEarlyMinutes,
        otCount: otCount,
        totalOtMinutes: totalOtMinutes,
        workedDurationHours: workedHours,
      ),
      dailyRecords: dailyRecords,
    );
  }

  static ({int hour, int minute}) _parseHour(String timeStr, {required int defaultHour, required int defaultMin}) {
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? int.parse(parts[1]) : 0;
      return (hour: h, minute: m);
    } catch (_) {
      return (hour: defaultHour, minute: defaultMin);
    }
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  // =========================================================================
  // EXPORT & SHARE ENGINE (CSV / Excel format)
  // =========================================================================

  /// Generates CSV spreadsheet bytes for either all branches or a single branch.
  Future<List<int>> exportExcelBytes({
    required String scope,
    int? branchId,
    required String period,
    int? year,
    int? month,
  }) async {
    final buffer = StringBuffer();
    final range = parsePeriod(period: period, year: year, month: month);

    // CSV Header with metadata
    buffer.writeln('FACE RECOGNITION ATTENDANCE REPORT');
    buffer.writeln('Scope,${scope == 'all' ? 'All Branches' : 'Branch ID $branchId'}');
    buffer.writeln('Period,${range.label} (${range.start.toIso8601String().substring(0, 10)} to ${range.end.toIso8601String().substring(0, 10)})');
    buffer.writeln('Generated,${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // Columns
    buffer.writeln(
      'Branch,Department,Employee ID,Full Name,Role,Attendance Rate (%),On-Time Rate (%),Present (Days),Absent (Days),Leaves (Days),Lates (Count),Late Minutes,Left Early (Count),OT (Count),OT Hours',
    );

    if (scope == 'all') {
      final allBranches = _db.getBranches();
      for (final b in allBranches) {
        final bId = b['id'] is int ? b['id'] : int.tryParse(b['id'].toString()) ?? 0;
        final detail = await getBranchDetail(branchId: bId, period: period, year: year, month: month);
        for (final emp in detail.employees) {
          buffer.writeln(
            '"${_escapeCsv(detail.branchName)}",'
            '"${_escapeCsv(emp.department)}",'
            '"${_escapeCsv(emp.employeeId)}",'
            '"${_escapeCsv(emp.name)}",'
            '"${_escapeCsv(emp.role.toUpperCase())}",'
            '${emp.attendanceRate.toStringAsFixed(1)},'
            '${emp.onTimeRate.toStringAsFixed(1)},'
            '${emp.summary.presentDays},'
            '${emp.summary.absentDays},'
            '${emp.summary.leaveDays},'
            '${emp.summary.lateCount},'
            '${emp.summary.totalLateMinutes},'
            '${emp.summary.leftEarlyCount},'
            '${emp.summary.otCount},'
            '"${emp.summary.totalOtFormatted}"',
          );
        }
      }
    } else if (branchId != null) {
      final detail = await getBranchDetail(branchId: branchId, period: period, year: year, month: month);
      for (final emp in detail.employees) {
        buffer.writeln(
          '"${_escapeCsv(detail.branchName)}",'
          '"${_escapeCsv(emp.department)}",'
          '"${_escapeCsv(emp.employeeId)}",'
          '"${_escapeCsv(emp.name)}",'
          '"${_escapeCsv(emp.role.toUpperCase())}",'
          '${emp.attendanceRate.toStringAsFixed(1)},'
          '${emp.onTimeRate.toStringAsFixed(1)},'
          '${emp.summary.presentDays},'
          '${emp.summary.absentDays},'
          '${emp.summary.leaveDays},'
          '${emp.summary.lateCount},'
          '${emp.summary.totalLateMinutes},'
          '${emp.summary.leftEarlyCount},'
          '${emp.summary.otCount},'
          '"${emp.summary.totalOtFormatted}"',
        );
      }
    }

    // UTF-8 with BOM for Excel compatibility
    final utf8Bytes = utf8.encode(buffer.toString());
    final bom = [0xEF, 0xBB, 0xBF];
    return [...bom, ...utf8Bytes];
  }

  static String _escapeCsv(String val) {
    return val.replaceAll('"', '""');
  }

  /// Downloads report and opens/saves it on the device
  Future<String> downloadAndOpenFile({
    required String scope,
    int? branchId,
    required String period,
    int? year,
    int? month,
    required String defaultFilename,
  }) async {
    final bytes = await exportExcelBytes(
      scope: scope,
      branchId: branchId,
      period: period,
      year: year,
      month: month,
    );

    final cleanName = defaultFilename.replaceAll(RegExp(r'[\\/*?:"<>| ]'), '_');

    if (kIsWeb) {
      // Browser download on Flutter Web (Edge, Chrome, Safari)
      try {
        final uint8 = Uint8List.fromList(bytes);
        final blob = web.Blob([uint8.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8;'));
        final url = web.URL.createObjectURL(blob);
        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = cleanName;
        anchor.click();
        web.URL.revokeObjectURL(url);
        return cleanName;
      } catch (e) {
        debugPrint('[CeoReportService] Web download error: $e');
      }
    }

    // Native Desktop / Mobile fallback
    try {
      final file = File(cleanName);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      // If direct file writing is restricted, use Printing share
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: cleanName);
      return cleanName;
    }
  }

  /// Shares report via share sheet or native print/share handler
  Future<void> shareExcelFile({
    required String scope,
    int? branchId,
    required String period,
    int? year,
    int? month,
    required String defaultFilename,
  }) async {
    final bytes = await exportExcelBytes(
      scope: scope,
      branchId: branchId,
      period: period,
      year: year,
      month: month,
    );

    final cleanName = defaultFilename.replaceAll(RegExp(r'[\\/*?:"<>| ]'), '_');

    if (kIsWeb) {
      await downloadAndOpenFile(
        scope: scope,
        branchId: branchId,
        period: period,
        year: year,
        month: month,
        defaultFilename: cleanName,
      );
      return;
    }

    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: cleanName,
    );
  }
}
