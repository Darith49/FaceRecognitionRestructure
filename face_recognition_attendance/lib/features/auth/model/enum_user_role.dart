enum UserRole { ceo, admin, manager, leader, employee }

UserRole stringToUserRole(String? value) {
  final clean = value?.trim().toLowerCase();
  switch (clean) {
    case 'ceo':
      return UserRole.ceo;
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    case 'leader':
      return UserRole.leader;
    case 'employee':
      return UserRole.employee;
    default:
      return UserRole.employee;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.ceo:
      return 'ceo';
    case UserRole.admin:
      return 'admin';
    case UserRole.manager:
      return 'manager';
    case UserRole.leader:
      return 'leader';
    case UserRole.employee:
      return 'employee';
  }
}
