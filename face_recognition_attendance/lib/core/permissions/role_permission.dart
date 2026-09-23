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
      // Organization Management
      AppPermission.createBranch,
      AppPermission.editBranch,
      AppPermission.deleteBranch,
      AppPermission.createDepartment,
      AppPermission.editDepartment,
      AppPermission.deleteDepartment,
      AppPermission.createEmployee,
      // Note: CEO does NOT check in
    },

    UserRole.admin: {
      AppPermission.accessCeoPanel,
      AppPermission.accessManagerPanel,
      AppPermission.accessLeaderPanel,
      AppPermission.accessEmployeePanel,
      // Organization Management
      AppPermission.createBranch,
      AppPermission.editBranch,
      AppPermission.deleteBranch,
      AppPermission.createDepartment,
      AppPermission.editDepartment,
      AppPermission.deleteDepartment,
      AppPermission.createEmployee,
      AppPermission.attendanceCheckIn,
      AppPermission.attendanceCheckOut,
      AppPermission.registerFace,
    },

    UserRole.manager: {
      AppPermission.accessManagerPanel,
      AppPermission.accessLeaderPanel,
      AppPermission.accessEmployeePanel,
      AppPermission.createDepartment,
      AppPermission.editDepartment,
      AppPermission.deleteDepartment,
      AppPermission.createEmployee,
      AppPermission.attendanceCheckIn,
      AppPermission.attendanceCheckOut,
      AppPermission.registerFace,
    },

    UserRole.leader: {
      AppPermission.accessLeaderPanel,
      AppPermission.accessEmployeePanel,
      AppPermission.createEmployee,
      AppPermission.attendanceCheckIn,
      AppPermission.attendanceCheckOut,
      AppPermission.registerFace,
    },
    UserRole.employee: {
      AppPermission.accessEmployeePanel,
      AppPermission.attendanceCheckIn,
      AppPermission.attendanceCheckOut,
      AppPermission.registerFace,
    },
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
      case UserRole.admin:
        return [UserRole.admin, UserRole.manager, UserRole.leader, UserRole.employee];
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
