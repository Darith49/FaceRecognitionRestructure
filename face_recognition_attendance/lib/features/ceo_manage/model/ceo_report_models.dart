class BranchesSummaryResponse {
  final String periodLabel;
  final String startDate;
  final String endDate;
  final CompanySummary companySummary;
  final List<BranchCardSummary> branches;

  BranchesSummaryResponse({
    required this.periodLabel,
    required this.startDate,
    required this.endDate,
    required this.companySummary,
    required this.branches,
  });

  factory BranchesSummaryResponse.fromJson(Map<String, dynamic> json) {
    return BranchesSummaryResponse(
      periodLabel: json['period_label'] ?? '',
      startDate: json['start_date'] ?? json['from_date'] ?? '',
      endDate: json['end_date'] ?? json['to_date'] ?? '',
      companySummary: CompanySummary.fromJson(
        json['company_summary'] is Map<String, dynamic>
            ? json['company_summary']
            : {},
      ),
      branches: (json['branches'] as List<dynamic>? ?? [])
          .map((b) => BranchCardSummary.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'period_label': periodLabel,
        'start_date': startDate,
        'end_date': endDate,
        'company_summary': companySummary.toJson(),
        'branches': branches.map((b) => b.toJson()).toList(),
      };
}

class CompanySummary {
  final int totalBranches;
  final int totalEmployees;
  final double attendanceRate;
  final double onTimeRate;
  final int totalRequiredWorkdays;
  final int totalPresentDays;
  final int totalOnTimeAttendances;
  final int totalLeaves;
  final int totalAbsences;

  CompanySummary({
    required this.totalBranches,
    required this.totalEmployees,
    required this.attendanceRate,
    required this.onTimeRate,
    required this.totalRequiredWorkdays,
    required this.totalPresentDays,
    required this.totalOnTimeAttendances,
    required this.totalLeaves,
    required this.totalAbsences,
  });

  factory CompanySummary.fromJson(Map<String, dynamic> json) {
    return CompanySummary(
      totalBranches: json['total_branches'] ?? 0,
      totalEmployees: json['total_employees'] ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0.0,
      totalRequiredWorkdays: json['total_required_workdays'] ?? 0,
      totalPresentDays: json['total_present_days'] ?? 0,
      totalOnTimeAttendances: json['total_on_time_attendances'] ?? 0,
      totalLeaves: json['total_leaves'] ?? 0,
      totalAbsences: json['total_absences'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_branches': totalBranches,
        'total_employees': totalEmployees,
        'attendance_rate': attendanceRate,
        'on_time_rate': onTimeRate,
        'total_required_workdays': totalRequiredWorkdays,
        'total_present_days': totalPresentDays,
        'total_on_time_attendances': totalOnTimeAttendances,
        'total_leaves': totalLeaves,
        'total_absences': totalAbsences,
      };
}

class BranchCardSummary {
  final int id;
  final String name;
  final String managerName;
  final int employeeCount;
  final double attendanceRate;
  final double onTimeRate;
  final int totalRequiredWorkdays;
  final int totalPresentDays;
  final int totalLeaves;
  final int totalAbsences;

  BranchCardSummary({
    required this.id,
    required this.name,
    required this.managerName,
    required this.employeeCount,
    required this.attendanceRate,
    required this.onTimeRate,
    required this.totalRequiredWorkdays,
    required this.totalPresentDays,
    required this.totalLeaves,
    required this.totalAbsences,
  });

  factory BranchCardSummary.fromJson(Map<String, dynamic> json) {
    final summ = json['summary'] as Map<String, dynamic>? ?? {};
    return BranchCardSummary(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] ?? '',
      managerName: json['manager_name'] ?? 'No Manager Assigned',
      employeeCount: json['employee_count'] ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0.0,
      totalRequiredWorkdays: summ['total_required_workdays'] ?? json['total_required_workdays'] ?? 0,
      totalPresentDays: summ['total_present_days'] ?? json['total_present_days'] ?? 0,
      totalLeaves: summ['total_leaves'] ?? json['total_leaves'] ?? 0,
      totalAbsences: summ['total_absences'] ?? json['total_absences'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'manager_name': managerName,
        'employee_count': employeeCount,
        'attendance_rate': attendanceRate,
        'on_time_rate': onTimeRate,
        'total_required_workdays': totalRequiredWorkdays,
        'total_present_days': totalPresentDays,
        'total_leaves': totalLeaves,
        'total_absences': totalAbsences,
      };
}

class BranchDetailResponse {
  final int branchId;
  final String branchName;
  final String managerName;
  final int employeeCount;
  final String periodLabel;
  final String startDate;
  final String endDate;
  final double attendanceRate;
  final double onTimeRate;
  final List<EmployeeItemReport> employees;

  BranchDetailResponse({
    required this.branchId,
    required this.branchName,
    required this.managerName,
    required this.employeeCount,
    required this.periodLabel,
    required this.startDate,
    required this.endDate,
    required this.attendanceRate,
    required this.onTimeRate,
    required this.employees,
  });

  factory BranchDetailResponse.fromJson(Map<String, dynamic> json) {
    return BranchDetailResponse(
      branchId: json['branch_id'] is int
          ? json['branch_id']
          : (int.tryParse(json['branch_id']?.toString() ?? '0') ?? 0),
      branchName: json['branch_name'] ?? '',
      managerName: json['manager_name'] ?? 'No Manager Assigned',
      employeeCount: json['employee_count'] ?? 0,
      periodLabel: json['period_label'] ?? '',
      startDate: json['start_date'] ?? json['from_date'] ?? '',
      endDate: json['end_date'] ?? json['to_date'] ?? '',
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0.0,
      employees: (json['employees'] as List<dynamic>? ?? [])
          .map((e) => EmployeeItemReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'branch_id': branchId,
        'branch_name': branchName,
        'manager_name': managerName,
        'employee_count': employeeCount,
        'period_label': periodLabel,
        'start_date': startDate,
        'end_date': endDate,
        'attendance_rate': attendanceRate,
        'on_time_rate': onTimeRate,
        'employees': employees.map((e) => e.toJson()).toList(),
      };
}

class EmployeeItemReport {
  final int id;
  final String name;
  final String employeeId;
  final String role;
  final String department;
  final String? profileUrl;
  final double attendanceRate;
  final double onTimeRate;
  final EmployeeReportSummary summary;

  EmployeeItemReport({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.role,
    required this.department,
    this.profileUrl,
    required this.attendanceRate,
    required this.onTimeRate,
    required this.summary,
  });

  factory EmployeeItemReport.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] as Map<String, dynamic>? ?? {};
    return EmployeeItemReport(
      id: emp['id'] is int
          ? emp['id']
          : (int.tryParse(emp['id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0),
      name: emp['fullname'] ?? emp['name'] ?? json['name'] ?? '',
      employeeId: emp['employee_id']?.toString() ?? json['employee_id']?.toString() ?? '',
      role: emp['role'] ?? json['role'] ?? 'employee',
      department: emp['department_name'] ?? emp['department'] ?? json['department'] ?? 'General',
      profileUrl: emp['profile_picture'] ?? emp['profile_url'] ?? json['profile_url'],
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0.0,
      summary: EmployeeReportSummary.fromJson(json['summary'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'employee_id': employeeId,
        'role': role,
        'department': department,
        'profile_url': profileUrl,
        'attendance_rate': attendanceRate,
        'on_time_rate': onTimeRate,
        'summary': summary.toJson(),
      };
}

class EmployeeReportSummary {
  final int requiredWorkdays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int lateCount;
  final int totalLateMinutes;
  final int leftEarlyCount;
  final int totalEarlyMinutes;
  final int otCount;
  final int totalOtMinutes;
  final double workedDurationHours;

  EmployeeReportSummary({
    required this.requiredWorkdays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.lateCount,
    required this.totalLateMinutes,
    required this.leftEarlyCount,
    required this.totalEarlyMinutes,
    required this.otCount,
    required this.totalOtMinutes,
    required this.workedDurationHours,
  });

  factory EmployeeReportSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeReportSummary(
      requiredWorkdays: json['required_workdays'] ?? json['required_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      leaveDays: json['leave_days'] ?? json['on_leave_days'] ?? 0,
      lateCount: json['late_count'] ?? 0,
      totalLateMinutes: json['total_late_minutes'] ?? 0,
      leftEarlyCount: json['left_early_count'] ?? 0,
      totalEarlyMinutes: json['total_early_minutes'] ?? 0,
      otCount: json['ot_count'] ?? 0,
      totalOtMinutes: json['total_ot_minutes'] ?? 0,
      workedDurationHours: (json['worked_duration_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get totalOtFormatted {
    final h = totalOtMinutes ~/ 60;
    final m = totalOtMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Map<String, dynamic> toJson() => {
        'required_workdays': requiredWorkdays,
        'present_days': presentDays,
        'absent_days': absentDays,
        'leave_days': leaveDays,
        'late_count': lateCount,
        'total_late_minutes': totalLateMinutes,
        'left_early_count': leftEarlyCount,
        'total_early_minutes': totalEarlyMinutes,
        'ot_count': otCount,
        'total_ot_minutes': totalOtMinutes,
        'worked_duration_hours': workedDurationHours,
      };
}

class EmployeeDetailResponse {
  final int employeeId;
  final String name;
  final String role;
  final String? profileUrl;
  final String branchName;
  final String departmentName;
  final String periodLabel;
  final String startDate;
  final String endDate;
  final double attendanceRate;
  final double onTimeRate;
  final EmployeeReportSummary summary;
  final List<DailyRecordReport> dailyRecords;

  EmployeeDetailResponse({
    required this.employeeId,
    required this.name,
    required this.role,
    this.profileUrl,
    required this.branchName,
    required this.departmentName,
    required this.periodLabel,
    required this.startDate,
    required this.endDate,
    required this.attendanceRate,
    required this.onTimeRate,
    required this.summary,
    required this.dailyRecords,
  });

  factory EmployeeDetailResponse.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] as Map<String, dynamic>? ?? {};
    final br = json['branch'] as Map<String, dynamic>? ?? {};
    final dep = json['department'] as Map<String, dynamic>? ?? {};

    return EmployeeDetailResponse(
      employeeId: emp['id'] is int
          ? emp['id']
          : (int.tryParse(emp['id']?.toString() ?? json['employee_id']?.toString() ?? '0') ?? 0),
      name: emp['fullname'] ?? emp['name'] ?? json['name'] ?? '',
      role: emp['role'] ?? json['role'] ?? 'employee',
      profileUrl: emp['profile_picture'] ?? emp['profile_url'] ?? json['profile_url'],
      branchName: br['name'] ?? emp['branch_name'] ?? json['branch_name'] ?? 'Headquarters',
      departmentName: dep['name'] ?? emp['department_name'] ?? json['department_name'] ?? 'General',
      periodLabel: json['period_label'] ?? '',
      startDate: json['start_date'] ?? json['from_date'] ?? '',
      endDate: json['end_date'] ?? json['to_date'] ?? '',
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0.0,
      summary: EmployeeReportSummary.fromJson(json['summary'] ?? {}),
      dailyRecords: (json['daily_records'] as List<dynamic>? ?? [])
          .map((d) => DailyRecordReport.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'name': name,
        'role': role,
        'profile_url': profileUrl,
        'branch_name': branchName,
        'department_name': departmentName,
        'period_label': periodLabel,
        'start_date': startDate,
        'end_date': endDate,
        'attendance_rate': attendanceRate,
        'on_time_rate': onTimeRate,
        'summary': summary.toJson(),
        'daily_records': dailyRecords.map((d) => d.toJson()).toList(),
      };
}

class DailyRecordReport {
  final String date;
  final String dateDisplay;
  final String dayName;
  final String mainStatus;
  final List<String> conditions;
  final String matrixCode;
  final String? firstCheckIn;
  final String? lastCheckOut;
  final String timeFormatted;
  final int lateMinutes;
  final int earlyMinutes;
  final int otMinutes;
  final String otFormatted;
  final String conditionDetails;

  DailyRecordReport({
    required this.date,
    required this.dateDisplay,
    required this.dayName,
    required this.mainStatus,
    required this.conditions,
    required this.matrixCode,
    this.firstCheckIn,
    this.lastCheckOut,
    required this.timeFormatted,
    required this.lateMinutes,
    required this.earlyMinutes,
    required this.otMinutes,
    required this.otFormatted,
    required this.conditionDetails,
  });

  factory DailyRecordReport.fromJson(Map<String, dynamic> json) {
    return DailyRecordReport(
      date: json['date'] ?? '',
      dateDisplay: json['date_display'] ?? json['day_formatted'] ?? json['date'] ?? '',
      dayName: json['day_name'] ?? json['weekday'] ?? '',
      mainStatus: json['main_status'] ?? 'Scheduled',
      conditions: (json['conditions'] as List<dynamic>? ?? []).map((c) => c.toString()).toList(),
      matrixCode: json['matrix_code'] ?? '',
      firstCheckIn: json['first_check_in'] ?? json['check_in_time'],
      lastCheckOut: json['last_check_out'] ?? json['check_out_time'],
      timeFormatted: json['time_formatted'] ?? json['time_range'] ?? '',
      lateMinutes: json['late_minutes'] ?? 0,
      earlyMinutes: json['early_minutes'] ?? 0,
      otMinutes: json['ot_minutes'] ?? 0,
      otFormatted: json['ot_formatted'] ?? '',
      conditionDetails: json['condition_details'] ?? json['condition_detail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'date_display': dateDisplay,
        'day_name': dayName,
        'main_status': mainStatus,
        'conditions': conditions,
        'matrix_code': matrixCode,
        'first_check_in': firstCheckIn,
        'last_check_out': lastCheckOut,
        'time_formatted': timeFormatted,
        'late_minutes': lateMinutes,
        'early_minutes': earlyMinutes,
        'ot_minutes': otMinutes,
        'ot_formatted': otFormatted,
        'condition_details': conditionDetails,
      };
}
