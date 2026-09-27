import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:face_recognition_attendance/core/services/sqlite_sync_service.dart';
import 'package:face_recognition_attendance/core/utils/image_compressor.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';
import 'package:get_storage/get_storage.dart';

/// Standalone Cross-Platform Local Database Service.
/// Completely replaces Django REST backend and Firestore database.
/// Uses GetStorage for instantaneous, synchronous key-value persistence
/// across Web, Android, iOS, Windows, macOS, and Linux.
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  late GetStorage _box;
  bool _isInitialized = false;

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
      if (incomingEmps.isNotEmpty) {
        _box.write('employees', incomingEmps);
      }
    }

    if (data.containsKey('persons') && data['persons'] is List) {
      final incomingPersons = (data['persons'] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      if (incomingPersons.isNotEmpty) {
        _box.write('persons', incomingPersons);
      }
    }

    if (data.containsKey('attendance') && data['attendance'] is List) {
      final incomingAtt = (data['attendance'] as List)
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList();
      if (incomingAtt.isNotEmpty) {
        _box.write('attendance', incomingAtt);
      }
    }

    if (data.containsKey('leaves') && data['leaves'] is List) {
      final incomingLeaves = (data['leaves'] as List)
          .map((l) => Map<String, dynamic>.from(l as Map))
          .toList();
      if (incomingLeaves.isNotEmpty) {
        _box.write('leaves', incomingLeaves);
      }
    }

    if (data.containsKey('overtimes') && data['overtimes'] is List) {
      final incomingOt = (data['overtimes'] as List)
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();
      if (incomingOt.isNotEmpty) {
        _box.write('overtimes', incomingOt);
      }
    }

    if (data.containsKey('permissions') && data['permissions'] is List) {
      final incomingPerm = (data['permissions'] as List)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      if (incomingPerm.isNotEmpty) {
        _box.write('permissions', incomingPerm);
      }
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
      SqliteSyncService().syncProfilePicture(
        email: cleanEmail,
        profilePictureBase64: updates['profile_picture'].toString(),
      );
    }
  }

  Map<String, dynamic>? getUserAccountData(String email) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    final vault = _getUserVault();
    return vault[cleanEmail];
  }

  void _seedDefaultDataIfEmpty() {
    // 1. Seed Branches
    if (_box.read('branches') == null) {
      _box.write('branches', [
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

    // 2. Seed Departments
    if (_box.read('departments') == null) {
      _box.write('departments', [
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

    // 3. Seed Employees
    if (_box.read('employees') == null) {
      _box.write('employees', [
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

    // 4. Seed Registered Biometric Persons
    if (_box.read('persons') == null) {
      _box.write('persons', []);
    }

    // 5. Seed Attendance
    if (_box.read('attendance') == null) {
      _box.write('attendance', []);
    }

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final monthStartStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-03';

    // 6. Seed Leaves
    final existingLeaves = _box.read<List>('leaves');
    if (existingLeaves == null || existingLeaves.isEmpty) {
      _box.write('leaves', [
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

    // 7. Seed Overtime
    final existingOvertimes = _box.read<List>('overtimes');
    if (existingOvertimes == null || existingOvertimes.isEmpty) {
      _box.write('overtimes', [
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

    // 8. Seed Permissions
    final existingPerms = _box.read<List>('permissions');
    if (existingPerms == null || existingPerms.isEmpty) {
      _box.write('permissions', [
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

    // 9. Seed Suggestions
    final existingSuggestions = _box.read<List>('suggestions');
    if (existingSuggestions == null || existingSuggestions.isEmpty) {
      _box.write('suggestions', [
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

    // 10. Seed Notifications
    final existingNotifs = _box.read<List>('notifications');
    if (existingNotifs == null || existingNotifs.isEmpty) {
      _box.write('notifications', [
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
  }

  /// Ensures demo accounts always exist and have their exact specified roles,
  /// even if local storage already has existing/cached entries.
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
      },
    ];

    final raw = _box.read<List>('employees');
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

    _box.write('employees', employees);
  }

  // ==================== PERSONS (BIOMETRICS) ====================
  List<Person>? _cachedPersons;

  List<Person> getPersons() {
    if (_cachedPersons != null) return _cachedPersons!;
    final raw = _box.read<List>('persons') ?? [];
    final persons = raw.map((e) => Person.fromMap(Map<String, dynamic>.from(e))).toList();

    // Two-way self-healing auto-recovery between 'persons' and 'employees'
    final rawEmp = _box.read<List>('employees') ?? [];
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
      _box.write('persons', persons.map((p) => p.toMap()).toList());
    }
    if (updatedEmployees) {
      _box.write('employees', empList);
    }

    _cachedPersons = persons;
    return _cachedPersons!;
  }

  void savePerson(Person person) {
    _cachedPersons = null;

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

    final list = _box.read<List>('persons') ?? [];
    final existingIndex = list.indexWhere((p) => p['id'] == optimizedPerson.id || p['employeeId'] == optimizedPerson.employeeId);
    if (existingIndex >= 0) {
      list[existingIndex] = optimizedPerson.toMap();
    } else {
      list.add(optimizedPerson.toMap());
    }
    _box.write('persons', list);

    // Save directly to the account in 'employees' storage and vault
    final rawEmp = _box.read<List>('employees') ?? [];
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
      _box.write('employees', empList);

      final email = empList[empIdx]['email']?.toString();
      if (email != null && email.isNotEmpty) {
        saveUserAccountData(email, {
          'has_face_registered': true,
          'face_templates': optimizedPerson.templates,
          'face_jpg': base64Encode(optimizedPerson.faceJpg),
          'face_registered_at': optimizedPerson.enrolledAt.toIso8601String(),
        });

        // Mirror directly to SQLite database backend
        SqliteSyncService().syncFaceRegistration(
          email: email,
          uid: optimizedPerson.id,
          employeeId: optimizedPerson.employeeId,
          name: optimizedPerson.name,
          templates: optimizedPerson.templates,
          referenceImage: base64Encode(optimizedPerson.faceJpg),
        );
      }
    }
  }

  void deletePerson(String id) {
    _cachedPersons = null;
    final list = _box.read<List>('persons') ?? [];
    list.removeWhere((p) => p['id'] == id || p['employeeId'] == id);
    _box.write('persons', list);

    // Clear face biometrics from the employee account
    final rawEmp = _box.read<List>('employees') ?? [];
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
      _box.write('employees', empList);
    }
  }

  // ==================== EMPLOYEES ====================
  List<Map<String, dynamic>> getEmployees() {
    final raw = _box.read<List>('employees') ?? [];
    final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final personList = _cachedPersons ?? (
      (_box.read<List>('persons') ?? []).map((e) => Person.fromMap(Map<String, dynamic>.from(e as Map))).toList()
    );
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

  Map<String, dynamic>? getEmployeeByEmail(String email) {
    final target = email.toLowerCase().trim();
    final list = getEmployees();
    for (final e in list) {
      final empEmail = e['email']?.toString().toLowerCase().trim();
      if (empEmail == target) return e;
    }
    return null;
  }

  Map<String, dynamic>? getEmployeeByUid(String uid) {
    final target = uid.trim();
    final list = getEmployees();
    for (final e in list) {
      if (e['firebase_uid']?.toString() == target ||
          e['id']?.toString() == target ||
          e['employee_id']?.toString() == target) {
        return e;
      }
    }
    return null;
  }

  Map<String, dynamic> saveEmployee(Map<String, dynamic> data) {
    final list = getEmployees();
    final int nextId = list.isEmpty ? 1 : (list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final newEmp = Map<String, dynamic>.from(data);
    newEmp['id'] = nextId;
    if (newEmp['employee_id'] == null || newEmp['employee_id'].toString().isEmpty) {
      newEmp['employee_id'] = 'EMP-${nextId.toString().padLeft(3, '0')}';
    }
    if (newEmp['firebase_uid'] == null || newEmp['firebase_uid'].toString().isEmpty) {
      newEmp['firebase_uid'] = 'local_uid_${newEmp['employee_id']}';
    }
    newEmp['created_at'] = DateTime.now().toIso8601String();
    list.add(newEmp);
    _box.write('employees', list);
    return newEmp;
  }

  Map<String, dynamic>? updateEmployee(dynamic id, Map<String, dynamic> updates) {
    final list = getEmployees();
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
    _box.write('employees', list);

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

  bool deleteEmployee(dynamic id) {
    final list = getEmployees();
    final countBefore = list.length;
    list.removeWhere((e) => e['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write('employees', list);
      return true;
    }
    return false;
  }

  // ==================== DEPARTMENTS ====================
  List<Map<String, dynamic>> getDepartments() {
    final raw = _box.read<List>('departments') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> saveDepartment(Map<String, dynamic> data) {
    final list = getDepartments();
    final int nextId = list.isEmpty ? 1 : (list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final newDept = Map<String, dynamic>.from(data);
    newDept['id'] = nextId;
    newDept['employee_count'] = newDept['employee_count'] ?? 0;
    newDept['created_at'] = DateTime.now().toIso8601String();
    list.add(newDept);
    _box.write('departments', list);
    return newDept;
  }

  Map<String, dynamic>? updateDepartment(dynamic id, Map<String, dynamic> updates) {
    final list = getDepartments();
    final idx = list.indexWhere((d) => d['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write('departments', list);
    return updated;
  }

  bool deleteDepartment(dynamic id) {
    final list = getDepartments();
    final countBefore = list.length;
    list.removeWhere((d) => d['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write('departments', list);
      return true;
    }
    return false;
  }

  // ==================== BRANCHES ====================
  List<Map<String, dynamic>> getBranches() {
    final raw = _box.read<List>('branches') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> saveBranch(Map<String, dynamic> data) {
    final list = getBranches();
    final int nextId = list.isEmpty ? 1 : (list.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final newBranch = Map<String, dynamic>.from(data);
    newBranch['id'] = nextId;
    newBranch['created_at'] = DateTime.now().toIso8601String();
    list.add(newBranch);
    _box.write('branches', list);
    return newBranch;
  }

  Map<String, dynamic>? updateBranch(dynamic id, Map<String, dynamic> updates) {
    final list = getBranches();
    final idx = list.indexWhere((b) => b['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write('branches', list);
    return updated;
  }

  bool deleteBranch(dynamic id) {
    final list = getBranches();
    final countBefore = list.length;
    list.removeWhere((b) => b['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write('branches', list);
      return true;
    }
    return false;
  }

  // ==================== ATTENDANCE ====================
  List<Map<String, dynamic>> getAttendanceRecords({dynamic employeeId, String? date}) {
    final raw = _box.read<List>('attendance') ?? [];
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
  }) {
    final list = _box.read<List>('attendance') ?? [];
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
    };

    if (existingIdx >= 0) {
      list[existingIdx] = record;
    } else {
      list.add(record);
    }

    _box.write('attendance', list);

    // Sync to SQLite backend
    SqliteSyncService().syncAttendance(
      employeeId: employeeId.toString(),
      employeeName: employeeName,
      type: 'check-in',
      time: now.toIso8601String().substring(11, 19),
      date: dateStr,
      checkType: 'face',
      faceMatched: true,
      confidence: similarity ?? 0.95,
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
  }) {
    final list = _box.read<List>('attendance') ?? [];
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
      _box.write('attendance', list);
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
      };
      list.add(record);
      _box.write('attendance', list);
      result = record;
    }

    // Sync to SQLite backend
    SqliteSyncService().syncAttendance(
      employeeId: employeeId.toString(),
      employeeName: employeeName,
      type: 'check-out',
      time: now.toIso8601String().substring(11, 19),
      date: dateStr,
      checkType: 'face',
      faceMatched: true,
      confidence: similarity ?? 0.95,
    );

    return result;
  }

  Map<String, dynamic> getAttendanceStatus(dynamic employeeId) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final records = getAttendanceRecords(employeeId: employeeId, date: dateStr);

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

  Map<String, dynamic> getMonthlySummary({required int year, required int month, dynamic employeeId}) {
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

    final attendanceRecords = getAttendanceRecords(employeeId: employeeId);
    final allLeaves = getLeaves();

    // Map of date strings -> attendance record
    final Map<String, Map<String, dynamic>> recordsByDate = {};
    for (final r in attendanceRecords) {
      final d = r['date']?.toString();
      if (d != null) {
        recordsByDate[d] = r;
      }
    }

    // Default approved demo leaves if user hasn't created leaves yet
    final List<Map<String, dynamic>> monthLeaves = [];
    final approvedLeaves = allLeaves.where((l) => (l['status']?.toString().toLowerCase() ?? '') == 'approved').toList();

    if (approvedLeaves.isNotEmpty) {
      for (final l in approvedLeaves) {
        monthLeaves.add(l);
      }
    } else {
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
          if (day == 3 || day == 17) {
            status = 'absent';
            daysAbsent++;
          } else if (attendanceRecords.isNotEmpty) {
            // User has recorded attendance on some days, so missing days are absent
            status = 'absent';
            daysAbsent++;
          } else {
            // Fresh / demo mode without records: weekdays default to worked for realistic UX
            status = 'worked';
            daysWorked++;
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
  List<Map<String, dynamic>> findSupervisorsFor(Map<String, dynamic> employee) {
    final role = (employee['role'] ?? 'employee').toString().toLowerCase().trim();
    final allEmployees = getEmployees();
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

    final allLeaves = getLeaves().where((l) => (l['status']?.toString().toLowerCase() ?? '') == 'pending').toList();
    final allOvertimes = getOvertimes().where((o) => (o['status']?.toString().toLowerCase() ?? '') == 'pending').toList();
    final allPerms = getPermissions().where((p) => (p['status']?.toString().toLowerCase() ?? '') == 'pending').toList();

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

  List<Map<String, dynamic>> getLeaves({dynamic employeeId, String? status}) {
    final raw = _box.read<List>('leaves') ?? [];
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

  Map<String, dynamic>? getLeaveById(dynamic id) {
    final list = getLeaves();
    final idx = list.indexWhere((l) => l['id'].toString() == id.toString());
    return idx >= 0 ? list[idx] : null;
  }

  Map<String, dynamic> addLeave(Map<String, dynamic> data) {
    final list = getLeaves();
    final int nextId = list.isEmpty ? 1 : list.map((l) => (l['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    list.add(item);
    _box.write('leaves', list);

    // Auto-dispatch in-app notification to supervisors
    final supervisors = findSupervisorsFor(item);
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
      );
    }

    return item;
  }

  Map<String, dynamic>? updateLeave(dynamic id, Map<String, dynamic> updates) {
    final list = getLeaves();
    final idx = list.indexWhere((l) => l['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write('leaves', list);
    return updated;
  }

  Map<String, dynamic>? reviewLeave(
    dynamic id, {
    required String status,
    String? reviewerName,
    String? reviewerRole,
    String? reviewNotes,
  }) {
    final list = getLeaves();
    final idx = list.indexWhere((l) => l['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updated['status'] = status.toLowerCase();
    if (reviewerName != null) updated['reviewer_name'] = reviewerName;
    if (reviewerRole != null) updated['reviewer_role'] = reviewerRole;
    if (reviewNotes != null) updated['review_notes'] = reviewNotes;
    updated['reviewed_at'] = DateTime.now().toIso8601String();
    list[idx] = updated;
    _box.write('leaves', list);

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
    );

    return updated;
  }

  Map<String, dynamic>? updateLeaveStatus(dynamic id, String status) {
    return reviewLeave(id, status: status, reviewerName: 'CEO', reviewerRole: 'CEO');
  }

  bool deleteLeave(dynamic id) {
    final list = getLeaves();
    final countBefore = list.length;
    list.removeWhere((l) => l['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write('leaves', list);
      return true;
    }
    return false;
  }

  // ==================== OVERTIME REQUESTS ====================

  List<Map<String, dynamic>> getOvertimes({dynamic employeeId, String? status}) {
    final raw = _box.read<List>('overtimes') ?? [];
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

  Map<String, dynamic>? getOvertimeById(dynamic id) {
    final list = getOvertimes();
    final idx = list.indexWhere((o) => o['id'].toString() == id.toString());
    return idx >= 0 ? list[idx] : null;
  }

  Map<String, dynamic> addOvertime(Map<String, dynamic> data) {
    final list = getOvertimes();
    final int nextId = list.isEmpty ? 1 : list.map((o) => (o['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    list.add(item);
    _box.write('overtimes', list);

    // Auto-dispatch in-app notification to supervisors
    final supervisors = findSupervisorsFor(item);
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
      );
    }

    return item;
  }

  Map<String, dynamic>? updateOvertime(dynamic id, Map<String, dynamic> updates) {
    final list = getOvertimes();
    final idx = list.indexWhere((o) => o['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write('overtimes', list);
    return updated;
  }

  Map<String, dynamic>? reviewOvertime(
    dynamic id, {
    required String status,
    String? reviewerName,
    String? reviewerRole,
    String? reviewNotes,
  }) {
    final list = getOvertimes();
    final idx = list.indexWhere((o) => o['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updated['status'] = status.toLowerCase();
    if (reviewerName != null) updated['reviewer_name'] = reviewerName;
    if (reviewerRole != null) updated['reviewer_role'] = reviewerRole;
    if (reviewNotes != null) updated['review_notes'] = reviewNotes;
    updated['reviewed_at'] = DateTime.now().toIso8601String();
    list[idx] = updated;
    _box.write('overtimes', list);

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
    );

    return updated;
  }

  bool deleteOvertime(dynamic id) {
    final list = getOvertimes();
    final countBefore = list.length;
    list.removeWhere((o) => o['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write('overtimes', list);
      return true;
    }
    return false;
  }

  // ==================== PERMISSION REQUESTS ====================

  List<Map<String, dynamic>> getPermissions({dynamic employeeId, String? status}) {
    final raw = _box.read<List>('permissions') ?? [];
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

  Map<String, dynamic>? getPermissionById(dynamic id) {
    final list = getPermissions();
    final idx = list.indexWhere((p) => p['id'].toString() == id.toString());
    return idx >= 0 ? list[idx] : null;
  }

  Map<String, dynamic> addPermission(Map<String, dynamic> data) {
    final list = getPermissions();
    final int nextId = list.isEmpty ? 1 : list.map((p) => (p['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    list.add(item);
    _box.write('permissions', list);

    // Auto-dispatch in-app notification to supervisors
    final supervisors = findSupervisorsFor(item);
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
      );
    }

    return item;
  }

  Map<String, dynamic>? updatePermission(dynamic id, Map<String, dynamic> updates) {
    final list = getPermissions();
    final idx = list.indexWhere((p) => p['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write('permissions', list);
    return updated;
  }

  Map<String, dynamic>? reviewPermission(
    dynamic id, {
    required String status,
    String? reviewerName,
    String? reviewerRole,
    String? reviewNotes,
  }) {
    final list = getPermissions();
    final idx = list.indexWhere((p) => p['id'].toString() == id.toString());
    if (idx < 0) return null;
    final updated = Map<String, dynamic>.from(list[idx]);
    updated['status'] = status.toLowerCase();
    if (reviewerName != null) updated['reviewer_name'] = reviewerName;
    if (reviewerRole != null) updated['reviewer_role'] = reviewerRole;
    if (reviewNotes != null) updated['review_notes'] = reviewNotes;
    updated['reviewed_at'] = DateTime.now().toIso8601String();
    list[idx] = updated;
    _box.write('permissions', list);

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
    );

    return updated;
  }

  bool deletePermission(dynamic id) {
    final list = getPermissions();
    final countBefore = list.length;
    list.removeWhere((p) => p['id'].toString() == id.toString());
    if (list.length < countBefore) {
      _box.write('permissions', list);
      return true;
    }
    return false;
  }

  // ==================== SUGGESTIONS (ANONYMOUS & ROLE-FILTERED) ====================

  List<Map<String, dynamic>> getSuggestions() {
    final raw = _box.read<List>('suggestions') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic>? getSuggestionById(dynamic id) {
    final list = getSuggestions();
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
  }) {
    final cleanRole = role.toLowerCase().trim();
    final all = getSuggestions();
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

  Map<String, dynamic> addSuggestion(Map<String, dynamic> data) {
    final list = getSuggestions();
    final int nextId = list.isEmpty ? 1 : list.map((s) => (s['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['is_read'] = false;
    item['is_anonymous'] = true; // Always anonymous
    item['created_at'] = item['created_at'] ?? DateTime.now().toIso8601String();
    list.add(item);
    _box.write('suggestions', list);

    // Notify routing:
    // Strictly CEO and Managers (NEVER Leader or Employee)
    final allEmployees = getEmployees();
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
      );
    }

    return item;
  }

  void markSuggestionRead(dynamic id, {String? readByName}) {
    final list = getSuggestions();
    final idx = list.indexWhere((s) => s['id'].toString() == id.toString());
    if (idx >= 0) {
      list[idx]['is_read'] = true;
      if (readByName != null) list[idx]['read_by_name'] = readByName;
      list[idx]['read_at'] = DateTime.now().toIso8601String();
      _box.write('suggestions', list);
    }
  }

  bool deleteSuggestion(dynamic id) {
    final list = getSuggestions();
    final countBefore = list.length;
    list.removeWhere((s) => s['id'].toString() == id.toString() && s['is_read'] != true);
    if (list.length < countBefore) {
      _box.write('suggestions', list);
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
  }) {
    final list = _box.read<List>('notifications') ?? [];
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
    };
    list.add(notif);
    _box.write('notifications', list);
    return notif;
  }

  List<Map<String, dynamic>> getNotifications({dynamic employeeId, String? firebaseUid}) {
    final raw = _box.read<List>('notifications') ?? [];
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

  void markNotificationRead(dynamic id) {
    final list = _box.read<List>('notifications') ?? [];
    final idx = list.indexWhere((n) => n['id'].toString() == id.toString());
    if (idx >= 0) {
      list[idx]['is_read'] = true;
      _box.write('notifications', list);
    }
  }

  void markAllNotificationsReadForUser({dynamic employeeId, String? firebaseUid}) {
    final list = _box.read<List>('notifications') ?? [];
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
    _box.write('notifications', list);
  }

  void markAllNotificationsRead() {
    final list = _box.read<List>('notifications') ?? [];
    for (var n in list) {
      n['is_read'] = true;
    }
    _box.write('notifications', list);
  }
}

