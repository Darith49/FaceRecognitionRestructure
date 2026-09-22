import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';

class MyTeamMember {
  final int id;
  final String firebaseUid;
  final String employeeId;
  final String fullname;
  final String email;
  final String phoneNumber;
  final int? reportingTo;
  final String? reportingToName;
  final String role;
  final int? branch;
  final String? branchName;
  final int? department;
  final String? departmentName;
  final String status;
  final bool hasFaceRegistered;
  final String? section1Start;
  final String? section1End;
  final String? section2Start;
  final String? section2End;
  final String? workDays;

  const MyTeamMember({
    required this.id,
    required this.firebaseUid,
    required this.employeeId,
    required this.fullname,
    required this.email,
    required this.phoneNumber,
    this.reportingTo,
    this.reportingToName,
    required this.role,
    this.branch,
    this.branchName,
    this.department,
    this.departmentName,
    required this.status,
    required this.hasFaceRegistered,
    this.section1Start,
    this.section1End,
    this.section2Start,
    this.section2End,
    this.workDays,
  });

  factory MyTeamMember.fromJson(Map<String, dynamic> json) {
    return MyTeamMember(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      firebaseUid: json['firebase_uid']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      reportingTo: json['reporting_to'] is int ? json['reporting_to'] : null,
      reportingToName: json['reporting_to_name']?.toString(),
      role: json['role']?.toString().toLowerCase() ?? 'employee',
      branch: json['branch'] is int ? json['branch'] : null,
      branchName: json['branch_name']?.toString(),
      department: json['department'] is int ? json['department'] : null,
      departmentName: json['department_name']?.toString(),
      status: json['status']?.toString() ?? 'active',
      hasFaceRegistered: json['has_face_registered'] == true,
      section1Start: json['section1_start']?.toString(),
      section1End: json['section1_end']?.toString(),
      section2Start: json['section2_start']?.toString(),
      section2End: json['section2_end']?.toString(),
      workDays: json['work_days']?.toString(),
    );
  }

  bool get isCeo => role == 'ceo';
  bool get isManager => role == 'manager';
  bool get isLeader => role == 'leader';
  bool get isEmployee => role == 'employee';

  bool get hasPhoneNumber => phoneNumber.trim().isNotEmpty;

  String get initials {
    final parts = fullname.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get displayRole {
    switch (role) {
      case 'ceo':
        return 'CEO';
      case 'manager':
        return 'Manager';
      case 'leader':
        return 'Leader';
      case 'employee':
      default:
        return 'Employee';
    }
  }

  Color get roleColor {
    switch (role) {
      case 'ceo':
        return RequestColors.primary;
      case 'manager':
        return RequestColors.primary;
      case 'leader':
        return RequestColors.gold;
      case 'employee':
      default:
        return RequestColors.teal;
    }
  }

  String get organizationSubtitle {
    final parts = <String>[];
    if (departmentName != null && departmentName!.isNotEmpty) {
      parts.add(departmentName!);
    }
    if (branchName != null && branchName!.isNotEmpty) {
      parts.add(branchName!);
    }
    return parts.isEmpty ? 'Organization Member' : parts.join(' • ');
  }

  static String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '--:--';
    final parts = timeStr.trim().split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return timeStr;
  }

  bool get hasShiftConfigured => section1Start != null && section1Start!.isNotEmpty;

  String get formattedShiftSummary {
    if (!hasShiftConfigured) return '07:00 - 11:00 • 13:00 - 17:00';
    final s1 = '${_formatTime(section1Start)} - ${_formatTime(section1End)}';
    final s2 = '${_formatTime(section2Start)} - ${_formatTime(section2End)}';
    return '$s1 • $s2';
  }

  String get formattedWorkDays {
    if (workDays == null || workDays!.trim().isEmpty) return 'Mon - Fri';
    final raw = workDays!.toLowerCase().split(',').map((d) => d.trim()).toList();
    if (raw.contains('mon') && raw.contains('tue') && raw.contains('wed') && raw.contains('thu') && raw.contains('fri')) {
      if (raw.contains('sat') && raw.contains('sun')) return 'Every Day';
      if (raw.contains('sat')) return 'Mon - Sat';
      return 'Mon - Fri';
    }
    return raw.map((d) => d.isNotEmpty ? '${d[0].toUpperCase()}${d.substring(1)}' : '').join(', ');
  }
}

class MyTeamBranch {
  final int id;
  final String name;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final String managerName;
  final String managerPhone;
  final int totalEmployees;
  final int totalDepartments;

  const MyTeamBranch({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.radius,
    required this.managerName,
    required this.managerPhone,
    required this.totalEmployees,
    required this.totalDepartments,
  });

  factory MyTeamBranch.fromJson(Map<String, dynamic> json) {
    return MyTeamBranch(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      radius: json['radius'] is num ? (json['radius'] as num).toDouble() : null,
      managerName: json['manager_name']?.toString() ?? 'No Manager Assigned',
      managerPhone: json['manager_phone']?.toString() ?? '',
      totalEmployees: json['total_employees'] is int ? json['total_employees'] : 0,
      totalDepartments: json['total_departments'] is int ? json['total_departments'] : 0,
    );
  }

  bool get hasManagerPhone => managerPhone.trim().isNotEmpty;
}

class MyTeamTab {
  final String key;
  final String title;
  final String badge;
  final bool isBranchList;
  final List<dynamic> items;

  const MyTeamTab({
    required this.key,
    required this.title,
    required this.badge,
    required this.isBranchList,
    required this.items,
  });

  factory MyTeamTab.fromJson(Map<String, dynamic> json) {
    final isBranch = json['is_branch_list'] == true;
    final rawItems = json['items'] as List<dynamic>? ?? [];

    final parsedItems = isBranch
        ? rawItems.map((e) => MyTeamBranch.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : rawItems.map((e) => MyTeamMember.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    return MyTeamTab(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '0',
      isBranchList: isBranch,
      items: parsedItems,
    );
  }
}

class MyTeamResponse {
  final String role;
  final MyTeamMember? user;
  final List<MyTeamMember> pinned;
  final List<MyTeamTab> tabs;

  const MyTeamResponse({
    required this.role,
    this.user,
    required this.pinned,
    required this.tabs,
  });

  factory MyTeamResponse.fromJson(Map<String, dynamic> json) {
    final rawPinned = json['pinned'] as List<dynamic>? ?? [];
    final rawTabs = json['tabs'] as List<dynamic>? ?? [];

    return MyTeamResponse(
      role: json['role']?.toString().toLowerCase() ?? 'employee',
      user: json['user'] is Map ? MyTeamMember.fromJson(Map<String, dynamic>.from(json['user'])) : null,
      pinned: rawPinned.map((e) => MyTeamMember.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      tabs: rawTabs.map((e) => MyTeamTab.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}
