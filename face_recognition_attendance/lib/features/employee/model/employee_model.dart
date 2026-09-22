import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';

class EmployeeModel {
  final int id;
  final String firebaseUid;
  final String employeeId;
  final String fullname;
  final String email;
  final UserRole role;
  final int? branchId;
  final String branchName;
  final int? departmentId;
  final String departmentName;
  final String status;
  final String section1Start;
  final String section1End;
  final String section2Start;
  final String section2End;
  final String workDays;
  final String createdBy;
  final DateTime? createdAt;
  final String? profileUrl;

  EmployeeModel({
    required this.id,
    required this.firebaseUid,
    required this.employeeId,
    required this.fullname,
    required this.email,
    required this.role,
    this.branchId,
    this.branchName = '',
    this.departmentId,
    this.departmentName = '',
    this.status = 'pending',
    this.section1Start = '07:00:00',
    this.section1End = '11:00:00',
    this.section2Start = '13:00:00',
    this.section2End = '17:00:00',
    this.workDays = 'mon,tue,wed,thu,fri',
    this.createdBy = '',
    this.createdAt,
    this.profileUrl,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      firebaseUid: json['firebase_uid'] ?? '',
      employeeId: json['employee_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      role: stringToUserRole(json['role']),
      branchId: json['branch'] is int
          ? json['branch']
          : int.tryParse(json['branch']?.toString() ?? ''),
      branchName: json['branch_name'] ?? '',
      departmentId: json['department'] is int
          ? json['department']
          : int.tryParse(json['department']?.toString() ?? ''),
      departmentName: json['department_name'] ?? '',
      status: json['status'] ?? 'pending',
      section1Start: json['section1_start']?.toString() ?? '07:00:00',
      section1End: json['section1_end']?.toString() ?? '11:00:00',
      section2Start: json['section2_start']?.toString() ?? '13:00:00',
      section2End: json['section2_end']?.toString() ?? '17:00:00',
      workDays: json['work_days']?.toString() ?? 'mon,tue,wed,thu,fri',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      profileUrl: json['profile_url']?.toString() ?? json['profileUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'employee_id': employeeId,
      'fullname': fullname,
      'email': email,
      'role': userRoleToString(role),
      'branch_id': branchId,
      'department_id': departmentId,
      'status': status,
      'section1_start': section1Start,
      'section1_end': section1End,
      'section2_start': section2Start,
      'section2_end': section2End,
      'work_days': workDays,
    };
  }
}
