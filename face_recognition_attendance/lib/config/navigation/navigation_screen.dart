import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/home_screen/view/home_screen.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/myteam_screen.dart';
import 'package:face_recognition_attendance/features/profile_screen/view/profile_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
import 'package:face_recognition_attendance/features/schedule_screen/view/schedule_screen.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class NavigationScreen extends GetView<NavigationController> {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.canvasParchment,
      extendBody: true,
      edgeFade: true,
      body: Obx(() {
        return IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            HomeScreen(),
            ScheduleScreen(),
            MyteamScreen(),
            RequestScreen(),
            ProfileScreen(),
          ],
        );
      }),
      bottomBar: Obx(() {
        final currentIndex = controller.currentIndex.value;
        final isProfileSelected = currentIndex == 4;

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
                  icon: const Icon(FluentIcons.home_24_regular),
                  activeIcon: const Icon(FluentIcons.home_24_filled),
                  label: 'nav_home'.tr,
                ),
                GlassTab(
                  icon: const Icon(FluentIcons.calendar_ltr_24_regular),
                  activeIcon: const Icon(FluentIcons.calendar_ltr_24_filled),
                  label: 'nav_schedule'.tr,
                ),
                GlassTab(
                  icon: const Icon(FluentIcons.people_community_24_regular),
                  activeIcon: const Icon(FluentIcons.people_community_24_filled),
                  label: 'nav_myteam'.tr,
                ),
                GlassTab(
                  icon: const Icon(FluentIcons.document_bullet_list_multiple_24_regular),
                  activeIcon: const Icon(FluentIcons.document_bullet_list_multiple_24_filled),
                  label: 'nav_request'.tr,
                ),
              ],
              extraButton: GlassTabBarExtraButton(
                icon: Icon(
                  isProfileSelected
                      ? FluentIcons.person_24_filled
                      : FluentIcons.person_24_regular,
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
              quality: GlassQuality.standard,
              interactionBehavior: GlassInteractionBehavior.full,
            ),
          ),
        );
      }),
    );
  }
}