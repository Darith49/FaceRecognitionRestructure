import 'dart:io';
import '../server/database.dart';

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

String partitionKey(String baseKey, {required bool isDemo}) {
  return isDemo ? 'demo_$baseKey' : 'real_$baseKey';
}

void main() {
  print('=== STARTING DEMO & REAL ISOLATION UNIT TESTS ===');

  // Test 1: Validate isDemoAccountEmail detector
  print('\n[Test 1] Testing demo account email detection...');
  final demoEmails = [
    'sonarseang@gmail.com',
    'admin@gmail.com',
    'manager@gmail.com',
    'leader@gmail.com',
    'employee@gmail.com',
    'SONARSEANG@GMAIL.COM',
    '  Admin@gmail.com  ',
    'Manager@Gmail.Com',
  ];
  for (final email in demoEmails) {
    assert(isDemoAccountEmail(email), 'Expected $email to be identified as demo account');
  }

  final realEmails = [
    'ceo@company.com',
    'admin@corporate.kh',
    'sarah.smith@enterprise.org',
    'david.leader@techcorp.com',
    'new_employee@startuphub.io',
  ];
  for (final email in realEmails) {
    assert(!isDemoAccountEmail(email), 'Expected $email to NOT be identified as demo account');
  }
  print('Demo account detection passed.');

  // Test 2: Storage partition key mapping
  print('\n[Test 2] Testing partition key namespacing...');
  assert(partitionKey('employees', isDemo: true) == 'demo_employees');
  assert(partitionKey('employees', isDemo: false) == 'real_employees');
  assert(partitionKey('branches', isDemo: true) == 'demo_branches');
  assert(partitionKey('branches', isDemo: false) == 'real_branches');
  assert(partitionKey('departments', isDemo: true) == 'demo_departments');
  assert(partitionKey('departments', isDemo: false) == 'real_departments');
  assert(partitionKey('attendance', isDemo: true) == 'demo_attendance');
  assert(partitionKey('attendance', isDemo: false) == 'real_attendance');
  assert(partitionKey('leaves', isDemo: true) == 'demo_leaves');
  assert(partitionKey('leaves', isDemo: false) == 'real_leaves');
  print('Partition key namespacing passed.');

  // Test 3: SQLite Database multi-tenant isolation
  print('\n[Test 3] Testing SQLite Database demo vs real partition isolation...');
  final testDbFile = 'test_isolation_run.db';
  if (File(testDbFile).existsSync()) {
    File(testDbFile).deleteSync();
  }

  final sqliteDb = AppSqliteDatabase();
  sqliteDb.init(dbPath: testDbFile);

  // Verify seeded demo branches have is_demo = 1
  final branches = sqliteDb.getBranches();
  assert(branches.length == 2, 'Expected 2 seeded branches');
  for (final b in branches) {
    assert(b['is_demo'] == 1, 'Branch ${b['name']} should have is_demo = 1');
  }

  // Verify seeded demo departments have is_demo = 1
  final depts = sqliteDb.getDepartments();
  assert(depts.length == 2, 'Expected 2 seeded departments');
  for (final d in depts) {
    assert(d['is_demo'] == 1, 'Department ${d['name']} should have is_demo = 1');
  }

  // Verify seeded demo employees have is_demo = 1
  final employees = sqliteDb.getEmployees();
  assert(employees.length == 5, 'Expected 5 seeded employees');
  for (final e in employees) {
    assert(e['is_demo'] == 1, 'Employee ${e['email']} should have is_demo = 1');
  }

  // Insert a Real User, Real Branch, Real Department (is_demo = 0)
  sqliteDb.db.execute('''
    INSERT INTO branches (name, address, latitude, longitude, radius, created_at, is_demo)
    VALUES (?, ?, ?, ?, ?, datetime('now'), 0);
  ''', ['Corporate Global Headquarters', 'Norodom Blvd, Phnom Penh', 11.5500, 104.9200, 400.0]);

  sqliteDb.db.execute('''
    INSERT INTO departments (name, code, description, manager_name, employee_count, created_at, is_demo)
    VALUES (?, ?, ?, ?, ?, datetime('now'), 0);
  ''', ['Executive Board', 'EXEC', 'Executive Board and Management', 'Real CEO', 1]);

  sqliteDb.db.execute('''
    INSERT INTO employees (fullname, email, role, employee_id, branch, department, is_demo, created_at)
    VALUES (?, ?, ?, ?, ?, ?, 0, datetime('now'));
  ''', ['Real Enterprise CEO', 'realceo@company.com', 'ceo', 'EMP-REAL-001', 3, 3]);

  // Verify data separation in SQLite
  final allEmps = sqliteDb.getEmployees();
  assert(allEmps.length == 6, 'Total employees should now be 6');

  final demoEmpsOnly = allEmps.where((e) => e['is_demo'] == 1).toList();
  final realEmpsOnly = allEmps.where((e) => e['is_demo'] == 0 || e['is_demo'] == null).toList();

  assert(demoEmpsOnly.length == 5, 'Demo partition should strictly contain 5 accounts');
  assert(realEmpsOnly.length == 1, 'Real partition should strictly contain 1 account');
  assert(realEmpsOnly.first['email'] == 'realceo@company.com', 'Real account email should match');

  // Verify Real branches & departments isolation
  final allBranches = sqliteDb.getBranches();
  final realBranchesOnly = allBranches.where((b) => b['is_demo'] == 0 || b['is_demo'] == null).toList();
  assert(realBranchesOnly.length == 1, 'Real branches should strictly contain 1 branch');
  assert(realBranchesOnly.first['name'] == 'Corporate Global Headquarters');

  final allDepts = sqliteDb.getDepartments();
  final realDeptsOnly = allDepts.where((d) => d['is_demo'] == 0 || d['is_demo'] == null).toList();
  assert(realDeptsOnly.length == 1, 'Real departments should strictly contain 1 department');
  assert(realDeptsOnly.first['name'] == 'Executive Board');

  print('SQLite Database multi-tenant isolation passed.');

  // Test 4: Hydration partitioning simulation
  print('\n[Test 4] Testing hydration partitioning into demo_* and real_* namespaces...');
  final demoBox = <String, dynamic>{};
  final realBox = <String, dynamic>{};

  for (final e in allEmps) {
    final email = e['email']?.toString() ?? '';
    final isDemo = (e['is_demo'] == 1 || e['is_demo'] == true) || isDemoAccountEmail(email);
    if (isDemo) {
      demoBox.putIfAbsent('demo_employees', () => <Map<String, dynamic>>[]).add(e);
    } else {
      realBox.putIfAbsent('real_employees', () => <Map<String, dynamic>>[]).add(e);
    }
  }

  final hydratedDemoEmps = demoBox['demo_employees'] as List<Map<String, dynamic>>;
  final hydratedRealEmps = realBox['real_employees'] as List<Map<String, dynamic>>;

  assert(hydratedDemoEmps.length == 5);
  assert(hydratedRealEmps.length == 1);
  assert(!hydratedRealEmps.any((e) => isDemoAccountEmail(e['email'])), 'Zero demo accounts in real partition!');
  assert(hydratedRealEmps.first['email'] == 'realceo@company.com');
  print('Hydration partitioning simulation passed.');

  sqliteDb.close();
  if (File(testDbFile).existsSync()) {
    File(testDbFile).deleteSync();
  }

  print('\n=== ALL DEMO & REAL ISOLATION TESTS PASSED SUCCESSFULLY! ===\n');
}
