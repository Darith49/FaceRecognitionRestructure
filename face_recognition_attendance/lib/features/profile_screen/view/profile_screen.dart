import 'package:face_recognition_attendance/core/permissions/app_permissions.dart';
import 'package:face_recognition_attendance/core/permissions/widgets/permission_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              'CEO can sell all button , manager can see (manager leader employee....)',
            ),
          ),
          PermissionView(
            targetPermission: AppPermission.accessCeoPanel,
            child: ElevatedButton(
              onPressed: () {
                Get.snackbar('CEO Action', 'CEO Button');
              },
              child: Text('CEO Button'),
            ),
          ),

          PermissionView(
            targetPermission: AppPermission.accessManagerPanel,
            child: ElevatedButton(
              onPressed: () {
                Get.snackbar('Manager Action', 'Manager Button');
              },
              child: Text('Manager Button'),
            ),
          ),
          PermissionView(
            targetPermission: AppPermission.accessLeaderPanel,
            child: ElevatedButton(
              onPressed: () {
                Get.snackbar('Leader Action', 'Leader  Button');
              },
              child: Text('Leader Button'),
            ),
          ),
          PermissionView(
            targetPermission: AppPermission.accessEmployeePanel,
            child: ElevatedButton(
              onPressed: () {
                Get.snackbar('Employee Action', 'Employee Button');
              },
              child: Text('Employee Button'),
            ),
          ),
        ],
      ),
    );
  }
}
