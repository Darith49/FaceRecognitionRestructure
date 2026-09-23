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
  final bool hasFaceRegistered;
  final List<double>? faceTemplates;
  final String? faceJpg;

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
    this.hasFaceRegistered = false,
    this.faceTemplates,
    this.faceJpg,
  });

  // Convert Object -> Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'employeeId': employeeId,
      'email': email,
      'fullname': fullname,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'role': userRoleToString(role),
      'branchId': branchId,
      'departmentId': departmentId,
      'status': userStatusToString(status),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'invitationStatus': invitationStatus,
      'hasFaceRegistered': hasFaceRegistered,
      'faceTemplates': faceTemplates,
      'faceJpg': faceJpg,
    };
  }

  // Convert Map -> UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    List<double>? parsedTemplates;
    if (map['faceTemplates'] is List) {
      parsedTemplates = (map['faceTemplates'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    } else if (map['face_templates'] is List) {
      parsedTemplates = (map['face_templates'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return UserModel(
      uid: map['uid'] ?? '',
      employeeId: map['employeeId'] ?? map['employee_id'] ?? '',
      email: map['email'] ?? '',
      fullname: map['fullname'] ?? '',
      gender: map['gender'],
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'].toString()) : null,
      phoneNumber: map['phoneNumber'] ?? map['phone_number'],
      profileUrl: map['profileUrl'] ?? map['profile_picture'],
      role: stringToUserRole(map['role']),
      branchId: map['branchId']?.toString() ?? map['branch']?.toString() ?? '',
      departmentId: map['departmentId']?.toString() ?? map['department']?.toString() ?? '',
      status: stringToUserStatus(map['status']),
      createdBy: map['createdBy'] ?? map['created_by'] ?? '',
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : (map['created_at'] != null
              ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
      invitationStatus: map['invitationStatus'] ?? 'accepted',
      hasFaceRegistered: map['hasFaceRegistered'] == true ||
          map['has_face_registered'] == true,
      faceTemplates: parsedTemplates,
      faceJpg: map['faceJpg']?.toString() ?? map['face_jpg']?.toString(),
    );
  }

  // Convert Object -> JSON Map (for SecureStorage / Local Cache)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'employeeId': employeeId,
      'email': email,
      'fullname': fullname,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'role': userRoleToString(role),
      'branchId': branchId,
      'departmentId': departmentId,
      'status': userStatusToString(status),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'invitationStatus': invitationStatus,
      'hasFaceRegistered': hasFaceRegistered,
      'faceTemplates': faceTemplates,
      'faceJpg': faceJpg,
    };
  }

  // Convert JSON Map -> UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<double>? parsedTemplates;
    if (json['faceTemplates'] is List) {
      parsedTemplates = (json['faceTemplates'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    } else if (json['face_templates'] is List) {
      parsedTemplates = (json['face_templates'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return UserModel(
      uid: json['uid'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
      email: json['email'] ?? '',
      fullname: json['fullname'] ?? '',
      gender: json['gender'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      profileUrl: json['profileUrl'] ?? json['profile_picture'],
      role: stringToUserRole(json['role']),
      branchId: json['branchId']?.toString() ?? json['branch']?.toString() ?? '',
      departmentId: json['departmentId']?.toString() ?? json['department']?.toString() ?? '',
      status: stringToUserStatus(json['status']),
      createdBy: json['createdBy'] ?? json['created_by'] ?? '',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : (json['created_at'] != null
              ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
      invitationStatus: json['invitationStatus'] ?? 'accepted',
      hasFaceRegistered: json['hasFaceRegistered'] == true ||
          json['has_face_registered'] == true,
      faceTemplates: parsedTemplates,
      faceJpg: json['faceJpg']?.toString() ?? json['face_jpg']?.toString(),
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
    bool? hasFaceRegistered,
    List<double>? faceTemplates,
    String? faceJpg,
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
      hasFaceRegistered: hasFaceRegistered ?? this.hasFaceRegistered,
      faceTemplates: faceTemplates ?? this.faceTemplates,
      faceJpg: faceJpg ?? this.faceJpg,
    );
  }
}
