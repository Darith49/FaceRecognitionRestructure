enum UserRole { ceo, manager, leader, employee }

UserRole stringToUserRole(String? value) {
  switch (value) {
    case 'ceo':
      return UserRole.ceo;
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
    case UserRole.manager:
      return 'manager';
    case UserRole.leader:
      return 'leader';
    case UserRole.employee:
      return 'employee';
  }
}
