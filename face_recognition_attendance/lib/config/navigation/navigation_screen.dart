import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/home_screen/view/home_screen.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/myteam_screen.dart';
import 'package:face_recognition_attendance/features/profile_screen/view/profile_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
import 'package:face_recognition_attendance/features/schedule_screen/view/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationScreen extends GetView<NavigationController> {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasParchment,
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            HomeScreen(),
            ScheduleScreen(),
            MyteamScreen(),
            RequestScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavTab(
                    icon: Icons.home_rounded,
                    outlinedIcon: Icons.home_outlined,
                    label: 'nav_home'.tr,
                    isSelected: controller.currentIndex.value == 0,
                    onTap: () => controller.changePage(0),
                  ),
                  _NavTab(
                    icon: Icons.calendar_month_rounded,
                    outlinedIcon: Icons.calendar_month_outlined,
                    label: 'nav_schedule'.tr,
                    isSelected: controller.currentIndex.value == 1,
                    onTap: () => controller.changePage(1),
                  ),
                  _NavTab(
                    icon: Icons.people_alt_rounded,
                    outlinedIcon: Icons.people_alt_outlined,
                    label: 'nav_myteam'.tr,
                    isSelected: controller.currentIndex.value == 2,
                    onTap: () => controller.changePage(2),
                  ),
                  _NavTab(
                    icon: Icons.assignment_rounded,
                    outlinedIcon: Icons.assignment_outlined,
                    label: 'nav_request'.tr,
                    isSelected: controller.currentIndex.value == 3,
                    onTap: () => controller.changePage(3),
                  ),
                  _NavTab(
                    icon: Icons.person_rounded,
                    outlinedIcon: Icons.person_outline_rounded,
                    label: 'nav_profile'.tr,
                    isSelected: controller.currentIndex.value == 4,
                    onTap: () => controller.changePage(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : const Color(0xFF8E8E93);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : outlinedIcon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}