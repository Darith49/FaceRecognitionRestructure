import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/role_permission.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';

void main() {
  print('=== STARTING ROLE & DEMO ACCOUNT PERMISSION TESTS ===');

  // 1. Test stringToUserRole parsing (case-insensitive)
  print('\n[Test 1] Testing stringToUserRole case-insensitive mapping...');
  assert(stringToUserRole('ceo') == UserRole.ceo);
  assert(stringToUserRole('CEO') == UserRole.ceo);
  assert(stringToUserRole('Ceo ') == UserRole.ceo);
  assert(stringToUserRole('admin') == UserRole.admin);
  assert(stringToUserRole('Admin') == UserRole.admin);
  assert(stringToUserRole(' ADMIN ') == UserRole.admin);
  assert(stringToUserRole('manager') == UserRole.manager);
  assert(stringToUserRole('Manager') == UserRole.manager);
  assert(stringToUserRole('leader') == UserRole.leader);
  assert(stringToUserRole('Leader') == UserRole.leader);
  assert(stringToUserRole('employee') == UserRole.employee);
  assert(stringToUserRole('Employee') == UserRole.employee);
  print('String to UserRole mapping tests passed.');

  // 2. Test userRoleToString
  print('\n[Test 2] Testing userRoleToString serialization...');
  assert(userRoleToString(UserRole.ceo) == 'ceo');
  assert(userRoleToString(UserRole.admin) == 'admin');
  assert(userRoleToString(UserRole.manager) == 'manager');
  assert(userRoleToString(UserRole.leader) == 'leader');
  assert(userRoleToString(UserRole.employee) == 'employee');
  print('UserRole to String serialization tests passed.');

  // 3. Test Demo Account Role Permissions
  print('\n[Test 3] Testing RolePermission for CEO & Admin...');
  assert(RolePermission.hasPermission(UserRole.ceo, AppPermission.accessCeoPanel));
  assert(RolePermission.hasPermission(UserRole.ceo, AppPermission.createBranch));
  assert(RolePermission.hasPermission(UserRole.admin, AppPermission.accessCeoPanel));
  assert(RolePermission.hasPermission(UserRole.admin, AppPermission.createBranch));

  print('\n[Test 4] Testing RolePermission for Manager, Leader, Employee...');
  assert(RolePermission.hasPermission(UserRole.manager, AppPermission.accessManagerPanel));
  assert(!RolePermission.hasPermission(UserRole.manager, AppPermission.accessCeoPanel));
  assert(!RolePermission.hasPermission(UserRole.manager, AppPermission.createBranch));

  assert(RolePermission.hasPermission(UserRole.leader, AppPermission.accessLeaderPanel));
  assert(!RolePermission.hasPermission(UserRole.leader, AppPermission.accessCeoPanel));
  assert(!RolePermission.hasPermission(UserRole.leader, AppPermission.createDepartment));

  assert(RolePermission.hasPermission(UserRole.employee, AppPermission.accessEmployeePanel));
  assert(!RolePermission.hasPermission(UserRole.employee, AppPermission.accessLeaderPanel));
  assert(!RolePermission.hasPermission(UserRole.employee, AppPermission.createEmployee));

  // 4. Test Createable Roles Hierarchy
  print('\n[Test 5] Testing Role creation hierarchy...');
  assert(RolePermission.canCreateRole(UserRole.ceo, UserRole.admin));
  assert(RolePermission.canCreateRole(UserRole.ceo, UserRole.manager));
  assert(RolePermission.canCreateRole(UserRole.admin, UserRole.manager));
  assert(RolePermission.canCreateRole(UserRole.manager, UserRole.leader));
  assert(!RolePermission.canCreateRole(UserRole.manager, UserRole.ceo));
  assert(!RolePermission.canCreateRole(UserRole.leader, UserRole.manager));
  assert(!RolePermission.canCreateRole(UserRole.employee, UserRole.employee));

  print('\n=== ALL ROLE & DEMO ACCOUNT TESTS PASSED SUCCESSFULLY! ===');
}
