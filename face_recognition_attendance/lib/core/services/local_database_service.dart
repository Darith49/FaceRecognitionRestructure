import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:face_recognition_attendance/core/utils/image_compressor.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';
import 'package:get_storage/get_storage.dart';

const Set<String> kDemoAccountEmails = {
  'sonarseang@gmail.com',
  'admin@gmail.com',
  'manager@gmail.com',
  'leader@gmail.com',
  'employee@gmail.com',
};

bool isDemoAccountEmail(String? email) {
  if (email == null) return false;
  return kDemoAccountEmails.contains(email.trim().toLowerCase());
}

/// Standalone Cross-Platform Local Database Service.
/// Completely replaces Django REST backend and Firestore database.
/// Uses GetStorage for instantaneous, synchronous key-value persistence
/// across Web, Android, iOS, Windows, macOS, and Linux.
///
/// Features strict multi-tenant partition isolation:
/// - Demo accounts operate in `demo_*` partition (pre-seeded with demo employees, branches, etc.)
/// - Real accounts operate in `real_*` partition (clean slate: 0 demo employees, 0 demo branches, 0 demo departments)
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  /// Provider callback to resolve the active user email from auth without circular dependencies.
  static String? Function()? currentEmailProvider;

  /// Hook to mirror writes to persistent SQLite backend without circular dependencies.
  static void Function({required String type, required Map<String, dynamic> payload})? onSyncHook;

  late GetStorage _box;
  bool _isInitialized = false;

  bool? _overrideDemoMode;

  /// Current partition mode: true for Demo accounts, false for Real accounts.
  bool get isDemoMode {
    if (_overrideDemoMode != null) return _overrideDemoMode!;
    final email = currentEmailProvider?.call();
    if (email != null && email.isNotEmpty) {
      return isDemoAccountEmail(email);
    }
    return false;
  }

  /// Explicitly set the active environment mode.
  void setDemoMode(bool? value) {
    _overrideDemoMode = value;
    _cachedDemoPersons = null;
    _cachedRealPersons = null;
  }

  /// Returns partition key prefixed by 'demo_' or 'real_'.
  String _k(String baseKey, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    return useDemo ? 'demo_$baseKey' : 'real_$baseKey';
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _box = GetStorage('face_attendance_local_db');
    await _box.initStorage;
    _seedDefaultDataIfEmpty();
    _syncDemoAccounts();
    _isInitialized = true;
  }

  // ==================== PERSISTENT USER ACCOUNT VAULT ====================
  // Ensures profile pictures and face biometrics are permanently retained
  // across logins, app restarts, and demo account synchronization.
  Map<String, dynamic> _getUserVault() {
    final raw = _box.read<Map>('user_account_vault');
    return raw != null
        ? Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map))))
        : <String, dynamic>{};
  }

  /// Hydrates the local cache with the full persistent state from the SQLite database.
  void hydrateFromSqlite(Map<String, dynamic> data) {
    if (data.containsKey('user_vault') && data['user_vault'] is Map) {
      final incomingVault = Map<String, dynamic>.from(data['user_vault'] as Map);
      final currentVault = _getUserVault();
      incomingVault.forEach((k, v) {
        if (v is Map) {
          final existing = currentVault[k] ?? <String, dynamic>{};
          v.forEach((vk, vv) {
            if (vk == 'profile_picture' && vv != null) {
              final pic = vv.toString();
              if (pic.contains('test_') || pic.contains('TEST_') || pic.length < 50) {
                return;
              }
            }
            existing[vk.toString()] = vv;
          });
          currentVault[k] = existing;
        }
      });
      _box.write('user_account_vault', currentVault);
    }

    if (data.containsKey('employees') && data['employees'] is List) {
      final incomingEmps = (data['employees'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final demoEmps = <Map<String, dynamic>>[];
      final realEmps = <Map<String, dynamic>>[];
      for (final e in incomingEmps) {
        final email = e['email']?.toString() ?? '';
        final isDemo = (e['is_demo'] == 1 || e['is_demo'] == true) || isDemoAccountEmail(email);
        if (isDemo) {
          demoEmps.add(e);
        } else {
          realEmps.add(e);
        }
      }
      if (demoEmps.isNotEmpty) _box.write('demo_employees', demoEmps);
      if (realEmps.isNotEmpty) _box.write('real_employees', realEmps);
    }

    if (data.containsKey('branches') && data['branches'] is List) {
      final incoming = (data['branches'] as List)
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();
      final demoBranches = <Map<String, dynamic>>[];
      final realBranches = <Map<String, dynamic>>[];
      for (final b in incoming) {
        if (b['is_demo'] == 1 || b['is_demo'] == true || b['id'] == 1 || b['id'] == 2) {
          demoBranches.add(b);
        } else {
          realBranches.add(b);
        }
      }
      if (demoBranches.isNotEmpty) _box.write('demo_branches', demoBranches);
      if (realBranches.isNotEmpty) _box.write('real_branches', realBranches);
    }

    if (data.containsKey('departments') && data['departments'] is List) {
      final incoming = (data['departments'] as List)
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();
      final demoDepts = <Map<String, dynamic>>[];
      final realDepts = <Map<String, dynamic>>[];
      for (final d in incoming) {
        if (d['is_demo'] == 1 || d['is_demo'] == true || d['id'] == 1 || d['id'] == 2) {
          demoDepts.add(d);
        } else {
          realDepts.add(d);
        }
      }
      if (demoDepts.isNotEmpty) _box.write('demo_departments', demoDepts);
      if (realDepts.isNotEmpty) _box.write('real_departments', realDepts);
    }

    if (data.containsKey('persons') && data['persons'] is List) {
      final incomingPersons = (data['persons'] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      final demoPersons = <Map<String, dynamic>>[];
      final realPersons = <Map<String, dynamic>>[];
      for (final p in incomingPersons) {
        if (p['is_demo'] == 1 || p['is_demo'] == true) {
          demoPersons.add(p);
        } else {
          realPersons.add(p);
        }
      }
      if (demoPersons.isNotEmpty) _box.write('demo_persons', demoPersons);
      if (realPersons.isNotEmpty) _box.write('real_persons', realPersons);
    }

    if (data.containsKey('attendance') && data['attendance'] is List) {
      final incomingAtt = (data['attendance'] as List)
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
      final demoAtt = <Map<String, dynamic>>[];
      final realAtt = <Map<String, dynamic>>[];
      for (final a in incomingAtt) {
        if (a['is_demo'] == 1 || a['is_demo'] == true) {
          demoAtt.add(a);
        } else {
          realAtt.add(a);
        }
      }
      if (demoAtt.isNotEmpty) _box.write('demo_attendance', demoAtt);
      if (realAtt.isNotEmpty) _box.write('real_attendance', realAtt);
    }

    if (data.containsKey('leaves') && data['leaves'] is List) {
      final incomingLeaves = (data['leaves'] as List)
          .map((l) => Map<String, dynamic>.from(l as Map))
          .toList();
      final demoLeaves = <Map<String, dynamic>>[];
      final realLeaves = <Map<String, dynamic>>[];
      for (final l in incomingLeaves) {
        if (l['is_demo'] == 1 || l['is_demo'] == true || l['id'] == 1 || l['id'] == 2) {
          demoLeaves.add(l);
        } else {
          realLeaves.add(l);
        }
      }
      if (demoLeaves.isNotEmpty) _box.write('demo_leaves', demoLeaves);
      if (realLeaves.isNotEmpty) _box.write('real_leaves', realLeaves);
    }

    if (data.containsKey('overtimes') && data['overtimes'] is List) {
      final incomingOt = (data['overtimes'] as List)
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();
      final demoOt = <Map<String, dynamic>>[];
      final realOt = <Map<String, dynamic>>[];
      for (final o in incomingOt) {
        if (o['is_demo'] == 1 || o['is_demo'] == true || o['id'] == 1) {
          demoOt.add(o);
        } else {
          realOt.add(o);
        }
      }
      if (demoOt.isNotEmpty) _box.write('demo_overtimes', demoOt);
      if (realOt.isNotEmpty) _box.write('real_overtimes', realOt);
    }

    if (data.containsKey('permissions') && data['permissions'] is List) {
      final incomingPerm = (data['permissions'] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      final demoPerm = <Map<String, dynamic>>[];
      final realPerm = <Map<String, dynamic>>[];
      for (final p in incomingPerm) {
        if (p['is_demo'] == 1 || p['is_demo'] == true) {
          demoPerm.add(p);
        } else {
          realPerm.add(p);
        }
      }
      if (demoPerm.isNotEmpty) _box.write('demo_permissions', demoPerm);
      if (realPerm.isNotEmpty) _box.write('real_permissions', realPerm);
    }

    _syncDemoAccounts();
  }

  void saveUserAccountData(String email, Map<String, dynamic> updates) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;
    final vault = _getUserVault();
    final existing = vault[cleanEmail] ?? <String, dynamic>{};
    updates.forEach((k, v) => existing[k] = v);
    vault[cleanEmail] = existing;
    _box.write('user_account_vault', vault);

    // Synchronize profile picture with SQLite backend
    if (updates.containsKey('profile_picture') && updates['profile_picture'] != null) {
      onSyncHook?.call(
        type: 'profile_picture',
        payload: {
          'email': cleanEmail,
          'profile_picture': updates['profile_picture'].toString(),
        },
      );
    }
  }

  Map<String, dynamic>? getUserAccountData(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    final vault = _getUserVault();
    return vault[cleanEmail];
  }

  void _migrateLegacyDataIfNeeded() {
    // Legacy employees migration
    final legacyEmps = _box.read<List>('employees');
    if (legacyEmps != null && _box.read('real_employees') == null) {
      final realEmps = <Map<String, dynamic>>[];
      final demoEmps = <Map<String, dynamic>>[];
      for (final e in legacyEmps) {
        final map = Map<String, dynamic>.from(e as Map);
        final email = map['email']?.toString() ?? '';
        if (isDemoAccountEmail(email)) {
          demoEmps.add(map);
        } else {
          realEmps.add(map);
        }
      }
      _box.write('demo_employees', demoEmps);
      _box.write('real_employees', realEmps);
      _box.remove('employees');
    }

    // Legacy branches migration
    final legacyBranches = _box.read<List>('branches');
    if (legacyBranches != null && _box.read('real_branches') == null) {
      _box.write('demo_branches', legacyBranches);
      _box.write('real_branches', <Map<String, dynamic>>[]);
      _box.remove('branches');
    }

    // Legacy departments migration
    final legacyDepts = _box.read<List>('departments');
    if (legacyDepts != null && _box.read('real_departments') == null) {
      _box.write('demo_departments', legacyDepts);
      _box.write('real_departments', <Map<String, dynamic>>[]);
      _box.remove('departments');
    }

    // Legacy leaves migration
    final legacyLeaves = _box.read<List>('leaves');
    if (legacyLeaves != null && _box.read('real_leaves') == null) {
      _box.write('demo_leaves', legacyLeaves);
      _box.write('real_leaves', <Map<String, dynamic>>[]);
      _box.remove('leaves');
    }

    // Legacy overtimes migration
    final legacyOvertimes = _box.read<List>('overtimes');
    if (legacyOvertimes != null && _box.read('real_overtimes') == null) {
      _box.write('demo_overtimes', legacyOvertimes);
      _box.write('real_overtimes', <Map<String, dynamic>>[]);
      _box.remove('overtimes');
    }

    // Legacy attendance migration
    final legacyAtt = _box.read<List>('attendance');
    if (legacyAtt != null && _box.read('real_attendance') == null) {
      _box.write('demo_attendance', legacyAtt);
      _box.write('real_attendance', <Map<String, dynamic>>[]);
      _box.remove('attendance');
    }

    // Legacy persons migration
    final legacyPersons = _box.read<List>('persons');
    if (legacyPersons != null && _box.read('real_persons') == null) {
      _box.write('demo_persons', legacyPersons);
      _box.write('real_persons', <Map<String, dynamic>>[]);
      _box.remove('persons');
    }

    // Legacy permissions migration
    final legacyPerms = _box.read<List>('permissions');
    if (legacyPerms != null && _box.read('real_permissions') == null) {
      _box.write('demo_permissions', legacyPerms);
      _box.write('real_permissions', <Map<String, dynamic>>[]);
      _box.remove('permissions');
    }

    // Legacy suggestions migration
    final legacySuggs = _box.read<List>('suggestions');
    if (legacySuggs != null && _box.read('real_suggestions') == null) {
      _box.write('demo_suggestions', legacySuggs);
      _box.write('real_suggestions', <Map<String, dynamic>>[]);
      _box.remove('suggestions');
    }

    // Legacy notifications migration
    final legacyNotifs = _box.read<List>('notifications');
    if (legacyNotifs != null && _box.read('real_notifications') == null) {
      _box.write('demo_notifications', legacyNotifs);
      _box.write('real_notifications', <Map<String, dynamic>>[]);
      _box.remove('notifications');
    }
  }

  void _seedDefaultDataIfEmpty() {
    _migrateLegacyDataIfNeeded();

    // 1. Seed Demo Branches & Initialize Real Branches
    if (_box.read('demo_branches') == null) {
      _box.write('demo_branches', [
        {
          'id': 1,
          'name': 'Phnom Penh Headquarters',
          'address': 'Russian Federation Blvd, Phnom Penh, Cambodia',
          'latitude': 11.5564,
          'longitude': 104.9282,
          'radius': 500.0,
          'created_at': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        },
        {
          'id': 2,
          'name': 'Siem Reap Regional Hub',
          'address': 'National Road 6, Siem Reap, Cambodia',
          'latitude': 13.3633,
          'longitude': 103.8564,
          'radius': 500.0,
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        }
      ]);
    }
    if (_box.read('real_branches') == null) {
      _box.write('real_branches', <Map<String, dynamic>>[]);
    }

    // 2. Seed Demo Departments & Initialize Real Departments
    if (_box.read('demo_departments') == null) {
      _box.write('demo_departments', [
        {
          'id': 1,
          'name': 'Software Engineering',
          'code': 'ENG',
          'description': 'Mobile & Cloud Development team',
          'manager_name': 'Darith Admin',
          'employee_count': 5,
          'created_at': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        },
        {
          'id': 2,
          'name': 'Human Resources',
          'code': 'HR',
          'description': 'Recruitment & Employee Relations',
          'manager_name': 'Sarah Manager',
          'employee_count': 2,
          'created_at': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        }
      ]);
    }
    if (_box.read('real_departments') == null) {
      _box.write('real_departments', <Map<String, dynamic>>[]);
    }

    // 3. Seed Demo Employees & Initialize Real Employees
    if (_box.read('demo_employees') == null) {
      _box.write('demo_employees', [
        {
          'id': 1,
          'firebase_uid': 'local_uid_ceo_1',
          'employee_id': 'EMP-001',
          'fullname': 'Sonar Seang',
          'email': 'sonarseang@gmail.com',
          'role': 'ceo',
          'branch': 1,
          'branch_name': 'Phnom Penh Headquarters',
          'department': 1,
          'department_name': 'Software Engineering',
          'status': 'active',
          'section1_start': '08:00:00',
          'section1_end': '12:00:00',
          'section2_start': '13:00:00',
          'section2_end': '17:00:00',
          'work_days': 'mon,tue,wed,thu,fri',
          'created_by': 'system',
          'created_at': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
          'profile_picture': null,
        },
        {
          'id': 2,
          'firebase_uid': 'local_uid_admin_2',
          'employee_id': 'EMP-002',
          'fullname': 'System Admin',
          'email': 'admin@gmail.com',
          'role': 'admin',
          'branch': 1,
          'branch_name': 'Phnom Penh Headquarters',
          'department': 1,
          'department_name': 'Software Engineering',
          'status': 'active',
          'section1_start': '08:00:00',
          'section1_end': '12:00:00',
          'section2_start': '13:00:00',
          'section2_end': '17:00:00',
          'work_days': 'mon,tue,wed,thu,fri',
          'created_by': 'EMP-001',
          'created_at': DateTime.now().subtract(const Duration(days: 75)).toIso8601String(),
          'profile_picture': null,
        },
        {
          'id': 3,
          'firebase_uid': 'local_uid_mgr_3',
          'employee_id': 'EMP-003',
          'fullname': 'Sarah Manager',
          'email': 'manager@gmail.com',
          'role': 'manager',
          'branch': 1,
          'branch_name': 'Phnom Penh Headquarters',
          'department': 2,
          'department_name': 'Human Resources',
          'status': 'active',
          'section1_start': '08:00:00',
          'section1_end': '12:00:00',
          'section2_start': '13:00:00',
          'section2_end': '17:00:00',
          'work_days': 'mon,tue,wed,thu,fri',
          'created_by': 'EMP-001',
          'created_at': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          'profile_picture': null,
        },
        {
          'id': 4,
          'firebase_uid': 'local_uid_ldr_4',
          'employee_id': 'EMP-004',
          'fullname': 'David Team Leader',
          'email': 'leader@gmail.com',
          'role': 'leader',
          'branch': 1,
          'branch_name': 'Phnom Penh Headquarters',
          'department': 1,
          'department_name': 'Software Engineering',
          'status': 'active',
          'section1_start': '08:00:00',
          'section1_end': '12:00:00',
          'section2_start': '13:00:00',
          'section2_end': '17:00:00',
          'work_days': 'mon,tue,wed,thu,fri',
          'created_by': 'EMP-001',
          'created_at': DateTime.now().subtract(const Duration(days: 50)).toIso8601String(),
          'profile_picture': null,
        },
        {
          'id': 5,
          'firebase_uid': 'local_uid_emp_5',
          'employee_id': 'EMP-005',
          'fullname': 'Alex Developer',
          'email': 'employee@gmail.com',
          'role': 'employee',
          'branch': 1,
          'branch_name': 'Phnom Penh Headquarters',
          'department': 1,
          'department_name': 'Software Engineering',
          'status': 'active',
          'section1_start': '08:00:00',
          'section1_end': '12:00:00',
          'section2_start': '13:00:00',
          'section2_end': '17:00:00',
          'work_days': 'mon,tue,wed,thu,fri',
          'created_by': 'EMP-001',
          'created_at': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
          'profile_picture': null,
        },
      ]);
    }
    if (_box.read('real_employees') == null) {
      _box.write('real_employees', <Map<String, dynamic>>[]);
    }

    // 4. Seed Registered Biometric Persons
    if (_box.read('demo_persons') == null) _box.write('demo_persons', []);
    if (_box.read('real_persons') == null) _box.write('real_persons', []);

    // 5. Seed Attendance
    if (_box.read('demo_attendance') == null) _box.write('demo_attendance', []);
    if (_box.read('real_attendance') == null) _box.write('real_attendance', []);

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final monthStartStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-03';

    // 6. Seed Leaves
    if (_box.read('demo_leaves') == null) {
      _box.write('demo_leaves', [
        {
          'id': 1,
          'employee_id': 5,
          'employee_name': 'Alex Developer',
          'employee_code': 'EMP-005',
          'employee_id_code': 'EMP-005',
          'employee_uid': 'local_uid_emp_5',
          'employee_email': 'employee@gmail.com',
          'employee_role': 'employee',
          'branch': 1,
          'department': 1,
          'leave_type': 'Personal Leave',
          'day_type': 'Full Day',
          'from_date': monthStartStr,
          'to_date': monthStartStr,
          'session': 0,
          'leave_mode': 'full_section',
          'reason': 'Family urgent appointment in hometown.',
          'status': 'approved',
          'reviewer_name': 'David Team Leader',
          'review_notes': 'Approved. Safe travels.',
          'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
        },
        {
          'id': 2,
          'employee_id': 5,
          'employee_name': 'Alex Developer',
          'employee_code': 'EMP-005',
          'employee_id_code': 'EMP-005',
          'employee_uid': 'local_uid_emp_5',
          'employee_email': 'employee@gmail.com',
          'employee_role': 'employee',
          'branch': 1,
          'department': 1,
          'leave_type': 'Section 1 (Morning)',
          'day_type': 'Section 1 (Morning)',
          'from_date': tomorrowStr,
          'to_date': tomorrowStr,
          'session': 1,
          'leave_mode': 'early_leave',
          'early_leave_time': '09:30:00',
          'reason': 'Dentist appointment checkup in the morning.',
          'status': 'pending',
          'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
        },
      ]);
    }
    if (_box.read('real_leaves') == null) {
      _box.write('real_leaves', <Map<String, dynamic>>[]);
    }

    // 7. Seed Overtime
    if (_box.read('demo_overtimes') == null) {
      _box.write('demo_overtimes', [
        {
          'id': 1,
          'employee_id': 4,
          'employee_name': 'David Team Leader',
          'employee_code': 'EMP-004',
          'employee_id_code': 'EMP-004',
          'employee_uid': 'local_uid_ldr_4',
          'employee_email': 'leader@gmail.com',
          'employee_role': 'leader',
          'branch': 1,
          'department': 1,
          'date': todayStr,
          'start_time': '18:00:00',
          'end_time': '20:00:00',
          'reason': 'Database indexing and migration deployment.',
          'status': 'pending',
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
      ]);
    }
    if (_box.read('real_overtimes') == null) {
      _box.write('real_overtimes', <Map<String, dynamic>>[]);
    }

    // 8. Seed Permissions
    if (_box.read('demo_permissions') == null) {
      _box.write('demo_permissions', [
        {
          'id': 1,
          'employee_id': 3,
          'employee_name': 'Sarah Manager',
          'employee_code': 'EMP-003',
          'employee_id_code': 'EMP-003',
          'employee_uid': 'local_uid_mgr_3',
          'employee_email': 'manager@gmail.com',
          'employee_role': 'manager',
          'branch': 1,
          'department': 2,
          'date': todayStr,
          'session': 2,
          'schedule_time': 'Section 2',
          'reason': 'Ministry quarterly board conference.',
          'status': 'pending',
          'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
      ]);
    }
    if (_box.read('real_permissions') == null) {
      _box.write('real_permissions', <Map<String, dynamic>>[]);
    }

    // 9. Seed Suggestions
    if (_box.read('demo_suggestions') == null) {
      _box.write('demo_suggestions', [
        {
          'id': 1,
          'title': 'Coffee Machine in Breakroom',
          'content': 'Would be great to add an espresso coffee maker on the 2nd floor.',
          'message': 'Would be great to add an espresso coffee maker on the 2nd floor.',
          'type': 'Facility',
          'is_anonymous': true,
          'is_read': false,
          'employee_id': 5,
          'employee_name': 'Anonymous',
          'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 2,
          'title': 'Ergonomic Standing Desks',
          'content': 'Standing desks would greatly help health and posture during long coding sprints.',
          'message': 'Standing desks would greatly help health and posture during long coding sprints.',
          'type': 'Equipment',
          'is_anonymous': true,
          'is_read': true,
          'employee_id': 5,
          'employee_name': 'Anonymous',
          'read_by_name': 'Sonar Seang',
          'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        }
      ]);
    }
    if (_box.read('real_suggestions') == null) {
      _box.write('real_suggestions', <Map<String, dynamic>>[]);
    }

    // 10. Seed Notifications
    if (_box.read('demo_notifications') == null) {
      _box.write('demo_notifications', [
        {
          'id': 101,
          'recipient_id': '4',
          'recipient_uid': 'local_uid_ldr_4',
          'title': 'New Leave Request',
          'message': 'Alex Developer submitted a leave request (Section 1 • Early leave at 09:30 AM).',
          'notif_type': 'leave',
          'ref_id': '2',
          'sender_name': 'Alex Developer',
          'is_read': false,
          'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
        },
        {
          'id': 102,
          'recipient_id': '3',
          'recipient_uid': 'local_uid_mgr_3',
          'title': 'New Overtime Request',
          'message': 'David Team Leader submitted an overtime request for today (18:00 - 20:00).',
          'notif_type': 'overtime',
          'ref_id': '1',
          'sender_name': 'David Team Leader',
          'is_read': false,
          'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 103,
          'recipient_id': '1',
          'recipient_uid': 'local_uid_ceo_1',
          'title': 'New Permission Request',
          'message': 'Sarah Manager submitted a permission request for Section 2.',
          'notif_type': 'permission',
          'ref_id': '1',
          'sender_name': 'Sarah Manager',
          'is_read': false,
          'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
        {
          'id': 104,
          'recipient_id': '1',
          'recipient_uid': 'local_uid_ceo_1',
          'title': 'New Suggestion Submitted',
          'message': 'Anonymous Suggestion: Would be great to add an espresso coffee maker on the 2nd floor.',
          'notif_type': 'suggestion',
          'ref_id': '1',
          'sender_name': 'Anonymous',
          'is_read': false,
          'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': 105,
          'recipient_id': '5',
          'recipient_uid': 'local_uid_emp_5',
          'title': 'Leave Request Approved',
          'message': 'Your personal leave request was approved by David Team Leader.',
          'notif_type': 'leave',
          'ref_id': '1',
          'sender_name': 'David Team Leader',
          'is_read': true,
          'created_at': now.subtract(const Duration(days: 14)).toIso8601String(),
        },
        {
          'id': 106,
          'recipient_id': null,
          'recipient_uid': null,
          'title': 'Welcome to Face Attendance App',
          'message': 'System now operates completely on-device with zero backend dependencies.',
          'notif_type': 'system',
          'ref_id': '',
          'sender_name': 'System Admin',
          'is_read': true,
          'created_at': now.toIso8601String(),
        }
      ]);
    }
    if (_box.read('real_notifications') == null) {
      _box.write('real_notifications', [
        {
          'id': 1,
          'recipient_id': null,
          'recipient_uid': null,
          'title': 'Welcome to Face Attendance App',
          'message': 'System is initialized with a clean organization workspace.',
          'notif_type': 'system',
          'ref_id': '',
          'sender_name': 'System Admin',
          'is_read': false,
          'created_at': now.toIso8601String(),
        }
      ]);
    }
  }

  /// Ensures demo accounts always exist in the demo partition and have their exact specified roles.
  void _syncDemoAccounts() {
    final demoDefs = [
      {
        'firebase_uid': 'local_uid_ceo_1',
        'employee_id': 'EMP-001',
        'fullname': 'Sonar Seang',
        'email': 'sonarseang@gmail.com',
        'role': 'ceo',
        'branch': 1,
        'branch_name': 'Phnom Penh Headquarters',
        'department': 1,
        'department_name': 'Software Engineering',
        'status': 'active',
        'is_demo': true,
      },
      {
        'firebase_uid': 'local_uid_admin_2',
        'employee_id': 'EMP-002',
        'fullname': 'System Admin',
        'email': 'admin@gmail.com',
        'role': 'admin',
        'branch': 1,
        'branch_name': 'Phnom Penh Headquarters',
        'department': 1,
        'department_name': 'Software Engineering',
        'status': 'active',
        'is_demo': true,
      },
      {
        'firebase_uid': 'local_uid_mgr_3',
        'employee_id': 'EMP-003',
        'fullname': 'Sarah Manager',
        'email': 'manager@gmail.com',
        'role': 'manager',
        'branch': 1,
        'branch_name': 'Phnom Penh Headquarters',
        'department': 2,
        'department_name': 'Human Resources',
        'status': 'active',
        'is_demo': true,
      },
      {
        'firebase_uid': 'local_uid_ldr_4',
        'employee_id': 'EMP-004',
        'fullname': 'David Team Leader',
        'email': 'leader@gmail.com',
        'role': 'leader',
        'branch': 1,
        'branch_name': 'Phnom Penh Headquarters',
        'department': 1,
        'department_name': 'Software Engineering',
        'status': 'active',
        'is_demo': true,
      },
      {
        'firebase_uid': 'local_uid_emp_5',
        'employee_id': 'EMP-005',
        'fullname': 'Alex Developer',
        'email': 'employee@gmail.com',
        'role': 'employee',
        'branch': 1,
        'branch_name': 'Phnom Penh Headquarters',
        'department': 1,
        'department_name': 'Software Engineering',
        'status': 'active',
        'is_demo': true,
      },
    ];

    final raw = _box.read<List>('demo_employees');
    final employees = raw != null
        ? List<Map<String, dynamic>>.from(raw.map((e) => Map<String, dynamic>.from(e as Map)))
        : <Map<String, dynamic>>[];

    final vault = _getUserVault();
    for (final demo in demoDefs) {
      final email = demo['email']?.toString().toLowerCase().trim() ?? '';
      final idx = employees.indexWhere((e) =>
          e['email']?.toString().toLowerCase().trim() == email);
      if (idx != -1) {
        employees[idx]['role'] = demo['role'];
        employees[idx]['fullname'] = demo['fullname'];
        employees[idx]['employee_id'] = demo['employee_id'];
        employees[idx]['firebase_uid'] ??= demo['firebase_uid'];
        employees[idx]['branch'] ??= demo['branch'];
        employees[idx]['branch_name'] ??= demo['branch_name'];
        employees[idx]['department'] ??= demo['department'];
        employees[idx]['department_name'] ??= demo['department_name'];
        employees[idx]['status'] = 'active';
        employees[idx]['is_demo'] = true;

        // Restore biometrics and profile picture from vault if present
        if (vault.containsKey(email)) {
          final v = vault[email]!;
          if (v['profile_picture'] != null && v['profile_picture'].toString().isNotEmpty) {
            employees[idx]['profile_picture'] = v['profile_picture'];
          }
          if (v['has_face_registered'] == true) {
            employees[idx]['has_face_registered'] = true;
            employees[idx]['face_templates'] ??= v['face_templates'];
            employees[idx]['face_jpg'] ??= v['face_jpg'];
            employees[idx]['face_registered_at'] ??= v['face_registered_at'];
          }
        }
      } else {
        int nextId = 1;
        if (employees.isNotEmpty) {
          nextId = employees.map((e) => (e['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
        }
        final v = vault[email];
        employees.add({
          'id': nextId,
          'section1_start': '08:00:00',
          'section1_end': '12:00:00',
          'section2_start': '13:00:00',
          'section2_end': '17:00:00',
          'work_days': 'mon,tue,wed,thu,fri',
          'created_by': 'system',
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'profile_picture': v?['profile_picture'],
          'has_face_registered': v?['has_face_registered'] == true,
          'face_templates': v?['face_templates'],
          'face_jpg': v?['face_jpg'],
          ...demo,
        });
      }
    }

    _box.write('demo_employees', employees);
  }

  // ==================== PERSONS (BIOMETRICS) ====================
  List<Person>? _cachedDemoPersons;
  List<Person>? _cachedRealPersons;

  List<Person> getPersons({bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    if (useDemo && _cachedDemoPersons != null) return _cachedDemoPersons!;
    if (!useDemo && _cachedRealPersons != null) return _cachedRealPersons!;

    final personsKey = _k('persons', forDemo: useDemo);
    final empKey = _k('employees', forDemo: useDemo);

    final raw = _box.read<List>(personsKey) ?? [];
    final persons = raw.map((e) => Person.fromMap(Map<String, dynamic>.from(e))).toList();

    // Two-way self-healing auto-recovery between 'persons' and 'employees'
    final rawEmp = _box.read<List>(empKey) ?? [];
    final empList = List<Map<String, dynamic>>.from(rawEmp.map((e) => Map<String, dynamic>.from(e as Map)));
    bool updatedPersons = false;
    bool updatedEmployees = false;

    for (var i = 0; i < empList.length; i++) {
      final emp = empList[i];
      final empCode = emp['employee_id']?.toString() ?? '';
      final empUid = emp['firebase_uid']?.toString() ?? emp['id']?.toString() ?? '';

      final personIdx = persons.indexWhere((p) =>
          p.id == empUid ||
          (empCode.isNotEmpty && p.employeeId == empCode) ||
          p.employeeId == empUid);

      if (personIdx >= 0) {
        if (emp['has_face_registered'] != true) {
          emp['has_face_registered'] = true;
          emp['face_templates'] ??= persons[personIdx].templates;
          emp['face_jpg'] ??= base64Encode(persons[personIdx].faceJpg);
          emp['face_registered_at'] ??= persons[personIdx].enrolledAt.toIso8601String();
          empList[i] = emp;
          updatedEmployees = true;
        }
      } else if (emp['has_face_registered'] == true &&
          emp['face_templates'] is List &&
          (emp['face_templates'] as List).isNotEmpty) {
        final restored = Person.fromMap({
          'id': empUid,
          'name': emp['fullname'] ?? 'User',
          'employeeId': empCode.isNotEmpty ? empCode : empUid,
          'faceJpg': emp['face_jpg'] ?? '',
          'templates': emp['face_templates'],
          'enrolledAt': emp['face_registered_at'] ?? DateTime.now().toIso8601String(),
        });
        persons.add(restored);
        updatedPersons = true;
      }
    }

    if (updatedPersons) {
      _box.write(personsKey, persons.map((p) => p.toMap()).toList());
    }
    if (updatedEmployees) {
      _box.write(empKey, empList);
    }

    if (useDemo) {
      _cachedDemoPersons = persons;
      return _cachedDemoPersons!;
    } else {
      _cachedRealPersons = persons;
      return _cachedRealPersons!;
    }
  }

  void savePerson(Person person, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    if (useDemo) {
      _cachedDemoPersons = null;
    } else {
      _cachedRealPersons = null;
    }
    final personsKey = _k('persons', forDemo: useDemo);
    final empKey = _k('employees', forDemo: useDemo);

    // Compress reference face image to prevent exceeding browser storage quota
    final compressedFaceJpg = ImageCompressor.compressFaceReference(person.faceJpg);
    final optimizedPerson = Person(
      id: person.id,
      name: person.name,
      employeeId: person.employeeId,
      faceJpg: compressedFaceJpg,
      templates: person.templates,
      enrolledAt: person.enrolledAt,
    );

    final list = _box.read<List>(personsKey) ?? [];
    final existingIndex = list.indexWhere((p) => p['id'] == optimizedPerson.id || p['employeeId'] == optimizedPerson.employeeId);
    if (existingIndex >= 0) {
      list[existingIndex] = optimizedPerson.toMap();
    } else {
      list.add(optimizedPerson.toMap());
    }
    _box.write(personsKey, list);

    // Save directly to the account in 'employees' storage and vault
    final rawEmp = _box.read<List>(empKey) ?? [];
    final empList = List<Map<String, dynamic>>.from(rawEmp.map((e) => Map<String, dynamic>.from(e as Map)));
    final empIdx = empList.indexWhere((e) =>
        e['id']?.toString() == optimizedPerson.id ||
        e['firebase_uid']?.toString() == optimizedPerson.id ||
        e['employee_id']?.toString() == optimizedPerson.employeeId ||
        e['employee_id']?.toString() == optimizedPerson.id);
    if (empIdx >= 0) {
      empList[empIdx]['has_face_registered'] = true;
      empList[empIdx]['face_templates'] = optimizedPerson.templates;
      empList[empIdx]['face_jpg'] = base64Encode(optimizedPerson.faceJpg);
      empList[empIdx]['face_registered_at'] = optimizedPerson.enrolledAt.toIso8601String();
      _box.write(empKey, empList);

      final email = empList[empIdx]['email']?.toString();
      if (email != null && email.isNotEmpty) {
        saveUserAccountData(email, {
          'has_face_registered': true,
          'face_templates': optimizedPerson.templates,
          'face_jpg': base64Encode(optimizedPerson.faceJpg),
          'face_registered_at': optimizedPerson.enrolledAt.toIso8601String(),
        });

        // Mirror directly to SQLite database backend
        onSyncHook?.call(
          type: 'face_registration',
          payload: {
            'email': email,
            'uid': optimizedPerson.id,
            'employeeId': optimizedPerson.employeeId,
            'name': optimizedPerson.name,
            'templates': optimizedPerson.templates,
            'referenceImage': base64Encode(optimizedPerson.faceJpg),
          },
        );
      }
    }
  }

  void deletePerson(String id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    if (useDemo) {
      _cachedDemoPersons = null;
    } else {
      _cachedRealPersons = null;
    }
    final personsKey = _k('persons', forDemo: useDemo);
    final empKey = _k('employees', forDemo: useDemo);

    final list = _box.read<List>(personsKey) ?? [];
    list.removeWhere((p) => p['id'] == id || p['employeeId'] == id);
    _box.write(personsKey, list);

    // Clear face biometrics from the employee account
    final rawEmp = _box.read<List>(empKey) ?? [];
    final empList = List<Map<String, dynamic>>.from(rawEmp.map((e) => Map<String, dynamic>.from(e as Map)));
    final empIdx = empList.indexWhere((e) =>
        e['id']?.toString() == id ||
        e['firebase_uid']?.toString() == id ||
        e['employee_id']?.toString() == id);
    if (empIdx >= 0) {
      empList[empIdx]['has_face_registered'] = false;
      empList[empIdx]['face_templates'] = null;
      empList[empIdx]['face_jpg'] = null;
      empList[empIdx]['face_registered_at'] = null;
      _box.write(empKey, empList);
    }
  }  // ==================== EMPLOYEES ====================
  List<Map<String, dynamic>> getEmployees({bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final empKey = _k('employees', forDemo: useDemo);
    final raw = _box.read<List>(empKey) ?? [];
    final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final personList = getPersons(forDemo: useDemo);
    final vault = _getUserVault();

    for (final emp in list) {
      final email = emp['email']?.toString().toLowerCase().trim() ?? '';
      final empCode = emp['employee_id']?.toString() ?? '';
      final empUid = emp['firebase_uid']?.toString() ?? emp['id']?.toString() ?? '';

      // Restore from vault if available
      if (vault.containsKey(email)) {
        final v = vault[email]!;
        if (v['profile_picture'] != null && v['profile_picture'].toString().isNotEmpty) {
          emp['profile_picture'] = v['profile_picture'];
        }
        if (v['has_face_registered'] == true) {
          emp['has_face_registered'] = true;
          emp['face_templates'] ??= v['face_templates'];
          emp['face_jpg'] ??= v['face_jpg'];
          emp['face_registered_at'] ??= v['face_registered_at'];
        }
      }

      final hasFace = emp['has_face_registered'] == true ||
          personList.any((p) =>
              p.id == empUid ||
              (empCode.isNotEmpty && p.employeeId == empCode) ||
              p.employeeId == empUid);
      emp['has_face_registered'] = hasFace;
    }
    return list;
  }

  Map<String, dynamic>? getEmployeeByEmail(String email, {bool? forDemo}) {
    final target = email.toLowerCase().trim();
    final isDemoEmail = isDemoAccountEmail(target);
    final list = getEmployees(forDemo: forDemo ?? (isDemoEmail ? true : isDemoMode));
    for (final e in list) {
      final empEmail = e['email']?.toString().toLowerCase().trim();
      if (empEmail == target) return e;
    }
    // Fallback across partitions if not found and forDemo was not explicitly specified
    if (forDemo == null) {
      final otherList = getEmployees(forDemo: !isDemoEmail);
      for (final e in otherList) {
        final empEmail = e['email']?.toString().toLowerCase().trim();
        if (empEmail == target) return e;
      }
    }
    return null;
  }

  Map<String, dynamic>? getEmployeeByUid(String uid, {bool? forDemo}) {
    final target = uid.trim();
    final list = getEmployees(forDemo: forDemo);
    for (final e in list) {
      if (e['firebase_uid']?.toString() == target ||
          e['id']?.toString() == target ||
          e['employee_id']?.toString() == target) {
        return e;
      }
    }
    // Fallback across partitions if not found and forDemo was not explicitly specified
    if (forDemo == null) {
      final otherList = getEmployees(forDemo: !isDemoMode);
      for (final e in otherList) {
        if (e['firebase_uid']?.toString() == target ||
            e['id']?.toString() == target ||
            e['employee_id']?.toString() == target) {
          return e;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> saveEmployee(Map<String, dynamic> data, {bool? forDemo}) {
    final useDemo = forDemo ?? (isDemoAccountEmail(data['email']?.toString() ?? '') ? true : isDemoMode);
    final empKey = _k('employees', forDemo: useDemo);
    final list = getEmployees(forDemo: useDemo);
    final int nextId = list.isEmpty ? 1 : (list.map((e) => (e['id'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b) + 1);
    final newEmp = Map<String, dynamic>.from(data);
    newEmp['id'] = nextId;
    if (newEmp['employee_id'] == null || newEmp['employee_id'].toString().isEmpty) {
      newEmp['employee_id'] = 'EMP-${nextId.toString().padLeft(3, '0')}';
    }
    if (newEmp['firebase_uid'] == null || newEmp['firebase_uid'].toString().isEmpty) {
      newEmp['firebase_uid'] = 'local_uid_${newEmp['employee_id']}';
    }
    newEmp['created_at'] = DateTime.now().toIso8601String();
    newEmp['is_demo'] = useDemo;
    list.add(newEmp);
    _box.write(empKey, list);
    return newEmp;
  }

  Map<String, dynamic>? updateEmployee(dynamic id, Map<String, dynamic> updates, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final empKey = _k('employees', forDemo: useDemo);
    final list = getEmployees(forDemo: useDemo);
    final idx = list.indexWhere((e) => e['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);

    // Automatically optimize profile picture if being updated
    if (updates.containsKey('profile_picture') && updates['profile_picture'] != null) {
      final rawPic = updates['profile_picture'].toString();
      if (rawPic.isNotEmpty) {
        updates['profile_picture'] = ImageCompressor.compressProfilePicture(rawPic);
      }
    }

    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write(empKey, list);

    // Keep vault in sync
    final email = updated['email']?.toString().toLowerCase().trim();
    if (email != null && email.isNotEmpty) {
      final vaultUpdates = <String, dynamic>{};
      if (updates.containsKey('profile_picture')) {
        vaultUpdates['profile_picture'] = updates['profile_picture'];
      }
      if (updates.containsKey('has_face_registered')) {
        vaultUpdates['has_face_registered'] = updates['has_face_registered'];
      }
      if (vaultUpdates.isNotEmpty) {
        saveUserAccountData(email, vaultUpdates);
      }
    }

    return updated;
  }

  bool deleteEmployee(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final empKey = _k('employees', forDemo: useDemo);
    final list = getEmployees(forDemo: useDemo);
    final countBefore = list.length;
    list.removeWhere((e) => e['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write(empKey, list);
      return true;
    }
    return false;
  }

  // ==================== DEPARTMENTS ====================
  List<Map<String, dynamic>> getDepartments({bool? forDemo}) {
    final key = _k('departments', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> saveDepartment(Map<String, dynamic> data, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('departments', forDemo: useDemo);
    final list = getDepartments(forDemo: useDemo);
    final int nextId = list.isEmpty ? 1 : (list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final newDept = Map<String, dynamic>.from(data);
    newDept['id'] = nextId;
    newDept['employee_count'] = newDept['employee_count'] ?? 0;
    newDept['created_at'] = DateTime.now().toIso8601String();
    newDept['is_demo'] = useDemo;
    list.add(newDept);
    _box.write(key, list);
    return newDept;
  }

  Map<String, dynamic>? updateDepartment(dynamic id, Map<String, dynamic> updates, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('departments', forDemo: useDemo);
    final list = getDepartments(forDemo: useDemo);
    final idx = list.indexWhere((d) => d['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write(key, list);
    return updated;
  }

  bool deleteDepartment(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('departments', forDemo: useDemo);
    final list = getDepartments(forDemo: useDemo);
    final countBefore = list.length;
    list.removeWhere((d) => d['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write(key, list);
      return true;
    }
    return false;
  }

  // ==================== BRANCHES ====================
  List<Map<String, dynamic>> getBranches({bool? forDemo}) {
    final key = _k('branches', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> saveBranch(Map<String, dynamic> data, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('branches', forDemo: useDemo);
    final list = getBranches(forDemo: useDemo);
    final int nextId = list.isEmpty ? 1 : (list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final newBranch = Map<String, dynamic>.from(data);
    newBranch['id'] = nextId;
    newBranch['created_at'] = DateTime.now().toIso8601String();
    newBranch['is_demo'] = useDemo;
    list.add(newBranch);
    _box.write(key, list);
    return newBranch;
  }

  Map<String, dynamic>? updateBranch(dynamic id, Map<String, dynamic> updates, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('branches', forDemo: useDemo);
    final list = getBranches(forDemo: useDemo);
    final idx = list.indexWhere((b) => b['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write(key, list);
    return updated;
  }

  bool deleteBranch(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('branches', forDemo: useDemo);
    final list = getBranches(forDemo: useDemo);
    final countBefore = list.length;
    list.removeWhere((b) => b['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write(key, list);
      return true;
    }
    return false;
  }

  // ==================== ATTENDANCE ====================
  List<Map<String, dynamic>> getAttendanceRecords({dynamic employeeId, String? date, bool? forDemo}) {
    final key = _k('attendance', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    var list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
    if (employeeId != null) {
      list = list.where((a) => a['employee_id'].toString() == employeeId.toString()).toList();
    }
    if (date != null && date.isNotEmpty) {
      list = list.where((a) => a['date'] == date).toList();
    }
    return list;
  }

  Map<String, dynamic> recordCheckIn({
    required dynamic employeeId,
    required String employeeName,
    double? latitude,
    double? longitude,
    int? session,
    double? similarity,
    bool? forDemo,
  }) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('attendance', forDemo: useDemo);
    final list = _box.read<List>(key) ?? [];
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final int nextId = list.isEmpty ? 1 : list.length + 1;

    // Check if there is already an open record for today
    final existingIdx = list.indexWhere(
      (a) => a['employee_id'].toString() == employeeId.toString() && a['date'] == dateStr && a['check_out_time'] == null,
    );

    final record = {
      'id': nextId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'date': dateStr,
      'check_in_time': now.toIso8601String(),
      'check_out_time': null,
      'status': 'Present',
      'latitude': latitude ?? 11.5564,
      'longitude': longitude ?? 104.9282,
      'session': session ?? 1,
      'similarity': similarity ?? 0.88,
      'is_demo': useDemo,
    };

    if (existingIdx >= 0) {
      list[existingIdx] = record;
    } else {
      list.add(record);
    }

    _box.write(key, list);

    // Sync to SQLite backend
    onSyncHook?.call(
      type: 'attendance',
      payload: {
        'employeeId': employeeId.toString(),
        'employeeName': employeeName,
        'type': 'check-in',
        'time': now.toIso8601String().substring(11, 19),
        'date': dateStr,
        'checkType': 'face',
        'faceMatched': true,
        'confidence': similarity ?? 0.95,
      },
    );

    return record;
  }

  Map<String, dynamic> recordCheckOut({
    required dynamic employeeId,
    required String employeeName,
    double? latitude,
    double? longitude,
    int? session,
    double? similarity,
    bool? forDemo,
  }) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('attendance', forDemo: useDemo);
    final list = _box.read<List>(key) ?? [];
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final existingIdx = list.lastIndexWhere(
      (a) => a['employee_id'].toString() == employeeId.toString() && a['date'] == dateStr,
    );

    Map<String, dynamic> result;
    if (existingIdx >= 0) {
      final updated = Map<String, dynamic>.from(list[existingIdx]);
      updated['check_out_time'] = now.toIso8601String();
      if (latitude != null) updated['out_latitude'] = latitude;
      if (longitude != null) updated['out_longitude'] = longitude;
      list[existingIdx] = updated;
      _box.write(key, list);
      result = updated;
    } else {
      final int nextId = list.isEmpty ? 1 : list.length + 1;
      final record = {
        'id': nextId,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'date': dateStr,
        'check_in_time': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'check_out_time': now.toIso8601String(),
        'status': 'Present',
        'latitude': latitude ?? 11.5564,
        'longitude': longitude ?? 104.9282,
        'session': session ?? 1,
        'similarity': similarity ?? 0.88,
        'is_demo': useDemo,
      };
      list.add(record);
      _box.write(key, list);
      result = record;
    }

    // Sync to SQLite backend
    onSyncHook?.call(
      type: 'attendance',
      payload: {
        'employeeId': employeeId.toString(),
        'employeeName': employeeName,
        'type': 'check-out',
        'time': now.toIso8601String().substring(11, 19),
        'date': dateStr,
        'checkType': 'face',
        'faceMatched': true,
        'confidence': similarity ?? 0.95,
      },
    );

    return result;
  }

  Map<String, dynamic> getAttendanceStatus(dynamic employeeId, {bool? forDemo}) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final records = getAttendanceRecords(employeeId: employeeId, date: dateStr, forDemo: forDemo);

    final isCheckedIn = records.isNotEmpty && records.any((r) => r['check_out_time'] == null);
    final lastRecord = records.isNotEmpty ? records.last : null;

    return {
      'is_checked_in': isCheckedIn,
      'today_date': dateStr,
      'check_in_time': lastRecord?['check_in_time'],
      'check_out_time': lastRecord?['check_out_time'],
      'status': lastRecord?['status'] ?? 'Not Checked In',
    };
  }

  Map<String, dynamic> getMonthlySummary({required int year, required int month, dynamic employeeId, bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = (month >= 1 && month <= 12) ? monthNames[month - 1] : 'Month $month';

    final attendanceRecords = getAttendanceRecords(employeeId: employeeId, forDemo: useDemo);
    final allLeaves = getLeaves(forDemo: useDemo);

    // Map of date strings -> attendance record
    final Map<String, Map<String, dynamic>> recordsByDate = {};
    for (final r in attendanceRecords) {
      final d = r['date']?.toString();
      if (d != null) {
        recordsByDate[d] = r;
      }
    }

    // Default approved demo leaves if user hasn't created leaves yet (ONLY in demo mode)
    final List<Map<String, dynamic>> monthLeaves = [];
    final approvedLeaves = allLeaves.where((l) => (l['status']?.toString().toLowerCase() ?? '') == 'approved').toList();

    if (approvedLeaves.isNotEmpty) {
      for (final l in approvedLeaves) {
        monthLeaves.add(l);
      }
    } else if (useDemo) {
      // Provide realistic demo approved leaves matching absence documentation
      final d3Str = '$year-${month.toString().padLeft(2, '0')}-03';
      final d17Str = '$year-${month.toString().padLeft(2, '0')}-17';
      monthLeaves.addAll([
        {
          'id': 101,
          'leave_type': 'Sick Leave',
          'from_date': d3Str,
          'to_date': d3Str,
          'reason': 'Severe fever and migraine. Visited clinic for checkup and prescribed bed rest.',
          'status': 'approved',
        },
        {
          'id': 102,
          'leave_type': 'Personal Leave',
          'from_date': d17Str,
          'to_date': d17Str,
          'reason': 'Urgent family obligation in hometown. Permission requested in advance.',
          'status': 'approved',
        },
      ]);
    }

    final Map<String, Map<String, dynamic>> calendarDays = {};
    int daysGoal = 0;
    int daysWorked = 0;
    int daysAbsent = 0;
    int daysLeave = 0;
    int daysRemaining = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final dateObj = DateTime(year, month, day);
      final isSunday = dateObj.weekday == DateTime.sunday;

      // Count workdays towards goal (Monday to Saturday)
      if (!isSunday) {
        daysGoal++;
      }

      String status = 'none';
      if (isSunday) {
        status = 'dayOff';
      } else {
        // Check if there is an approved leave
        final hasLeave = monthLeaves.any((l) {
          final from = l['from_date']?.toString();
          final to = l['to_date']?.toString();
          if (from == null || to == null) return false;
          return dateKey.compareTo(from) >= 0 && dateKey.compareTo(to) <= 0;
        });

        if (hasLeave) {
          status = 'leave';
          daysLeave++;
        } else if (recordsByDate.containsKey(dateKey)) {
          final rec = recordsByDate[dateKey]!;
          if (rec['status'] == 'Overtime') {
            status = 'overtime';
          } else {
            status = 'worked';
          }
          daysWorked++;
        } else if (dateObj.isBefore(today)) {
          // Past date with no attendance record and no leave
          if (useDemo && (day == 3 || day == 17)) {
            status = 'absent';
            daysAbsent++;
          } else if (attendanceRecords.isNotEmpty) {
            // User has recorded attendance on some days, so missing days are absent
            status = 'absent';
            daysAbsent++;
          } else if (useDemo) {
            // Fresh / demo mode without records: weekdays default to worked for realistic UX
            status = 'worked';
            daysWorked++;
          } else {
            status = 'none';
          }
        } else if (dateObj.isAtSameMomentAs(today)) {
          // Today: if not checked in yet, it's a workday
          status = 'workday';
          daysRemaining++;
        } else {
          // Future date
          status = 'workday';
          daysRemaining++;
        }
      }

      calendarDays[dateKey] = {
        'status': status,
        'date': dateKey,
        'day': day,
      };
    }

    final scheduleList = [
      {
        'short': 'Mon',
        'full': 'Monday',
        'shifts': [
          {'startHour': 8, 'endHour': 17, 'range': '08:00 AM - 05:00 PM'},
        ],
        'totalHours': 9,
      },
      {
        'short': 'Tue',
        'full': 'Tuesday',
        'shifts': [
          {'startHour': 8, 'endHour': 17, 'range': '08:00 AM - 05:00 PM'},
        ],
        'totalHours': 9,
      },
      {
        'short': 'Wed',
        'full': 'Wednesday',
        'shifts': [
          {'startHour': 8, 'endHour': 17, 'range': '08:00 AM - 05:00 PM'},
        ],
        'totalHours': 9,
      },
      {
        'short': 'Thu',
        'full': 'Thursday',
        'shifts': [
          {'startHour': 8, 'endHour': 17, 'range': '08:00 AM - 05:00 PM'},
        ],
        'totalHours': 9,
      },
      {
        'short': 'Fri',
        'full': 'Friday',
        'shifts': [
          {'startHour': 8, 'endHour': 17, 'range': '08:00 AM - 05:00 PM'},
        ],
        'totalHours': 9,
      },
      {
        'short': 'Sat',
        'full': 'Saturday',
        'shifts': [
          {'startHour': 8, 'endHour': 12, 'range': '08:00 AM - 12:00 PM'},
        ],
        'totalHours': 4,
      },
    ];

    final holidaysList = [
      {
        'short': 'Sun',
        'full': 'Sunday',
        'reason': 'Scheduled Weekly Day Off',
      },
    ];

    final leavesFormatted = monthLeaves.map((l) => {
      'id': l['id'] ?? 1,
      'leave_type': l['leave_type'] ?? 'Leave',
      'from_date': l['from_date'] ?? '',
      'to_date': l['to_date'] ?? '',
      'reason': l['reason'] ?? '',
      'status': l['status'] ?? 'approved',
    }).toList();

    return {
      'days_goal': daysGoal,
      'days_worked': daysWorked,
      'days_absent': daysAbsent,
      'days_leave': daysLeave,
      'absence_limit': 8,
      'on_time_rate': 96,
      'days_remaining': daysRemaining,
      'month_name': monthName,
      'calendar_days': calendarDays,
      'schedule': scheduleList,
      'holidays': holidaysList,
      'leaves': leavesFormatted,
    };
  }

  // ==================== STRICT 3-TIER HIERARCHY & ROUTING ====================

  /// Resolves the strict 3-tier approval chain:
  /// - Employee request -> Leader ONLY (never to Manager or CEO)
  /// - Leader request -> Manager ONLY (never to Leader or CEO)
  /// - Manager request -> CEO ONLY
  /// - CEO request -> No supervisor (returns [])
  List<Map<String, dynamic>> findSupervisorsFor(Map<String, dynamic> employee, {bool? forDemo}) {
    final role = (employee['role'] ?? 'employee').toString().toLowerCase().trim();
    final allEmployees = getEmployees(forDemo: forDemo);
    final empId = employee['id']?.toString() ?? '';

    if (role == 'employee') {
      // 1. Direct supervisor if active and role is leader
      if (employee['reporting_to'] != null) {
        final rep = allEmployees.firstWhereOrNull((e) =>
            e['id']?.toString() == employee['reporting_to']?.toString() &&
            e['status'] != 'inactive' &&
            e['role']?.toString().toLowerCase() == 'leader');
        if (rep != null) return [rep];
      }
      // 2. Leader in same department
      final deptId = employee['department']?.toString() ?? '';
      if (deptId.isNotEmpty) {
        final leader = allEmployees.firstWhereOrNull((e) =>
            e['id']?.toString() != empId &&
            e['status'] != 'inactive' &&
            e['role']?.toString().toLowerCase() == 'leader' &&
            e['department']?.toString() == deptId);
        if (leader != null) return [leader];
      }
      // 3. Leader in same branch
      final branchId = employee['branch']?.toString() ?? '';
      if (branchId.isNotEmpty) {
        final leader = allEmployees.firstWhereOrNull((e) =>
            e['id']?.toString() != empId &&
            e['status'] != 'inactive' &&
            e['role']?.toString().toLowerCase() == 'leader' &&
            e['branch']?.toString() == branchId);
        if (leader != null) return [leader];
      }
      // 4. Any non-inactive leader
      final leader = allEmployees.firstWhereOrNull((e) =>
          e['id']?.toString() != empId &&
          e['status'] != 'inactive' &&
          e['role']?.toString().toLowerCase() == 'leader');
      if (leader != null) return [leader];
      return [];
    } else if (role == 'leader') {
      // 1. Manager in same branch
      final branchId = employee['branch']?.toString() ?? '';
      if (branchId.isNotEmpty) {
        final manager = allEmployees.firstWhereOrNull((e) =>
            e['id']?.toString() != empId &&
            e['status'] != 'inactive' &&
            e['role']?.toString().toLowerCase() == 'manager' &&
            e['branch']?.toString() == branchId);
        if (manager != null) return [manager];
      }
      // 2. Any non-inactive manager
      final manager = allEmployees.firstWhereOrNull((e) =>
          e['id']?.toString() != empId &&
          e['status'] != 'inactive' &&
          e['role']?.toString().toLowerCase() == 'manager');
      if (manager != null) return [manager];
      return [];
    } else if (role == 'manager') {
      // Goes to CEO
      final ceo = allEmployees.firstWhereOrNull((e) =>
          e['id']?.toString() != empId &&
          e['status'] != 'inactive' &&
          (e['role']?.toString().toLowerCase() == 'ceo' || e['role']?.toString().toLowerCase() == 'admin'));
      if (ceo != null) return [ceo];
      return [];
    }
    return [];
  }

  /// Validates strict 3-tier review hierarchy:
  /// - Employee request -> Leader ONLY
  /// - Leader request -> Manager ONLY
  /// - Manager request -> CEO ONLY
  bool canUserReviewRequester(String reviewerRole, String requesterRole) {
    final rev = reviewerRole.toLowerCase().trim();
    final req = requesterRole.toLowerCase().trim();
    if (rev == 'admin') return true;
    if (req == 'employee') return rev == 'leader';
    if (req == 'leader') return rev == 'manager';
    if (req == 'manager') return rev == 'ceo';
    return false;
  }

  // ==================== INCOMING REQUESTS ROUTING ====================

  /// Strict 3-tier incoming requests for reviewer:
  /// - Employee: returns 0 pending
  /// - Leader: pending requests from Employees in department/branch
  /// - Manager: pending requests from Leaders in branch
  /// - CEO: pending requests from Managers
  Map<String, dynamic> getIncomingRequests({
    required String role,
    dynamic employeeId,
    int? branchId,
    int? departmentId,
    bool? forDemo,
  }) {
    final cleanRole = role.toLowerCase().trim();
    if (cleanRole == 'employee') {
      return {
        'role': 'employee',
        'total_pending': 0,
        'leaves': <Map<String, dynamic>>[],
        'overtimes': <Map<String, dynamic>>[],
        'permissions': <Map<String, dynamic>>[],
      };
    }

    final allLeaves = getLeaves(forDemo: forDemo).where((l) => (l['status']?.toString().toLowerCase() ?? '') == 'pending').toList();
    final allOvertimes = getOvertimes(forDemo: forDemo).where((o) => (o['status']?.toString().toLowerCase() ?? '') == 'pending').toList();
    final allPerms = getPermissions(forDemo: forDemo).where((p) => (p['status']?.toString().toLowerCase() ?? '') == 'pending').toList();

    bool isSubordinate(Map<String, dynamic> req) {
      final reqRole = (req['employee_role'] ?? req['role'] ?? 'employee').toString().toLowerCase().trim();
      final reqEmpId = req['employee_id']?.toString() ?? '';
      if (employeeId != null && reqEmpId == employeeId.toString()) return false;

      if (cleanRole == 'leader') {
        // Leader only sees Employee requests
        if (reqRole != 'employee') return false;
        if (departmentId != null && req['department'] != null) {
          return req['department'].toString() == departmentId.toString();
        }
        if (branchId != null && req['branch'] != null) {
          return req['branch'].toString() == branchId.toString();
        }
        return true;
      } else if (cleanRole == 'manager') {
        // Manager only sees Leader requests
        if (reqRole != 'leader') return false;
        if (branchId != null && req['branch'] != null) {
          return req['branch'].toString() == branchId.toString();
        }
        return true;
      } else if (cleanRole == 'ceo' || cleanRole == 'admin') {
        // CEO sees Manager requests (and any unassigned / direct escalation)
        return reqRole == 'manager' || (cleanRole == 'admin');
      }
      return false;
    }

    final pendingLeaves = allLeaves.where(isSubordinate).toList();
    final pendingOvertimes = allOvertimes.where(isSubordinate).toList();
    final pendingPerms = allPerms.where(isSubordinate).toList();

    return {
      'role': cleanRole,
      'total_pending': pendingLeaves.length + pendingOvertimes.length + pendingPerms.length,
      'leaves': pendingLeaves,
      'overtimes': pendingOvertimes,
      'permissions': pendingPerms,
    };
  }

  // ==================== LEAVE REQUESTS ====================

  List<Map<String, dynamic>> getLeaves({dynamic employeeId, String? status, bool? forDemo}) {
    final key = _k('leaves', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    var list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
    if (employeeId != null) {
      list = list.where((l) =>
          l['employee_id']?.toString() == employeeId.toString() ||
          l['employee_uid']?.toString() == employeeId.toString()).toList();
    }
    if (status != null && status.isNotEmpty) {
      list = list.where((l) =>
          (l['status']?.toString().toLowerCase() ?? '') == status.toLowerCase()).toList();
    }
    return list;
  }

  Map<String, dynamic>? getLeaveById(dynamic id, {bool? forDemo}) {
    final list = getLeaves(forDemo: forDemo);
    final idx = list.indexWhere((l) => l['id'].toString() == id.toString());
    return idx >= 0 ? list[idx] : null;
  }

  Map<String, dynamic> addLeave(Map<String, dynamic> data, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('leaves', forDemo: useDemo);
    final list = getLeaves(forDemo: useDemo);
    final int nextId = list.isEmpty ? 1 : list.map((l) => (l['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    item['is_demo'] = useDemo;
    list.add(item);
    _box.write(key, list);

    // Auto-dispatch in-app notification to supervisors
    final supervisors = findSupervisorsFor(item, forDemo: useDemo);
    final empName = item['employee_name'] ?? 'Employee';
    final scheduleLabel = item['day_type'] ?? 'Leave Request';
    for (final sup in supervisors) {
      sendNotification(
        recipientId: sup['id'],
        recipientUid: sup['firebase_uid'],
        title: 'New Leave Request',
        message: '$empName submitted a leave request ($scheduleLabel).',
        notifType: 'leave',
        refId: nextId.toString(),
        senderName: empName,
        senderProfileUrl: item['employee_profile_url'],
        forDemo: useDemo,
      );
    }

    return item;
  }

  Map<String, dynamic>? updateLeave(dynamic id, Map<String, dynamic> updates, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('leaves', forDemo: useDemo);
    final list = getLeaves(forDemo: useDemo);
    final idx = list.indexWhere((l) => l['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write(key, list);
    return updated;
  }

  Map<String, dynamic>? reviewLeave(
    dynamic id, {
    required String status,
    String? reviewerName,
    String? reviewerRole,
    String? reviewNotes,
    bool? forDemo,
  }) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('leaves', forDemo: useDemo);
    final list = getLeaves(forDemo: useDemo);
    final idx = list.indexWhere((l) => l['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updated['status'] = status.toLowerCase();
    if (reviewerName != null) updated['reviewer_name'] = reviewerName;
    if (reviewerRole != null) updated['reviewer_role'] = reviewerRole;
    if (reviewNotes != null) updated['review_notes'] = reviewNotes;
    updated['reviewed_at'] = DateTime.now().toIso8601String();
    list[idx] = updated;
    _box.write(key, list);

    // Auto-dispatch in-app notification to requester
    final rev = reviewerName ?? 'Supervisor';
    final isApprove = status.toLowerCase() == 'approved';
    sendNotification(
      recipientId: updated['employee_id'],
      recipientUid: updated['employee_uid'],
      title: isApprove ? 'Leave Request Approved' : 'Leave Request Rejected',
      message: 'Your leave request has been ${isApprove ? "approved" : "rejected"} by $rev.',
      notifType: 'leave',
      refId: id.toString(),
      senderName: rev,
      forDemo: useDemo,
    );

    return updated;
  }

  Map<String, dynamic>? updateLeaveStatus(dynamic id, String status, {bool? forDemo}) {
    return reviewLeave(id, status: status, reviewerName: 'CEO', reviewerRole: 'CEO', forDemo: forDemo);
  }

  bool deleteLeave(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('leaves', forDemo: useDemo);
    final list = getLeaves(forDemo: useDemo);
    final countBefore = list.length;
    list.removeWhere((l) => l['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write(key, list);
      return true;
    }
    return false;
  }

  // ==================== OVERTIME REQUESTS ====================

  List<Map<String, dynamic>> getOvertimes({dynamic employeeId, String? status, bool? forDemo}) {
    final key = _k('overtimes', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    var list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
    if (employeeId != null) {
      list = list.where((o) =>
          o['employee_id']?.toString() == employeeId.toString() ||
          o['employee_uid']?.toString() == employeeId.toString()).toList();
    }
    if (status != null && status.isNotEmpty) {
      list = list.where((o) =>
          (o['status']?.toString().toLowerCase() ?? '') == status.toLowerCase()).toList();
    }
    return list;
  }

  Map<String, dynamic>? getOvertimeById(dynamic id, {bool? forDemo}) {
    final list = getOvertimes(forDemo: forDemo);
    final idx = list.indexWhere((o) => o['id'].toString() == id.toString());
    return idx >= 0 ? list[idx] : null;
  }

  Map<String, dynamic> addOvertime(Map<String, dynamic> data, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('overtimes', forDemo: useDemo);
    final list = getOvertimes(forDemo: useDemo);
    final int nextId = list.isEmpty ? 1 : list.map((o) => (o['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    item['is_demo'] = useDemo;
    list.add(item);
    _box.write(key, list);

    // Auto-dispatch in-app notification to supervisors
    final supervisors = findSupervisorsFor(item, forDemo: useDemo);
    final empName = item['employee_name'] ?? 'Employee';
    final dateStr = item['date'] ?? 'today';
    for (final sup in supervisors) {
      sendNotification(
        recipientId: sup['id'],
        recipientUid: sup['firebase_uid'],
        title: 'New Overtime Request',
        message: '$empName submitted an overtime request for $dateStr.',
        notifType: 'overtime',
        refId: nextId.toString(),
        senderName: empName,
        senderProfileUrl: item['employee_profile_url'],
        forDemo: useDemo,
      );
    }

    return item;
  }

  Map<String, dynamic>? updateOvertime(dynamic id, Map<String, dynamic> updates, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('overtimes', forDemo: useDemo);
    final list = getOvertimes(forDemo: useDemo);
    final idx = list.indexWhere((o) => o['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write(key, list);
    return updated;
  }

  Map<String, dynamic>? reviewOvertime(
    dynamic id, {
    required String status,
    String? reviewerName,
    String? reviewerRole,
    String? reviewNotes,
    bool? forDemo,
  }) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('overtimes', forDemo: useDemo);
    final list = getOvertimes(forDemo: useDemo);
    final idx = list.indexWhere((o) => o['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updated['status'] = status.toLowerCase();
    if (reviewerName != null) updated['reviewer_name'] = reviewerName;
    if (reviewerRole != null) updated['reviewer_role'] = reviewerRole;
    if (reviewNotes != null) updated['review_notes'] = reviewNotes;
    updated['reviewed_at'] = DateTime.now().toIso8601String();
    list[idx] = updated;
    _box.write(key, list);

    // Auto-dispatch in-app notification to requester
    final rev = reviewerName ?? 'Supervisor';
    final isApprove = status.toLowerCase() == 'approved';
    sendNotification(
      recipientId: updated['employee_id'],
      recipientUid: updated['employee_uid'],
      title: isApprove ? 'Overtime Request Approved' : 'Overtime Request Rejected',
      message: 'Your overtime request has been ${isApprove ? "approved" : "rejected"} by $rev.',
      notifType: 'overtime',
      refId: id.toString(),
      senderName: rev,
      forDemo: useDemo,
    );

    return updated;
  }

  bool deleteOvertime(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('overtimes', forDemo: useDemo);
    final list = getOvertimes(forDemo: useDemo);
    final countBefore = list.length;
    list.removeWhere((o) => o['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write(key, list);
      return true;
    }
    return false;
  }

  // ==================== PERMISSION REQUESTS ====================

  List<Map<String, dynamic>> getPermissions({dynamic employeeId, String? status, bool? forDemo}) {
    final key = _k('permissions', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    var list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
    if (employeeId != null) {
      list = list.where((p) =>
          p['employee_id']?.toString() == employeeId.toString() ||
          p['employee_uid']?.toString() == employeeId.toString()).toList();
    }
    if (status != null && status.isNotEmpty) {
      list = list.where((p) =>
          (p['status']?.toString().toLowerCase() ?? '') == status.toLowerCase()).toList();
    }
    return list;
  }

  Map<String, dynamic>? getPermissionById(dynamic id, {bool? forDemo}) {
    final list = getPermissions(forDemo: forDemo);
    final idx = list.indexWhere((p) => p['id'].toString() == id.toString());
    return idx >= 0 ? list[idx] : null;
  }

  Map<String, dynamic> addPermission(Map<String, dynamic> data, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('permissions', forDemo: useDemo);
    final list = getPermissions(forDemo: useDemo);
    final int nextId = list.isEmpty ? 1 : list.map((p) => (p['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    item['is_demo'] = useDemo;
    list.add(item);
    _box.write(key, list);

    // Auto-dispatch in-app notification to supervisors
    final supervisors = findSupervisorsFor(item, forDemo: useDemo);
    final empName = item['employee_name'] ?? 'Employee';
    final sched = item['schedule_time'] ?? item['schedule'] ?? 'Section';
    final dateStr = item['date'] ?? 'today';
    for (final sup in supervisors) {
      sendNotification(
        recipientId: sup['id'],
        recipientUid: sup['firebase_uid'],
        title: 'New Permission Request',
        message: '$empName submitted a permission request for $sched on $dateStr.',
        notifType: 'permission',
        refId: nextId.toString(),
        senderName: empName,
        senderProfileUrl: item['employee_profile_url'],
        forDemo: useDemo,
      );
    }

    return item;
  }

  Map<String, dynamic>? updatePermission(dynamic id, Map<String, dynamic> updates, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('permissions', forDemo: useDemo);
    final list = getPermissions(forDemo: useDemo);
    final idx = list.indexWhere((p) => p['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write(key, list);
    return updated;
  }

  Map<String, dynamic>? reviewPermission(
    dynamic id, {
    required String status,
    String? reviewerName,
    String? reviewerRole,
    String? reviewNotes,
    bool? forDemo,
  }) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('permissions', forDemo: useDemo);
    final list = getPermissions(forDemo: useDemo);
    final idx = list.indexWhere((p) => p['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updated['status'] = status.toLowerCase();
    if (reviewerName != null) updated['reviewer_name'] = reviewerName;
    if (reviewerRole != null) updated['reviewer_role'] = reviewerRole;
    if (reviewNotes != null) updated['review_notes'] = reviewNotes;
    updated['reviewed_at'] = DateTime.now().toIso8601String();
    list[idx] = updated;
    _box.write(key, list);

    // Auto-dispatch in-app notification to requester
    final rev = reviewerName ?? 'Supervisor';
    final isApprove = status.toLowerCase() == 'approved';
    sendNotification(
      recipientId: updated['employee_id'],
      recipientUid: updated['employee_uid'],
      title: isApprove ? 'Permission Request Approved' : 'Permission Request Rejected',
      message: 'Your permission request has been ${isApprove ? "approved" : "rejected"} by $rev.',
      notifType: 'permission',
      refId: id.toString(),
      senderName: rev,
      forDemo: useDemo,
    );

    return updated;
  }

  bool deletePermission(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('permissions', forDemo: useDemo);
    final list = getPermissions(forDemo: useDemo);
    final countBefore = list.length;
    list.removeWhere((p) => p['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write(key, list);
      return true;
    }
    return false;
  }

  // ==================== SUGGESTIONS (ANONYMOUS & ROLE-FILTERED) ====================

  List<Map<String, dynamic>> getSuggestions({bool? forDemo}) {
    final key = _k('suggestions', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic>? getSuggestionById(dynamic id, {bool? forDemo}) {
    final list = getSuggestions(forDemo: forDemo);
    final idx = list.indexWhere((s) => s['id'].toString() == id.toString());
    return idx >= 0 ? list[idx] : null;
  }

  /// Returns suggestions according to role hierarchy:
  /// - CEO: sees all suggestions
  /// - Manager: sees suggestions from branch staff (employees/leaders) + own
  /// - Employee & Leader: see only their own suggestions
  List<Map<String, dynamic>> getSuggestionsForRole(
    String role, {
    dynamic employeeId,
    int? branchId,
    String? statusFilter,
    bool? forDemo,
  }) {
    final cleanRole = role.toLowerCase().trim();
    final all = getSuggestions(forDemo: forDemo);
    var list = <Map<String, dynamic>>[];

    if (cleanRole == 'ceo' || cleanRole == 'admin') {
      list = all;
    } else if (cleanRole == 'manager') {
      list = all.where((s) {
        if (employeeId != null && s['employee_id']?.toString() == employeeId.toString()) return true;
        final sRole = (s['employee_role'] ?? 'employee').toString().toLowerCase();
        if (branchId != null && s['branch'] != null) {
          return (sRole == 'employee' || sRole == 'leader') && s['branch'].toString() == branchId.toString();
        }
        return sRole == 'employee' || sRole == 'leader';
      }).toList();
    } else {
      // Regular staff see only their own suggestions
      if (employeeId != null) {
        list = all.where((s) => s['employee_id']?.toString() == employeeId.toString()).toList();
      } else {
        list = all;
      }
    }

    if (statusFilter == 'pending') {
      list = list.where((s) => s['is_read'] != true).toList();
    } else if (statusFilter == 'seen') {
      list = list.where((s) => s['is_read'] == true).toList();
    }

    return list;
  }

  Map<String, dynamic> addSuggestion(Map<String, dynamic> data, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('suggestions', forDemo: useDemo);
    final list = getSuggestions(forDemo: useDemo);
    final int nextId = list.isEmpty ? 1 : list.map((s) => (s['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['is_read'] = false;
    item['is_anonymous'] = true; // Always anonymous
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    item['is_demo'] = useDemo;
    list.add(item);
    _box.write(key, list);

    // Notify routing:
    // Strictly CEO and Managers (NEVER Leader or Employee)
    final allEmployees = getEmployees(forDemo: useDemo);
    final userRole = (item['employee_role'] ?? 'employee').toString().toLowerCase();
    final userId = item['employee_id']?.toString() ?? '';

    List<Map<String, dynamic>> recipients = [];
    if (userRole == 'manager') {
      // Notify CEO only
      recipients = allEmployees.where((e) =>
          e['status'] != 'inactive' &&
          e['id']?.toString() != userId &&
          (e['role']?.toString().toLowerCase() == 'ceo' || e['role']?.toString().toLowerCase() == 'admin')).toList();
    } else {
      // Notify CEO and Managers
      recipients = allEmployees.where((e) =>
          e['status'] != 'inactive' &&
          e['id']?.toString() != userId &&
          ['ceo', 'admin', 'manager'].contains(e['role']?.toString().toLowerCase())).toList();
    }

    final msgSnippet = (item['content'] ?? item['message'] ?? '').toString();
    final preview = msgSnippet.length > 80 ? '${msgSnippet.substring(0, 80)}...' : msgSnippet;

    for (final r in recipients) {
      sendNotification(
        recipientId: r['id'],
        recipientUid: r['firebase_uid'],
        title: 'New Suggestion Submitted',
        message: 'Anonymous Suggestion: $preview',
        notifType: 'suggestion',
        refId: nextId.toString(),
        senderName: 'Anonymous',
        forDemo: useDemo,
      );
    }

    return item;
  }

  void markSuggestionRead(dynamic id, {String? readByName, bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('suggestions', forDemo: useDemo);
    final list = getSuggestions(forDemo: useDemo);
    final idx = list.indexWhere((s) => s['id'].toString() == id.toString());
    if (idx >= 0) {
      list[idx]['is_read'] = true;
      if (readByName != null) list[idx]['read_by_name'] = readByName;
      list[idx]['read_at'] = DateTime.now().toIso8601String();
      _box.write(key, list);
    }
  }

  bool deleteSuggestion(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('suggestions', forDemo: useDemo);
    final list = getSuggestions(forDemo: useDemo);
    final countBefore = list.length;
    list.removeWhere((s) => s['id'].toString() == id.toString() && s['is_read'] != true);
    if (list.length < countBefore) {
      _box.write(key, list);
      return true;
    }
    return false;
  }

  // ==================== IN-APP NOTIFICATIONS ====================

  Map<String, dynamic> sendNotification({
    required dynamic recipientId,
    String? recipientUid,
    required String title,
    required String message,
    String notifType = 'general',
    String refId = '',
    String senderName = 'System',
    String? senderProfileUrl,
    bool? forDemo,
  }) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('notifications', forDemo: useDemo);
    final list = _box.read<List>(key) ?? [];
    final int nextId = list.isEmpty ? 1 : list.map((n) => (n['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final notif = {
      'id': nextId,
      'recipient_id': recipientId?.toString(),
      'recipient_uid': recipientUid,
      'title': title,
      'message': message,
      'notif_type': notifType,
      'ref_id': refId,
      'sender_name': senderName,
      'sender_profile_url': senderProfileUrl,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'is_demo': useDemo,
    };
    list.add(notif);
    _box.write(key, list);
    return notif;
  }

  List<Map<String, dynamic>> getNotifications({dynamic employeeId, String? firebaseUid, bool? forDemo}) {
    final key = _k('notifications', forDemo: forDemo);
    final raw = _box.read<List>(key) ?? [];
    var list = raw.map((e) => Map<String, dynamic>.from(e)).toList();

    if (employeeId != null || (firebaseUid != null && firebaseUid.isNotEmpty)) {
      list = list.where((n) {
        final rId = n['recipient_id']?.toString();
        final rUid = n['recipient_uid']?.toString();
        // System wide notifications (null recipient) or targeted to user
        if (rId == null && rUid == null) return true;
        if (employeeId != null && rId == employeeId.toString()) return true;
        if (firebaseUid != null && rUid == firebaseUid) return true;
        return false;
      }).toList();
    }

    return list;
  }

  void markNotificationRead(dynamic id, {bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('notifications', forDemo: useDemo);
    final list = _box.read<List>(key) ?? [];
    final idx = list.indexWhere((n) => n['id'].toString() == id.toString());
    if (idx >= 0) {
      list[idx]['is_read'] = true;
      _box.write(key, list);
    }
  }

  void markAllNotificationsReadForUser({dynamic employeeId, String? firebaseUid, bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('notifications', forDemo: useDemo);
    final list = _box.read<List>(key) ?? [];
    for (var n in list) {
      final rId = n['recipient_id']?.toString();
      final rUid = n['recipient_uid']?.toString();
      final forUser = (rId == null && rUid == null) ||
          (employeeId != null && rId == employeeId.toString()) ||
          (firebaseUid != null && rUid == firebaseUid);
      if (forUser) {
        n['is_read'] = true;
      }
    }
    _box.write(key, list);
  }

  void markAllNotificationsRead({bool? forDemo}) {
    final useDemo = forDemo ?? isDemoMode;
    final key = _k('notifications', forDemo: useDemo);
    final list = _box.read<List>(key) ?? [];
    for (var n in list) {
      n['is_read'] = true;
    }
    _box.write(key, list);
  }
}

