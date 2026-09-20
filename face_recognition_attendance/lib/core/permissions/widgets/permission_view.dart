import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/permission_service.dart';
import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

class PermissionView extends GetView<AuthController> {
  final AppPermission targetPermission;
  final Widget child;
  final Widget fallback;

  const PermissionView({
    super.key,
    required this.targetPermission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.currentuser.value;
      if (user == null) return fallback;

      final isAllowed = PermissionService.to.can(targetPermission);
      return isAllowed ? child : fallback;
    });
  }
}
