import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/create_hub/view/create_hub_screen.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loginController = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : null;

    return GlassScaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.canvasParchment,
      extendBody: true,
      edgeFade: true,
      body: Obx(() {
        final role = loginController?.currentuser.value?.role;
        final isManagement = role == UserRole.ceo || role == UserRole.manager || role == UserRole.leader;

        return IndexedStack(
          index: controller.currentIndex.value,
          children: [
            const HomeScreen(),
            if (isManagement) const CreateHubScreen() else const ScheduleScreen(),
            const MyteamScreen(),
            const RequestScreen(),
            const ProfileScreen(),
          ],
        );
      }),
      bottomBar: Obx(() {
        final currentIndex = controller.currentIndex.value;
        final isProfileSelected = currentIndex == 4;
        final role = loginController?.currentuser.value?.role;
        final isManagement = role == UserRole.ceo || role == UserRole.manager || role == UserRole.leader;

        return Material(
          type: MaterialType.transparency,
          child: DefaultTextStyle(
            style: const TextStyle(
              decoration: TextDecoration.none,
              fontFamily: 'Inter',
            ),
            child: GlassTabBar.bottom(
              selectedIndex: isProfileSelected ? 0 : currentIndex,
              showIndicator: !isProfileSelected,
              onTabSelected: (index) => controller.changePage(index),
              tabs: [
                GlassTab(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: 'nav_home'.tr,
                ),
                if (isManagement)
                  GlassTab(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    activeIcon: const Icon(Icons.add_circle_rounded),
                    label: 'nav_create'.tr,
                  )
                else
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
              ],
              extraButton: GlassTabBarExtraButton(
                icon: Icon(
                  isProfileSelected
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  size: 26,
                  color: isProfileSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white : AppColors.ink),
                ),
                onTap: () => controller.changePage(4),
                label: 'nav_profile'.tr,
                iconColor: isProfileSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.ink),
                placement: GlassExtraButtonPlacement.right,
                size: 64,
              ),
              textStyle: const TextStyle(
                decoration: TextDecoration.none,
                fontSize: 11,
              ),
              selectedLabelStyle: const TextStyle(
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
              ),
              selectedIconColor: AppColors.primary,
              selectedLabelColor: AppColors.primary,
              unselectedIconColor: isDark ? Colors.white70 : AppColors.ink,
              unselectedLabelColor: isDark ? Colors.white70 : AppColors.ink,
              indicatorColor: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFE5E5EA).withValues(alpha: 0.85),
              barHeight: 64,
              quality: GlassQuality.premium,
              interactionBehavior: GlassInteractionBehavior.full,
            ),
          ),
        );
      }),
    );
  }
}