import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/home_screen/view/home_screen.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/myteam_screen.dart';
import 'package:face_recognition_attendance/features/profile_screen/view/profile_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
import 'package:face_recognition_attendance/features/schedule_screen/view/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class NavigationScreen extends GetView<NavigationController> {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      backgroundColor: AppColors.canvasParchment,
      extendBody: true,
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
      bottomBar: Obx(
        () => GlassTabBar.bottom(
          selectedIndex: controller.currentIndex.value,
          onTabSelected: (index) => controller.changePage(index),
          tabs: [
            GlassTab(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: 'nav_home'.tr,
            ),
            GlassTab(
              icon: const Icon(Icons.calendar_month_outlined),
              activeIcon: const Icon(Icons.calendar_month_rounded),
              label: 'nav_schedule'.tr,
            ),
            GlassTab(
              icon: const Icon(Icons.people_alt_outlined),
              activeIcon: const Icon(Icons.people_alt_rounded),
              label: 'nav_myteam'.tr,
            ),
            GlassTab(
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment_rounded),
              label: 'nav_request'.tr,
            ),
            GlassTab(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: 'nav_profile'.tr,
            ),
          ],
          selectedIconColor: AppColors.primary,
          selectedLabelColor: AppColors.primary,
          unselectedIconColor: const Color(0xFF8E8E93),
          unselectedLabelColor: const Color(0xFF8E8E93),
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          barHeight: 64,
        ),
      ),
    );
  }
}