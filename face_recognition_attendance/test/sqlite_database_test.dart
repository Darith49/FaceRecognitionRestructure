import 'dart:io';
import '../server/database.dart';

void main() {
  print('=== STARTING SQLITE DATABASE UNIT TESTS ===');

  final testDbFile = 'test_database_run.db';
  if (File(testDbFile).existsSync()) {
    File(testDbFile).deleteSync();
  }

  final sqliteDb = AppSqliteDatabase();
  sqliteDb.init(dbPath: testDbFile);

  print('[Test 1] Verifying seeded branches, departments, and employees...');
  final branches = sqliteDb.getBranches();
  final depts = sqliteDb.getDepartments();
  final employees = sqliteDb.getEmployees();

  assert(branches.length == 2, 'Expected 2 branches, got ${branches.length}');
  assert(depts.length == 2, 'Expected 2 departments, got ${depts.length}');
  assert(employees.length == 5, 'Expected 5 demo employees, got ${employees.length}');
  print('Branches: ${branches.length}, Departments: ${depts.length}, Employees: ${employees.length} - PASSED');

  print('[Test 2] Testing User Vault with profile picture and face biometrics...');
  final testEmail = 'employee@gmail.com';
  final sampleFaceTemplate = List.generate(128, (i) => 0.05 * i);
  final sampleAvatar = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...sample_avatar';
  final sampleFaceJpg = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...sample_face';

  sqliteDb.saveUserVault(testEmail, {
    'profile_picture': sampleAvatar,
    'has_face_registered': true,
    'face_templates': [sampleFaceTemplate],
    'face_jpg': sampleFaceJpg,
    'face_registered_at': DateTime.now().toIso8601String(),
  });

  final vaultData = sqliteDb.getUserVault(testEmail);
  assert(vaultData != null, 'Vault data should not be null');
  assert(vaultData!['has_face_registered'] == true, 'Face should be registered');
  assert(vaultData!['profile_picture'] == sampleAvatar, 'Avatar should match');
  assert((vaultData!['face_templates'] as List).isNotEmpty, 'Face templates should exist');
  assert((vaultData!['face_templates'][0] as List).length == 128, 'Template vector length should be 128');

  // Verify it also updated the employee record
  final emp = sqliteDb.getEmployeeByEmail(testEmail);
  assert(emp != null, 'Employee should exist');
  assert(emp!['has_face_registered'] == true, 'Employee face should be registered');
  assert(emp!['profile_picture'] == sampleAvatar, 'Employee avatar should be updated');
  print('User Vault biometrics and avatar persistence test - PASSED');

  print('[Test 3] Testing Persons Biometric Registry...');
  sqliteDb.savePerson({
    'id': 'local_uid_emp_5',
    'name': 'Alex Developer',
    'employee_id': 'EMP-005',
    'templates': [sampleFaceTemplate],
    'reference_image': sampleFaceJpg,
  });

  final persons = sqliteDb.getPersons();
  assert(persons.any((p) => p['id'] == 'local_uid_emp_5'), 'Person should be in registry');
  print('Persons registry test - PASSED');

  print('[Test 4] Testing Attendance Clocking...');
  final checkIn = sqliteDb.recordAttendance(
    employeeId: 'EMP-005',
    employeeName: 'Alex Developer',
    type: 'check-in',
    time: '08:15:00',
    date: '2026-09-23',
    checkType: 'face',
    branchId: 1,
    branchName: 'Phnom Penh Headquarters',
    faceMatched: true,
    confidence: 0.98,
  );
  assert(checkIn['id'] != null, 'Check-in record ID should be generated');

  final checkOut = sqliteDb.recordAttendance(
    employeeId: 'EMP-005',
    employeeName: 'Alex Developer',
    type: 'check-out',
    time: '17:30:00',
    date: '2026-09-23',
    checkType: 'face',
  );
  assert(checkOut['check_out_time'] == '17:30:00', 'Check out time should match');

  final logs = sqliteDb.getAttendanceRecords(employeeId: 'EMP-005', date: '2026-09-23');
  assert(logs.isNotEmpty, 'Attendance logs should not be empty');
  assert(logs.first['check_in_time'] == '08:15:00', 'Check in time should match');
  assert(logs.first['check_out_time'] == '17:30:00', 'Check out time should match');
  print('Attendance clocking test - PASSED');

  print('[Test 5] Testing Bootstrap Data Snapshot...');
  final bootstrap = sqliteDb.getBootstrapData();
  assert((bootstrap['employees'] as List).length == 5, 'Bootstrap should have 5 employees');
  assert((bootstrap['user_vault'] as Map).containsKey(testEmail), 'Bootstrap should contain user vault');
  print('Bootstrap data snapshot test - PASSED');

  sqliteDb.close();

  // Test 6: Reopen database and verify persistent state survived database closure
  print('[Test 6] Reopening SQLite database file to verify disk persistence...');
  final reopenedDb = AppSqliteDatabase();
  reopenedDb.init(dbPath: testDbFile);

  final reopenedVault = reopenedDb.getUserVault(testEmail);
  assert(reopenedVault != null, 'Reopened vault must exist');
  assert(reopenedVault!['has_face_registered'] == true, 'Reopened vault face registration must be preserved');
  assert(reopenedVault!['profile_picture'] == sampleAvatar, 'Reopened avatar must match exactly');
  assert(reopenedDb.getAttendanceRecords().isNotEmpty, 'Reopened attendance records must be preserved');

  reopenedDb.close();
  print('Disk persistence after database restart test - PASSED');

  // Clean up test file
  if (File(testDbFile).existsSync()) {
    File(testDbFile).deleteSync();
  }

  print('=== ALL SQLITE DATABASE UNIT TESTS PASSED SUCCESSFULLY! ===');
}
