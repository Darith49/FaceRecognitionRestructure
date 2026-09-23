import 'dart:math';
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

    // 6. Seed Leaves
    if (_box.read('leaves') == null) {
      _box.write('leaves', []);
    }

    // 7. Seed Overtime
    if (_box.read('overtimes') == null) {
      _box.write('overtimes', []);
    }

    // 8. Seed Suggestions
    if (_box.read('suggestions') == null) {
      _box.write('suggestions', [
        {
          'id': 1,
          'title': 'Coffee Machine in Breakroom',
          'content': 'Would be great to add an espresso coffee maker on the 2nd floor.',
          'type': 'Facility',
          'is_read': false,
          'employee_name': 'Alex Developer',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        }
      ]);
    }

    // 9. Seed Notifications
    if (_box.read('notifications') == null) {
      _box.write('notifications', [
        {
          'id': 1,
          'title': 'Welcome to Face Attendance App',
          'message': 'System now operates completely on-device with zero backend dependencies.',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'type': 'system',
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

    for (final demo in demoDefs) {
      final idx = employees.indexWhere((e) =>
          e['email']?.toString().toLowerCase().trim() == demo['email']?.toString().toLowerCase().trim());
      if (idx != -1) {
        employees[idx]['role'] = demo['role'];
        employees[idx]['fullname'] = demo['fullname'];
        employees[idx]['employee_id'] = demo['employee_id'];
        employees[idx]['branch'] ??= demo['branch'];
        employees[idx]['branch_name'] ??= demo['branch_name'];
        employees[idx]['department'] ??= demo['department'];
        employees[idx]['department_name'] ??= demo['department_name'];
        employees[idx]['status'] = 'active';
      } else {
        int nextId = 1;
        if (employees.isNotEmpty) {
          nextId = employees.map((e) => (e['id'] as num?)?.toInt() ?? 0).reduce(max) + 1;
        }
        employees.add({
          'id': nextId,
          'section1_start': '08:00:00',
          'section1_end': '12:00:00',
          'section2_start': '13:00:00',
          'section2_end': '17:00:00',
          'work_days': 'mon,tue,wed,thu,fri',
          'created_by': 'system',
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'profile_picture': null,
          ...demo,
        });
      }
    }

    _box.write('employees', employees);
  }

  // ==================== PERSONS (BIOMETRICS) ====================
  List<Person> getPersons() {
    final raw = _box.read<List>('persons') ?? [];
    return raw.map((e) => Person.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  void savePerson(Person person) {
    final list = _box.read<List>('persons') ?? [];
    final existingIndex = list.indexWhere((p) => p['id'] == person.id || p['employeeId'] == person.employeeId);
    if (existingIndex >= 0) {
      list[existingIndex] = person.toMap();
    } else {
      list.add(person.toMap());
    }
    _box.write('persons', list);
  }

  void deletePerson(String id) {
    final list = _box.read<List>('persons') ?? [];
    list.removeWhere((p) => p['id'] == id || p['employeeId'] == id);
    _box.write('persons', list);
  }

  // ==================== EMPLOYEES ====================
  List<Map<String, dynamic>> getEmployees() {
    final raw = _box.read<List>('employees') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic>? getEmployeeByEmail(String email) {
    final list = getEmployees();
    try {
      return list.firstWhere(
        (e) => (e['email'] as String).toLowerCase() == email.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getEmployeeByUid(String uid) {
    final list = getEmployees();
    try {
      return list.firstWhere(
        (e) => e['firebase_uid'] == uid || e['id'].toString() == uid || e['employee_id'] == uid,
      );
    } catch (_) {
      return null;
    }
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
    updates.forEach((k, v) => updated[k] = v);
    list[idx] = updated;
    _box.write('employees', list);
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

    if (existingIdx >= 0) {
      final updated = Map<String, dynamic>.from(list[existingIdx]);
      updated['check_out_time'] = now.toIso8601String();
      if (latitude != null) updated['out_latitude'] = latitude;
      if (longitude != null) updated['out_longitude'] = longitude;
      list[existingIdx] = updated;
      _box.write('attendance', list);
      return updated;
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
      return record;
    }
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

  // ==================== REQUESTS (LEAVE, OVERTIME, PERMISSIONS) ====================
  List<Map<String, dynamic>> getLeaves() {
    final raw = _box.read<List>('leaves') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> addLeave(Map<String, dynamic> data) {
    final list = getLeaves();
    final int nextId = list.isEmpty ? 1 : list.length + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = DateTime.now().toIso8601String();
    list.add(item);
    _box.write('leaves', list);
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

  List<Map<String, dynamic>> getOvertimes() {
    final raw = _box.read<List>('overtimes') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> addOvertime(Map<String, dynamic> data) {
    final list = getOvertimes();
    final int nextId = list.isEmpty ? 1 : list.length + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['status'] = item['status'] ?? 'pending';
    item['created_at'] = DateTime.now().toIso8601String();
    list.add(item);
    _box.write('overtimes', list);
    return item;
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

  List<Map<String, dynamic>> getSuggestions() {
    final raw = _box.read<List>('suggestions') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> addSuggestion(Map<String, dynamic> data) {
    final list = getSuggestions();
    final int nextId = list.isEmpty ? 1 : list.length + 1;
    final item = Map<String, dynamic>.from(data);
    item['id'] = nextId;
    item['is_read'] = false;
    item['created_at'] = DateTime.now().toIso8601String();
    list.add(item);
    _box.write('suggestions', list);
    return item;
  }

  void markSuggestionRead(dynamic id) {
    final list = getSuggestions();
    final idx = list.indexWhere((s) => s['id'].toString() == id.toString());
    if (idx >= 0) {
      list[idx]['is_read'] = true;
      _box.write('suggestions', list);
    }
  }

  // ==================== NOTIFICATIONS ====================
  List<Map<String, dynamic>> getNotifications() {
    final raw = _box.read<List>('notifications') ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void markNotificationRead(dynamic id) {
    final list = getNotifications();
    final idx = list.indexWhere((n) => n['id'].toString() == id.toString());
    if (idx >= 0) {
      list[idx]['is_read'] = true;
      _box.write('notifications', list);
    }
  }

  void markAllNotificationsRead() {
    final list = getNotifications();
    for (var n in list) {
      n['is_read'] = true;
    }
    _box.write('notifications', list);
  }
}
