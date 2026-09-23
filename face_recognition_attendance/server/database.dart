import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

/// Standalone Native SQLite Database for Face Recognition Attendance System.
/// Preserves user biometrics, face embeddings, reference images, profile avatars,
/// employees, attendance logs, and requests permanently on the local disk.
class AppSqliteDatabase {
  static final AppSqliteDatabase _instance = AppSqliteDatabase._internal();
  factory AppSqliteDatabase() => _instance;
  AppSqliteDatabase._internal();

  Database? _db;
  bool _initialized = false;

  Database get db {
    if (_db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  /// Initialize SQLite connection and apply migrations.
  void init({String? dbPath}) {
    if (_initialized && _db != null) return;

    _ensureSqliteLibraryLoaded();

    final targetPath = dbPath ?? _resolveDefaultDbPath();
    final dbFile = File(targetPath);
    if (!dbFile.parent.existsSync()) {
      dbFile.parent.createSync(recursive: true);
    }

    _db = sqlite3.open(targetPath);
    _db!.execute('PRAGMA foreign_keys = ON;');
    _db!.execute('PRAGMA journal_mode = WAL;');

    _createTables();
    _seedInitialDataIfEmpty();
    _initialized = true;
  }

  void close() {
    _db?.close();
    _db = null;
    _initialized = false;
  }

  static void _ensureSqliteLibraryLoaded() {
    if (Platform.isWindows) {
      try {
        DynamicLibrary.open('sqlite3.dll');
      } catch (_) {
        // Try resolving relative to project directory
        final candidates = [
          'sqlite3.dll',
          '${Directory.current.path}\\sqlite3.dll',
          '${File(Platform.script.toFilePath()).parent.parent.path}\\sqlite3.dll',
          '${Platform.environment['LOCALAPPDATA']}\\Programs\\Python\\Python312\\DLLs\\sqlite3.dll',
        ];
        bool loaded = false;
        for (final p in candidates) {
          if (File(p).existsSync()) {
            try {
              DynamicLibrary.open(p);
              loaded = true;
              break;
            } catch (_) {}
          }
        }
        if (!loaded) {
          // Fallback to process symbols
          try {
            DynamicLibrary.process();
          } catch (_) {}
        }
      }
    }
  }

  static String _resolveDefaultDbPath() {
    final projectDir = Directory.current.path;
    return '$projectDir${Platform.pathSeparator}database${Platform.pathSeparator}face_attendance.db';
  }

  void _createTables() {
    // 1. Persistent User Account Vault (Profile picture, face recognition templates & photo)
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS user_vault (
        email TEXT PRIMARY KEY,
        profile_picture TEXT,
        has_face_registered INTEGER DEFAULT 0,
        face_templates TEXT,
        face_jpg TEXT,
        face_registered_at TEXT,
        updated_at TEXT
      );
    ''');

    // 2. Branches
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS branches (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL,
        radius REAL,
        created_at TEXT
      );
    ''');

    // 3. Departments
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS departments (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT,
        description TEXT,
        manager_name TEXT,
        employee_count INTEGER DEFAULT 0,
        created_at TEXT
      );
    ''');

    // 4. Employees
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT,
        employee_id TEXT UNIQUE,
        fullname TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL,
        branch INTEGER,
        branch_name TEXT,
        department INTEGER,
        department_name TEXT,
        status TEXT DEFAULT 'active',
        section1_start TEXT DEFAULT '08:00:00',
        section1_end TEXT DEFAULT '12:00:00',
        section2_start TEXT DEFAULT '13:00:00',
        section2_end TEXT DEFAULT '17:00:00',
        work_days TEXT DEFAULT 'mon,tue,wed,thu,fri',
        created_by TEXT DEFAULT 'system',
        created_at TEXT,
        profile_picture TEXT,
        has_face_registered INTEGER DEFAULT 0,
        face_templates TEXT,
        face_jpg TEXT,
        face_registered_at TEXT
      );
    ''');

    // 5. Registered Face Biometric Persons
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS persons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        employee_id TEXT,
        templates_json TEXT NOT NULL,
        reference_image TEXT,
        created_at TEXT
      );
    ''');

    // 6. Attendance Logs
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT NOT NULL,
        employee_name TEXT NOT NULL,
        date TEXT NOT NULL,
        check_in_time TEXT,
        check_out_time TEXT,
        status TEXT NOT NULL,
        check_in_type TEXT DEFAULT 'face',
        check_out_type TEXT,
        branch_id INTEGER,
        branch_name TEXT,
        notes TEXT,
        face_matched INTEGER DEFAULT 1,
        confidence REAL DEFAULT 0.0
      );
    ''');

    // 7. Leaves
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS leaves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT NOT NULL,
        employee_name TEXT NOT NULL,
        leave_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        total_days REAL DEFAULT 1.0,
        reason TEXT,
        status TEXT DEFAULT 'pending',
        approved_by TEXT,
        approved_at TEXT,
        created_at TEXT
      );
    ''');

    // 8. Overtimes
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS overtimes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT NOT NULL,
        employee_name TEXT NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        total_hours REAL DEFAULT 1.0,
        reason TEXT,
        status TEXT DEFAULT 'pending',
        approved_by TEXT,
        approved_at TEXT,
        created_at TEXT
      );
    ''');

    // 9. Suggestions
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS suggestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT DEFAULT 'General',
        is_read INTEGER DEFAULT 0,
        employee_name TEXT,
        created_at TEXT
      );
    ''');

    // 10. Notifications
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT,
        type TEXT DEFAULT 'system'
      );
    ''');
  }

  void _seedInitialDataIfEmpty() {
    // 1. Seed Branches
    final branchCount = _db!.select('SELECT COUNT(*) as count FROM branches;').first['count'] as int;
    if (branchCount == 0) {
      _db!.execute('''
        INSERT INTO branches (id, name, address, latitude, longitude, radius, created_at) VALUES
        (1, 'Phnom Penh Headquarters', 'Russian Federation Blvd, Phnom Penh, Cambodia', 11.5564, 104.9282, 500.0, datetime('now', '-60 days')),
        (2, 'Siem Reap Regional Hub', 'National Road 6, Siem Reap, Cambodia', 13.3633, 103.8564, 500.0, datetime('now', '-30 days'));
      ''');
    }

    // 2. Seed Departments
    final deptCount = _db!.select('SELECT COUNT(*) as count FROM departments;').first['count'] as int;
    if (deptCount == 0) {
      _db!.execute('''
        INSERT INTO departments (id, name, code, description, manager_name, employee_count, created_at) VALUES
        (1, 'Software Engineering', 'ENG', 'Mobile & Cloud Development team', 'Darith Admin', 5, datetime('now', '-60 days')),
        (2, 'Human Resources', 'HR', 'Recruitment & Employee Relations', 'Sarah Manager', 2, datetime('now', '-60 days'));
      ''');
    }

    // 3. Seed Demo Employees
    final empCount = _db!.select('SELECT COUNT(*) as count FROM employees;').first['count'] as int;
    if (empCount == 0) {
      final now = DateTime.now().toIso8601String();
      final demoEmployees = [
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
        },
      ];

      for (final e in demoEmployees) {
        _db!.execute('''
          INSERT INTO employees (
            id, firebase_uid, employee_id, fullname, email, role,
            branch, branch_name, department, department_name, status,
            section1_start, section1_end, section2_start, section2_end, work_days,
            created_by, created_at, has_face_registered
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', '08:00:00', '12:00:00', '13:00:00', '17:00:00', 'mon,tue,wed,thu,fri', 'system', ?, 0);
        ''', [
          e['id'],
          e['firebase_uid'],
          e['employee_id'],
          e['fullname'],
          e['email'],
          e['role'],
          e['branch'],
          e['branch_name'],
          e['department'],
          e['department_name'],
          now,
        ]);
      }
    }

    // 4. Seed Welcome Notification
    final notifCount = _db!.select('SELECT COUNT(*) as count FROM notifications;').first['count'] as int;
    if (notifCount == 0) {
      _db!.execute('''
        INSERT INTO notifications (title, message, is_read, created_at, type) VALUES
        ('Persistent SQLite Database Active', 'All biometric face registrations, attendance logs, and profile pictures are permanently preserved in SQLite database/face_attendance.db.', 0, datetime('now'), 'system');
      ''');
    }
  }

  // ==================== USER VAULT (PERMANENT BIOMETRICS & AVATAR) ====================

  Map<String, dynamic>? getUserVault(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final rows = _db!.select('SELECT * FROM user_vault WHERE LOWER(email) = ?;', [cleanEmail]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'email': row['email'],
      'profile_picture': row['profile_picture'],
      'has_face_registered': (row['has_face_registered'] as int? ?? 0) == 1,
      'face_templates': row['face_templates'] != null ? jsonDecode(row['face_templates'] as String) : null,
      'face_jpg': row['face_jpg'],
      'face_registered_at': row['face_registered_at'],
      'updated_at': row['updated_at'],
    };
  }

  void saveUserVault(String email, Map<String, dynamic> data) {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;
    final existing = getUserVault(cleanEmail) ?? {};
    final merged = Map<String, dynamic>.from(existing)..addAll(data);

    // Map profile_url alias if present
    if (merged.containsKey('profile_url') && (!merged.containsKey('profile_picture') || merged['profile_picture'] == null)) {
      merged['profile_picture'] = merged['profile_url'];
    }

    final templatesJson = merged['face_templates'] != null
        ? (merged['face_templates'] is String ? merged['face_templates'] : jsonEncode(merged['face_templates']))
        : null;

    _db!.execute('''
      INSERT INTO user_vault (email, profile_picture, has_face_registered, face_templates, face_jpg, face_registered_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
      ON CONFLICT(email) DO UPDATE SET
        profile_picture = COALESCE(excluded.profile_picture, user_vault.profile_picture),
        has_face_registered = COALESCE(excluded.has_face_registered, user_vault.has_face_registered),
        face_templates = COALESCE(excluded.face_templates, user_vault.face_templates),
        face_jpg = COALESCE(excluded.face_jpg, user_vault.face_jpg),
        face_registered_at = COALESCE(excluded.face_registered_at, user_vault.face_registered_at),
        updated_at = datetime('now');
    ''', [
      cleanEmail,
      merged['profile_picture'],
      (merged['has_face_registered'] == true) ? 1 : 0,
      templatesJson,
      merged['face_jpg'],
      merged['face_registered_at'] ?? DateTime.now().toIso8601String(),
    ]);

    // Also update employees table if user exists there
    _db!.execute('''
      UPDATE employees SET
        profile_picture = COALESCE(?, profile_picture),
        has_face_registered = CASE WHEN ? = 1 THEN 1 ELSE has_face_registered END,
        face_templates = COALESCE(?, face_templates),
        face_jpg = COALESCE(?, face_jpg),
        face_registered_at = COALESCE(?, face_registered_at)
      WHERE LOWER(email) = ?;
    ''', [
      merged['profile_picture'],
      (merged['has_face_registered'] == true) ? 1 : 0,
      templatesJson,
      merged['face_jpg'],
      merged['face_registered_at'],
      cleanEmail,
    ]);
  }

  // ==================== EMPLOYEES ====================

  List<Map<String, dynamic>> getEmployees() {
    final rows = _db!.select('SELECT * FROM employees ORDER BY id ASC;');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['has_face_registered'] = (r['has_face_registered'] as int? ?? 0) == 1;
      if (r['face_templates'] != null) {
        try {
          m['face_templates'] = jsonDecode(r['face_templates'] as String);
        } catch (_) {}
      }
      return m;
    }).toList();
  }

  Map<String, dynamic>? getEmployeeByEmail(String email) {
    final clean = email.trim().toLowerCase();
    final rows = _db!.select('SELECT * FROM employees WHERE LOWER(email) = ?;', [clean]);
    if (rows.isEmpty) return null;
    final m = Map<String, dynamic>.from(rows.first);
    m['has_face_registered'] = (m['has_face_registered'] as int? ?? 0) == 1;
    if (m['face_templates'] != null) {
      try {
        m['face_templates'] = jsonDecode(m['face_templates'] as String);
      } catch (_) {}
    }
    return m;
  }

  Map<String, dynamic>? getEmployeeById(dynamic id) {
    final rows = _db!.select('SELECT * FROM employees WHERE id = ? OR firebase_uid = ? OR employee_id = ?;', [id, id, id]);
    if (rows.isEmpty) return null;
    final m = Map<String, dynamic>.from(rows.first);
    m['has_face_registered'] = (m['has_face_registered'] as int? ?? 0) == 1;
    if (m['face_templates'] != null) {
      try {
        m['face_templates'] = jsonDecode(m['face_templates'] as String);
      } catch (_) {}
    }
    return m;
  }

  void updateEmployee(dynamic id, Map<String, dynamic> updates) {
    final emp = getEmployeeById(id);
    if (emp == null) return;

    final targetId = emp['id'];
    final email = emp['email']?.toString() ?? '';

    // Allowed columns in employees table to prevent SQL errors from non-existent fields
    const allowedColumns = {
      'firebase_uid', 'employee_id', 'fullname', 'email', 'role',
      'branch', 'branch_name', 'department', 'department_name', 'status',
      'section1_start', 'section1_end', 'section2_start', 'section2_end',
      'work_days', 'created_by', 'created_at', 'profile_picture',
      'has_face_registered', 'face_templates', 'face_jpg', 'face_registered_at',
    };

    final fields = <String>[];
    final values = <dynamic>[];

    updates.forEach((k, v) {
      String col = k;
      if (col == 'uid') col = 'firebase_uid';
      if (col == 'profile_url') col = 'profile_picture';

      if (!allowedColumns.contains(col)) return;

      if (col == 'has_face_registered') {
        fields.add('has_face_registered = ?');
        values.add(v == true ? 1 : 0);
      } else if (col == 'face_templates') {
        fields.add('face_templates = ?');
        values.add(v != null ? (v is String ? v : jsonEncode(v)) : null);
      } else if (col != 'id') {
        fields.add('$col = ?');
        values.add(v);
      }
    });

    if (fields.isNotEmpty) {
      values.add(targetId);
      _db!.execute('UPDATE employees SET ${fields.join(', ')} WHERE id = ?;', values);
    }

    // Mirror updates to vault if email exists and biometrics or avatar were updated
    final vaultUpdates = <String, dynamic>{};
    if (updates.containsKey('profile_picture')) vaultUpdates['profile_picture'] = updates['profile_picture'];
    if (updates.containsKey('profile_url')) vaultUpdates['profile_picture'] = updates['profile_url'];
    if (updates.containsKey('has_face_registered')) vaultUpdates['has_face_registered'] = updates['has_face_registered'];
    if (updates.containsKey('face_templates')) vaultUpdates['face_templates'] = updates['face_templates'];
    if (updates.containsKey('face_jpg')) vaultUpdates['face_jpg'] = updates['face_jpg'];

    if (email.isNotEmpty && vaultUpdates.isNotEmpty) {
      saveUserVault(email, vaultUpdates);
    }
  }

  // ==================== PERSONS (BIOMETRIC RECOGNITION REGISTRY) ====================

  List<Map<String, dynamic>> getPersons() {
    final rows = _db!.select('SELECT * FROM persons ORDER BY created_at DESC;');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      try {
        m['templates'] = jsonDecode(r['templates_json'] as String);
      } catch (_) {
        m['templates'] = [];
      }
      return m;
    }).toList();
  }

  void savePerson(Map<String, dynamic> person) {
    final id = person['id']?.toString() ?? '';
    final name = person['name']?.toString() ?? '';
    final employeeId = person['employee_id']?.toString() ?? '';
    final templates = person['templates'];
    final referenceImage = person['reference_image']?.toString();
    final createdAt = person['created_at']?.toString() ?? DateTime.now().toIso8601String();

    final templatesJson = templates != null
        ? (templates is String ? templates : jsonEncode(templates))
        : '[]';

    _db!.execute('''
      INSERT INTO persons (id, name, employee_id, templates_json, reference_image, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        employee_id = excluded.employee_id,
        templates_json = excluded.templates_json,
        reference_image = excluded.reference_image,
        created_at = excluded.created_at;
    ''', [id, name, employeeId, templatesJson, referenceImage, createdAt]);

    // Also link back to employees and vault
    final emp = getEmployeeById(id) ?? getEmployeeById(employeeId);
    if (emp != null) {
      final email = emp['email']?.toString() ?? '';
      final updates = {
        'has_face_registered': true,
        'face_templates': templates,
        'face_jpg': referenceImage,
        'face_registered_at': createdAt,
      };
      updateEmployee(emp['id'], updates);
      if (email.isNotEmpty) {
        saveUserVault(email, updates);
      }
    }
  }

  void deletePerson(String id) {
    _db!.execute('DELETE FROM persons WHERE id = ? OR employee_id = ?;', [id, id]);
    final emp = getEmployeeById(id);
    if (emp != null) {
      updateEmployee(emp['id'], {
        'has_face_registered': false,
        'face_templates': null,
        'face_jpg': null,
      });
      final email = emp['email']?.toString() ?? '';
      if (email.isNotEmpty) {
        saveUserVault(email, {
          'has_face_registered': false,
          'face_templates': null,
          'face_jpg': null,
        });
      }
    }
  }

  // ==================== ATTENDANCE ====================

  List<Map<String, dynamic>> getAttendanceRecords({String? employeeId, String? date}) {
    String sql = 'SELECT * FROM attendance';
    final conditions = <String>[];
    final params = <dynamic>[];

    if (employeeId != null) {
      conditions.add('(employee_id = ?)');
      params.add(employeeId);
    }
    if (date != null) {
      conditions.add('(date = ?)');
      params.add(date);
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }
    sql += ' ORDER BY id DESC;';

    final rows = _db!.select(sql, params);
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['face_matched'] = (r['face_matched'] as int? ?? 1) == 1;
      return m;
    }).toList();
  }

  Map<String, dynamic> recordAttendance({
    required String employeeId,
    required String employeeName,
    required String type, // 'check-in' or 'check-out'
    required String time,
    required String date,
    String? checkType,
    int? branchId,
    String? branchName,
    String? notes,
    bool faceMatched = true,
    double confidence = 0.95,
  }) {
    if (type == 'check-in') {
      _db!.execute('''
        INSERT INTO attendance (
          employee_id, employee_name, date, check_in_time, status,
          check_in_type, branch_id, branch_name, notes, face_matched, confidence
        ) VALUES (?, ?, ?, ?, 'present', ?, ?, ?, ?, ?, ?);
      ''', [
        employeeId,
        employeeName,
        date,
        time,
        checkType ?? 'face',
        branchId ?? 1,
        branchName ?? 'Phnom Penh Headquarters',
        notes,
        faceMatched ? 1 : 0,
        confidence,
      ]);

      final lastId = _db!.lastInsertRowId;
      return {
        'id': lastId,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'date': date,
        'check_in_time': time,
        'status': 'present',
        'message': 'Check-in recorded successfully in SQLite',
      };
    } else {
      // Check-out: Find today's open record or insert completed record
      final openRows = _db!.select('''
        SELECT * FROM attendance
        WHERE employee_id = ? AND date = ? AND check_out_time IS NULL
        ORDER BY id DESC LIMIT 1;
      ''', [employeeId, date]);

      if (openRows.isNotEmpty) {
        final recordId = openRows.first['id'];
        _db!.execute('''
          UPDATE attendance SET
            check_out_time = ?,
            check_out_type = ?
          WHERE id = ?;
        ''', [time, checkType ?? 'face', recordId]);

        return {
          'id': recordId,
          'employee_id': employeeId,
          'employee_name': employeeName,
          'date': date,
          'check_out_time': time,
          'message': 'Check-out updated successfully in SQLite',
        };
      } else {
        _db!.execute('''
          INSERT INTO attendance (
            employee_id, employee_name, date, check_out_time, status,
            check_out_type, branch_id, branch_name, notes, face_matched, confidence
          ) VALUES (?, ?, ?, ?, 'present', ?, ?, ?, ?, ?, ?);
        ''', [
          employeeId,
          employeeName,
          date,
          time,
          checkType ?? 'face',
          branchId ?? 1,
          branchName ?? 'Phnom Penh Headquarters',
          notes,
          faceMatched ? 1 : 0,
          confidence,
        ]);

        return {
          'id': _db!.lastInsertRowId,
          'employee_id': employeeId,
          'employee_name': employeeName,
          'date': date,
          'check_out_time': time,
          'message': 'Check-out recorded successfully in SQLite',
        };
      }
    }
  }

  // ==================== LEAVES & OVERTIMES ====================

  List<Map<String, dynamic>> getLeaves() {
    final rows = _db!.select('SELECT * FROM leaves ORDER BY id DESC;');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Map<String, dynamic> createLeave(Map<String, dynamic> data) {
    _db!.execute('''
      INSERT INTO leaves (
        employee_id, employee_name, leave_type, start_date, end_date,
        total_days, reason, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', datetime('now'));
    ''', [
      data['employee_id']?.toString() ?? '',
      data['employee_name']?.toString() ?? '',
      data['leave_type']?.toString() ?? 'Annual',
      data['start_date']?.toString() ?? '',
      data['end_date']?.toString() ?? '',
      data['total_days'] as num? ?? 1.0,
      data['reason']?.toString(),
    ]);

    final id = _db!.lastInsertRowId;
    return Map<String, dynamic>.from(data)..['id'] = id..['status'] = 'pending';
  }

  List<Map<String, dynamic>> getOvertimes() {
    final rows = _db!.select('SELECT * FROM overtimes ORDER BY id DESC;');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Map<String, dynamic> createOvertime(Map<String, dynamic> data) {
    _db!.execute('''
      INSERT INTO overtimes (
        employee_id, employee_name, date, start_time, end_time,
        total_hours, reason, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', datetime('now'));
    ''', [
      data['employee_id']?.toString() ?? '',
      data['employee_name']?.toString() ?? '',
      data['date']?.toString() ?? '',
      data['start_time']?.toString() ?? '',
      data['end_time']?.toString() ?? '',
      data['total_hours'] as num? ?? 1.0,
      data['reason']?.toString(),
    ]);

    final id = _db!.lastInsertRowId;
    return Map<String, dynamic>.from(data)..['id'] = id..['status'] = 'pending';
  }

  // ==================== DEPARTMENTS & BRANCHES ====================

  List<Map<String, dynamic>> getDepartments() {
    final rows = _db!.select('SELECT * FROM departments ORDER BY id ASC;');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  List<Map<String, dynamic>> getBranches() {
    final rows = _db!.select('SELECT * FROM branches ORDER BY id ASC;');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  List<Map<String, dynamic>> getSuggestions() {
    final rows = _db!.select('SELECT * FROM suggestions ORDER BY id DESC;');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['is_read'] = (r['is_read'] as int? ?? 0) == 1;
      return m;
    }).toList();
  }

  List<Map<String, dynamic>> getNotifications() {
    final rows = _db!.select('SELECT * FROM notifications ORDER BY id DESC;');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['is_read'] = (r['is_read'] as int? ?? 0) == 1;
      return m;
    }).toList();
  }

  /// Exports entire SQLite database snapshot as a unified JSON Map for client bootstrapping.
  Map<String, dynamic> getBootstrapData() {
    final vaultRows = _db!.select('SELECT * FROM user_vault;');
    final vault = <String, dynamic>{};
    for (final r in vaultRows) {
      final email = r['email']?.toString() ?? '';
      if (email.isNotEmpty) {
        vault[email] = {
          'email': email,
          'profile_picture': r['profile_picture'],
          'has_face_registered': (r['has_face_registered'] as int? ?? 0) == 1,
          'face_templates': r['face_templates'] != null ? jsonDecode(r['face_templates'] as String) : null,
          'face_jpg': r['face_jpg'],
          'face_registered_at': r['face_registered_at'],
          'updated_at': r['updated_at'],
        };
      }
    }

    return {
      'branches': getBranches(),
      'departments': getDepartments(),
      'employees': getEmployees(),
      'persons': getPersons(),
      'attendance': getAttendanceRecords(),
      'leaves': getLeaves(),
      'overtimes': getOvertimes(),
      'suggestions': getSuggestions(),
      'notifications': getNotifications(),
      'user_vault': vault,
    };
  }
}
