import 'package:collection/collection.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/services/sqlite_sync_service.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_status.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/foundation.dart';
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
  LocalAuthService._internal() {
    LocalDatabaseService.currentEmailProvider = () => _currentUser?.email;
  }

  final LocalDatabaseService _db = LocalDatabaseService();
  final GetStorage _authBox = GetStorage('face_attendance_auth');

  LocalUser? _currentUser;

  Future<void> init() async {
    await _authBox.initStorage;
    final cachedUid = _authBox.read<String>('current_user_uid');
    if (cachedUid != null && cachedUid.isNotEmpty) {
      var emp = _db.getEmployeeByUid(cachedUid, forDemo: false);
      bool isDemo = false;
      if (emp == null) {
        emp = _db.getEmployeeByUid(cachedUid, forDemo: true);
        if (emp != null) isDemo = true;
      }
      if (emp == null) {
        emp = _db.getEmployeeByUid(cachedUid);
        if (emp != null) isDemo = isDemoAccountEmail(emp['email']);
      }
      if (emp != null) {
        _currentUser = LocalUser(
          uid: emp['firebase_uid'] ?? emp['id'].toString(),
          email: emp['email'] ?? '',
          displayName: emp['fullname'],
        );
        _db.setDemoMode(isDemo || isDemoAccountEmail(emp['email']));
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
    final isDemo = isDemoAccountEmail(cleanEmail);
    _db.setDemoMode(isDemo);
    var emp = _db.getEmployeeByEmail(cleanEmail, forDemo: isDemo);

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
          'password': '123456',
        }, forDemo: true);
      } else if (emp['role'] != demo['role'] || emp['fullname'] != demo['name']) {
        emp = _db.updateEmployee(emp['id'], {
          'role': demo['role']!,
          'fullname': demo['name']!,
        }, forDemo: true) ?? emp;
      }

      final storedPass = emp['password']?.toString() ?? '123456';
      if (password.isNotEmpty && password != storedPass && password != '123456') {
        throw Exception('wrong-password');
      }

      return _createAndCacheUser(emp);
    }

    if (emp == null) {
      final vault = _db.getUserAccountData(cleanEmail);
      if (vault != null && vault['fullname'] != null) {
        emp = _db.saveEmployee({
          'fullname': vault['fullname'],
          'email': cleanEmail,
          'role': vault['role'] ?? 'employee',
          'password': vault['password'] ?? password,
          'branch': vault['branch'],
          'department': vault['department'],
          'status': 'active',
        }, forDemo: false);
      }
    }

    if (emp == null) {
      throw Exception('user-not-found');
    }

    final storedPass = emp['password']?.toString() ??
        _db.getUserAccountData(cleanEmail)?['password']?.toString();
    if (storedPass != null && storedPass.isNotEmpty) {
      if (password != storedPass) {
        throw Exception('wrong-password');
      }
    }

    return _createAndCacheUser(emp);
  }

  /// Register a new user account with specified role
  Future<UserModel> register({
    required String fullname,
    required String email,
    required String password,
    required UserRole role,
    int? branchId,
    String? branchName,
    int? departmentId,
    String? departmentName,
    String? employeeId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('invalid-email');
    }
    if (password.length < 6) {
      throw Exception('weak-password');
    }

    final isDemo = isDemoAccountEmail(cleanEmail);
    _db.setDemoMode(isDemo);

    final existing = _db.getEmployeeByEmail(cleanEmail, forDemo: isDemo);
    if (existing != null) {
      throw Exception('email-already-in-use');
    }

    final branches = _db.getBranches();
    final departments = _db.getDepartments();

    final bId = branchId;
    String bName = branchName ?? '';
    if (bName.isEmpty && bId != null) {
      final matchB = branches.firstWhereOrNull((b) => b['id'] == bId);
      bName = matchB?['name']?.toString() ?? 'Unassigned';
    } else if (bName.isEmpty) {
      bName = 'Unassigned';
    }

    final dId = departmentId;
    String dName = departmentName ?? '';
    if (dName.isEmpty && dId != null) {
      final matchD = departments.firstWhereOrNull((d) => d['id'] == dId);
      dName = matchD?['name']?.toString() ?? 'Unassigned';
    } else if (dName.isEmpty) {
      dName = 'Unassigned';
    }

    final autoEmpId = employeeId != null && employeeId.trim().isNotEmpty
        ? employeeId.trim()
        : 'EMP-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

    final empData = {
      'fullname': fullname.trim(),
      'email': cleanEmail,
      'role': userRoleToString(role),
      'employee_id': autoEmpId,
      'password': password,
      'branch': bId,
      'branch_name': bName,
      'department': dId,
      'department_name': dName,
      'status': 'active',
      'work_days': 'mon,tue,wed,thu,fri',
      'section1_start': '08:00:00',
      'section1_end': '12:00:00',
      'section2_start': '13:00:00',
      'section2_end': '17:00:00',
      'created_at': DateTime.now().toIso8601String(),
      'created_by': 'self_registration',
    };

    final savedEmp = _db.saveEmployee(empData);
    final vaultData = {
      'fullname': fullname.trim(),
      'role': userRoleToString(role),
      'password': password,
      'branch': bId,
      'department': dId,
      'employee_id': autoEmpId,
    };
    _db.saveUserAccountData(cleanEmail, vaultData);

    // Explicitly sync with persistent SQLite backend immediately
    try {
      SqliteSyncService().syncEmployee(savedEmp);
      SqliteSyncService().syncUserVault(email: cleanEmail, vaultData: vaultData);
    } catch (_) {}

    return _createAndCacheUser(savedEmp);
  }

  /// Face Login: log in instantly via biometric match
  Future<UserModel?> loginWithFace(String employeeId) async {
    var emp = _db.getEmployeeByUid(employeeId, forDemo: false);
    if (emp != null) {
      _db.setDemoMode(false);
      return _createAndCacheUser(emp);
    }
    emp = _db.getEmployeeByUid(employeeId, forDemo: true);
    if (emp != null) {
      _db.setDemoMode(true);
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
    _db.setDemoMode(isDemoAccountEmail(user.email));
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
    _db.setDemoMode(null);
  }

  Future<void> resetPassowrd({required String email}) async {
    debugPrint('[LocalAuthService] Password reset requested for $email');
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
