import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/role_permission.dart';
import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:get/get.dart';

class PermissionService extends GetxService {
  static PermissionService get to => Get.find<PermissionService>();

  AuthController get _authController => Get.find<AuthController>();

  UserRole? get currentRole => _authController.currentuser.value?.role;

  //Check CurrentUser have Permission or not
  bool can(AppPermission permission) {
    final role = currentRole;
    if (role == null) return false;
    return RolePermission.hasPermission(role, permission);
  }

  bool canAny(List<AppPermission> permissions) {
    final role = currentRole;
    if (role == null) return false;
    return permissions.any((p) => RolePermission.hasPermission(role, p));
  }

  //Return list of role the current user is allowed to create
  List<UserRole> getCreateableRoles() {
    final role = currentRole;
    if (role == null) return [];
    return RolePermission.getCreateableRoles(role);
  }

  bool canCreateRole(UserRole targetRole) {
    final role = currentRole;
    if (role == null) return false;
    return RolePermission.canCreateRole(role, targetRole);
  }
}
