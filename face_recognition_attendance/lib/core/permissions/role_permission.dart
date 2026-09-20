import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';

class RolePermission {
  //Private Constructor not allow other call create object from this class because all method is static
  RolePermission._();

  static final Map<UserRole, Set<AppPermission>> _rolePermissions = {
    UserRole.ceo: {
      AppPermission.accessCeoPanel,
      AppPermission.accessManagerPanel,
      AppPermission.accessLeaderPanel,
      AppPermission.accessEmployeePanel,
    },

    UserRole.manager: {
      AppPermission.accessManagerPanel,
      AppPermission.accessLeaderPanel,
      AppPermission.accessEmployeePanel,
    },

    UserRole.leader: {
      AppPermission.accessLeaderPanel,
      AppPermission.accessEmployeePanel,
    },
    UserRole.employee: {AppPermission.accessEmployeePanel},
  };

  //Check Permission
  static bool hasPermission(UserRole role, AppPermission permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  static Set<AppPermission> getPermissions(UserRole role) {
    return _rolePermissions[role] ?? {};
  }

  static List<UserRole> getCreateableRoles(UserRole currentRole) {
    switch (currentRole) {
      case UserRole.ceo:
        return [UserRole.manager, UserRole.leader, UserRole.employee];
      case UserRole.manager:
        return [UserRole.leader, UserRole.employee];
      case UserRole.leader:
        return [UserRole.employee];
      case UserRole.employee:
        return [];
    }
  }

  //Check the current Role can create target Role or not as bool
  static bool canCreateRole(UserRole currentRole, UserRole targetRole) {
    return getCreateableRoles(currentRole).contains(targetRole);
  }
}
