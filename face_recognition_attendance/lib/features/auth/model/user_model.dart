import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_status.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';

class UserModel {
  final String uid;
  final String employeeId;
  final String email;
  final String fullname;

  final String? gender;
  final DateTime? dob;
  final String? phoneNumber;
  final String? profileUrl;

  final UserRole role;

  final String branchId;
  final String departmentId;

  final UserStatus status;

  final String createdBy;
  final DateTime createdAt;

  final String invitationStatus;

  UserModel({
    required this.uid,
    required this.employeeId,
    required this.email,
    required this.fullname,
    this.gender,
    this.dob,
    this.phoneNumber,
    this.profileUrl,
    required this.role,
    required this.branchId,
    required this.departmentId,
    this.status = UserStatus.active,
    required this.createdBy,
    required this.createdAt,
    this.invitationStatus = 'accepted',
  });

  // Convert Object -> Map
  // For storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'employeeId': employeeId,
      'email': email,
      'fullname': fullname,
      'gender': gender,
      'dob': dob == null ? null : Timestamp.fromDate(dob!),
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'role': userRoleToString(role),
      'branchId': branchId,
      'departmentId': departmentId,
      'status': userStatusToString(status),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'invitationStatus': invitationStatus,
    };
  }

  // Convert Firestore Map -> UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      employeeId: map['employeeId'] ?? '',
      email: map['email'] ?? '',
      fullname: map['fullname'] ?? '',

      gender: map['gender'],

      dob: map['dob'] != null ? (map['dob'] as Timestamp).toDate() : null,

      phoneNumber: map['phoneNumber'],
      profileUrl: map['profileUrl'],

      role: stringToUserRole(map['role']) ?? UserRole.employee,

      branchId: map['branchId'] ?? '',
      departmentId: map['departmentId'] ?? '',

      status: stringToUserStatus(map['status']) ?? UserStatus.active,

      createdBy: map['createdBy'] ?? '',

      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),

      invitationStatus: map['invitationStatus'] ?? 'accepted',
    );
  }
  UserModel copyWith({
    String? uid,
    String? employeeId,
    String? email,
    String? fullname,
    String? gender,
    DateTime? dob,
    String? phoneNumber,
    String? profileUrl,
    UserRole? role,
    String? branchId,
    String? departmentId,
    UserStatus? status,
    String? createdBy,
    DateTime? createdAt,
    String? invitationStatus,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      fullname: fullname ?? this.fullname,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileUrl: profileUrl ?? this.profileUrl,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      departmentId: departmentId ?? this.departmentId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      invitationStatus: invitationStatus ?? this.invitationStatus,
    );
  }
}
