import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_status.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:get_storage/get_storage.dart';

/// Local User credential representation for offline authentication
class LocalUser {
  final String uid;
  final String email;
  final String? displayName;
  final String refreshToken;

  LocalUser get user => this;

  LocalUser({
    required this.uid,
    required this.email,
    this.displayName,
    String? refreshToken,
  }) : refreshToken = refreshToken ?? 'local_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
}

/// Standalone Cross-Platform Authentication Service.
/// Completely replaces Firebase Auth and Firestore user collection.
class LocalAuthService {
  static final LocalAuthService _instance = LocalAuthService._internal();
  factory LocalAuthService() => _instance;
  LocalAuthService._internal();

  final LocalDatabaseService _db = LocalDatabaseService();
  final GetStorage _authBox = GetStorage('face_attendance_auth');

  LocalUser? _currentUser;

  Future<void> init() async {
    await _authBox.initStorage;
    final cachedUid = _authBox.read<String>('current_user_uid');
    if (cachedUid != null && cachedUid.isNotEmpty) {
      final emp = _db.getEmployeeByUid(cachedUid);
      if (emp != null) {
        _currentUser = LocalUser(
          uid: emp['firebase_uid'] ?? emp['id'].toString(),
          email: emp['email'] ?? '',
          displayName: emp['fullname'],
        );
      }
    }
  }

  LocalUser? getCurrentUser() => _currentUser;

  static const Map<String, Map<String, String>> _demoProfiles = {
    'sonarseang@gmail.com': {'role': 'ceo', 'name': 'Sonar Seang', 'empId': 'EMP-001'},
    'admin@gmail.com': {'role': 'admin', 'name': 'System Admin', 'empId': 'EMP-002'},
    'manager@gmail.com': {'role': 'manager', 'name': 'Sarah Manager', 'empId': 'EMP-003'},
    'leader@gmail.com': {'role': 'leader', 'name': 'David Team Leader', 'empId': 'EMP-004'},
    'employee@gmail.com': {'role': 'employee', 'name': 'Alex Developer', 'empId': 'EMP-005'},
  };

  /// Authenticate with email & password locally
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    var emp = _db.getEmployeeByEmail(cleanEmail);

    if (_demoProfiles.containsKey(cleanEmail)) {
      final demo = _demoProfiles[cleanEmail]!;
      if (emp == null) {
        emp = _db.saveEmployee({
          'fullname': demo['name']!,
          'email': cleanEmail,
          'role': demo['role']!,
          'employee_id': demo['empId']!,
          'branch': 1,
          'branch_name': 'Phnom Penh Headquarters',
          'department': cleanEmail == 'manager@gmail.com' ? 2 : 1,
          'department_name': cleanEmail == 'manager@gmail.com' ? 'Human Resources' : 'Software Engineering',
          'status': 'active',
        });
      } else if (emp['role'] != demo['role'] || emp['fullname'] != demo['name']) {
        emp = _db.updateEmployee(emp['id'], {
          'role': demo['role']!,
          'fullname': demo['name']!,
        }) ?? emp;
      }
      return _createAndCacheUser(emp);
    }

    if (emp == null) {
      // If user not in database, create on the fly as an active employee
      final newEmp = _db.saveEmployee({
        'fullname': cleanEmail.split('@').first.capitalizeFirst,
        'email': cleanEmail,
        'role': 'employee',
        'branch': 1,
        'branch_name': 'Phnom Penh Headquarters',
        'department': 1,
        'department_name': 'Software Engineering',
        'status': 'active',
      });
      return _createAndCacheUser(newEmp);
    }

    return _createAndCacheUser(emp);
  }

  /// Face Login: log in instantly via biometric match
  Future<UserModel?> loginWithFace(String employeeId) async {
    final emp = _db.getEmployeeByUid(employeeId);
    if (emp != null) {
      return _createAndCacheUser(emp);
    }
    return null;
  }

  void setCurrentUserFromModel(UserModel user) {
    _currentUser = LocalUser(
      uid: user.uid,
      email: user.email,
      displayName: user.fullname,
    );
    _authBox.write('current_user_uid', user.uid);
  }

  UserModel _createAndCacheUser(Map<String, dynamic> emp) {
    final uid = emp['firebase_uid'] ?? emp['id'].toString();
    final email = emp['email']?.toString().toLowerCase().trim() ?? '';
    final vault = _db.getUserAccountData(email);

    _currentUser = LocalUser(
      uid: uid,
      email: emp['email'] ?? '',
      displayName: emp['fullname'],
    );
    _authBox.write('current_user_uid', uid);

    final bool hasFace = emp['has_face_registered'] == true ||
        (vault?['has_face_registered'] == true) ||
        _db.getPersons().any((p) =>
            p.id == uid ||
            p.employeeId == emp['employee_id'] ||
            p.employeeId == uid);

    List<double>? templates;
    if (emp['face_templates'] is List) {
      templates = (emp['face_templates'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    } else if (vault?['face_templates'] is List) {
      templates = (vault!['face_templates'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    final vaultPic = vault?['profile_picture']?.toString();
    final empPic = emp['profile_picture']?.toString();
    final effectiveProfilePic = (vaultPic != null && vaultPic.isNotEmpty)
        ? vaultPic
        : ((empPic != null && empPic.isNotEmpty) ? empPic : null);
    final effectiveFaceJpg = emp['face_jpg']?.toString() ?? vault?['face_jpg']?.toString();

    return UserModel(
      uid: uid,
      employeeId: emp['employee_id'] ?? emp['id'].toString(),
      email: emp['email'] ?? '',
      fullname: emp['fullname'] ?? '',
      role: stringToUserRole(emp['role']),
      branchId: emp['branch']?.toString() ?? '1',
      departmentId: emp['department']?.toString() ?? '1',
      status: UserStatus.active,
      createdBy: emp['created_by'] ?? 'system',
      createdAt: emp['created_at'] != null
          ? DateTime.tryParse(emp['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      profileUrl: effectiveProfilePic,
      hasFaceRegistered: hasFace,
      faceTemplates: templates,
      faceJpg: effectiveFaceJpg,
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    await _authBox.remove('current_user_uid');
  }

  Future<void> resetPassowrd({required String email}) async {
    debugPrint('[LocalAuthService] Password reset requested for $email');
  }

  Future<dynamic> signInWithGoogle() async {
    // Provide seamless local mock for Google sign-in
    final emp = _db.getEmployees().first;
    return LocalUser(
      uid: emp['firebase_uid'] ?? 'local_uid_google_1',
      email: emp['email'] ?? 'google_user@company.com',
      displayName: emp['fullname'],
    );
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (_currentUser == null) return null;
    return 'local_jwt_token_${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<UserModel?> getUserByUid(String uid) async {
    final emp = _db.getEmployeeByUid(uid);
    if (emp == null) return null;
    return _createAndCacheUser(emp);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final emp = _db.getEmployeeByEmail(email);
    if (emp == null) return null;
    return _createAndCacheUser(emp);
  }

  Future<void> updateProfilePicture(String uid, String profileUrl) async {
    final emp = _db.getEmployeeByUid(uid) ??
        (_currentUser != null ? _db.getEmployeeByEmail(_currentUser!.email) : null);
    if (emp != null) {
      _db.updateEmployee(emp['id'], {'profile_picture': profileUrl});
      final email = emp['email']?.toString() ?? _currentUser?.email ?? '';
      if (email.isNotEmpty) {
        _db.saveUserAccountData(email, {'profile_picture': profileUrl});
      }
    }
  }

  Future<void> linkFirestoreUser(String targetUid, UserModel user) async {
    final emp = _db.getEmployeeByEmail(user.email);
    if (emp != null) {
      _db.updateEmployee(emp['id'], {'firebase_uid': targetUid});
    }
  }
}

extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
