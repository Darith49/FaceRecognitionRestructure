import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Full Screen Body (Edge-to-Edge)
          NotificationListener<ScrollNotification>(
            onNotification: controller.onScrollNotification,
            child: Obx(
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
          ),

          Obx(
            () => AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: controller.isNavBarVisible.value ? 0 : -130,
              child: CurvedNavigationBar(
                index: controller.currentIndex.value,
                height: 75,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
                buttonBackgroundColor: AppColors.primary,
                animationCurve: Curves.easeInOut,
                animationDuration: const Duration(milliseconds: 400),
                onTap: controller.changePage,
                items: [
                  CurvedNavigationBarItem(
                    child: const Icon(Icons.home_outlined, size: 28, color: Colors.white),
                    label: 'nav_home'.tr,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  CurvedNavigationBarItem(
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      size: 28,
                      color: Colors.white,
                    ),
                    label: 'nav_schedule'.tr,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  CurvedNavigationBarItem(
                    child: const Icon(
                      Icons.people_alt_outlined,
                      size: 28,
                      color: Colors.white,
                    ),
                    label: 'nav_myteam'.tr,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  CurvedNavigationBarItem(
                    child: const Icon(
                      Icons.pending_actions_outlined,
                      size: 28,
                      color: Colors.white,
                    ),
                    label: 'nav_request'.tr,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  CurvedNavigationBarItem(
                    child: const Icon(Icons.perm_identity, size: 28, color: Colors.white),
                    label: 'nav_profile'.tr,
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}