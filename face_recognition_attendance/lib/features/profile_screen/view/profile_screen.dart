import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/widgets/permission_view.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('profile_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'settings_title'.tr,
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() {
                        final user = loginController?.currentuser.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullname ?? 'profile_name'.tr,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'profile_email'.tr,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (user?.role != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user!.role.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Settings Tile
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                title: Text('settings_title'.tr),
                subtitle: Text('settings_language'.tr),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(AppRoutes.settings),
              ),
            ),

            const SizedBox(height: 16),

            // Role Test Section (preserves existing functionality)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Role-Based Panel Access:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),

            PermissionView(
              targetPermission: AppPermission.accessCeoPanel,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Get.snackbar('CEO Action', 'CEO Button');
                  },
                  child: const Text('CEO Button'),
                ),
              ),
            ),

            PermissionView(
              targetPermission: AppPermission.accessManagerPanel,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Get.snackbar('Manager Action', 'Manager Button');
                  },
                  child: const Text('Manager Button'),
                ),
              ),
            ),

            PermissionView(
              targetPermission: AppPermission.accessLeaderPanel,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Get.snackbar('Leader Action', 'Leader Button');
                  },
                  child: const Text('Leader Button'),
                ),
              ),
            ),

            PermissionView(
              targetPermission: AppPermission.accessEmployeePanel,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    Get.snackbar('Employee Action', 'Employee Button');
                  },
                  child: const Text('Employee Button'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
