import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class PermissionMiddleware extends GetMiddleware {
  final AppPermission requiredPermission;
  final String redirectRoute;

  PermissionMiddleware(
    this.requiredPermission, {
    this.redirectRoute = AppRoutes.navigation,
  });

  @override
  RouteSettings? redirect(String? route) {
    // Check permission via PermissionService
    if (!PermissionService.to.can(requiredPermission)) {
      Get.snackbar(
        'Access Denied',
        'You do not have permission to view this page.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return RouteSettings(name: redirectRoute);
    }
    return null;
  }
}
