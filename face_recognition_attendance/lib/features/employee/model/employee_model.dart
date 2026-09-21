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
  final String createdBy;
  final DateTime? createdAt;

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
    this.createdBy = '',
    this.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      firebaseUid: json['firebase_uid'] ?? '',
      employeeId: json['employee_id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      role: stringToUserRole(json['role']),
      branchId: json['branch'] is int ? json['branch'] : int.tryParse(json['branch']?.toString() ?? ''),
      branchName: json['branch_name'] ?? '',
      departmentId: json['department'] is int ? json['department'] : int.tryParse(json['department']?.toString() ?? ''),
      departmentName: json['department_name'] ?? '',
      status: json['status'] ?? 'pending',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
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
    };
  }
}
