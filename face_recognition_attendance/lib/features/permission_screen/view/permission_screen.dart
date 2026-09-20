import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Permission" menu: Attendance and Request Permission.
class PermissionScreen extends GetView<PermissionController> {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Permission',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RequestMenuCard(
            icon: Icons.assignment_outlined,
            iconBackground: const Color(0xFFF4B07A),
            title: 'Attendance',
            subtitle: 'P / AP / W',
            // TODO: there is no design for the Attendance page yet.
            onTap: () => RequestSnack.show(
              ScaffoldMessenger.of(context),
              'The Attendance page is coming soon.',
            ),
          ),
          const SizedBox(height: 12),
          RequestMenuCard(
            icon: Icons.mail_outline_rounded,
            iconBackground: const Color(0xFFC97B7B),
            title: 'Request Permission',
            subtitle: 'Request Permission',
            onTap: _openRequestPermission,
          ),
        ],
      ),
    );
  }

  void _openRequestPermission() {
    // If the user already added sessions, show the list. Otherwise start with the form.
    final hasDrafts = controller.draftSessions.isNotEmpty;
    Get.toNamed(
      hasDrafts ? AppRoutes.permissionSessions : AppRoutes.requestPermission,
    );
  }
}
