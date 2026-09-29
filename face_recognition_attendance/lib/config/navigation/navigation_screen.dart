import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/services/theme_service.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/ceo_manage/view/ceo_manage_screen.dart';
import 'package:face_recognition_attendance/features/clock_screen/view/clock_screen.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/view/home_screen.dart';
import 'package:face_recognition_attendance/features/myteam_screen/controller/myteam_controller.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/myteam_screen.dart';
import 'package:face_recognition_attendance/features/profile_screen/view/profile_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class NavigationScreen extends GetView<NavigationController> {
  const NavigationScreen({super.key});

  bool _isCeoUser() {
    final loginCtrl = Get.isRegistered<LoginController>() ? Get.find<LoginController>() : null;
    final role = loginCtrl?.currentuser.value?.role;
    if (role == UserRole.ceo) return true;
    if (loginCtrl?.isCeo == true) return true;

    final homeCtrl = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;
    if (homeCtrl?.isCeo == true) return true;

    final myTeamCtrl = Get.isRegistered<MyTeamController>() ? Get.find<MyTeamController>() : null;
    if (myTeamCtrl?.currentRole.toLowerCase() == 'ceo' || myTeamCtrl?.isCeo == true) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeService = Get.isRegistered<ThemeService>() ? Get.find<ThemeService>() : null;
      final isDark = themeService != null
          ? themeService.isActualDark
          : (Theme.of(context).brightness == Brightness.dark);
      final loc = Get.locale?.toString() ?? 'en_US';
      final currentIndex = controller.currentIndex.value;
      final isProfileSelected = currentIndex == 4;
      final isCeo = _isCeoUser();

      return GlassScaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.canvasParchment,
        extendBody: true,
        edgeFade: true,
        body: KeyedSubtree(
          key: ValueKey('$loc-$isDark-$isCeo'),
          child: IndexedStack(
            index: currentIndex,
            children: [
              const HomeScreen(),
              isCeo ? const CeoManageScreen() : const ClockScreen(showBackButton: false),
              const RequestScreen(),
              const MyteamScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
        bottomBar: Material(
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
                  icon: Icon(isCeo ? FluentIcons.chart_multiple_24_regular : FluentIcons.fingerprint_24_regular),
                  activeIcon: Icon(isCeo ? FluentIcons.chart_multiple_24_filled : FluentIcons.fingerprint_24_filled),
                  label: isCeo ? 'nav_manage'.tr : 'nav_clock'.tr,
                ),
                GlassTab(
                  icon: const Icon(FluentIcons.document_bullet_list_multiple_24_regular),
                  activeIcon: const Icon(FluentIcons.document_bullet_list_multiple_24_filled),
                  label: 'nav_request'.tr,
                ),
                GlassTab(
                  icon: const Icon(FluentIcons.people_community_24_regular),
                  activeIcon: const Icon(FluentIcons.people_community_24_filled),
                  label: 'nav_myteam'.tr,
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
        ),
      );
    });
  }
}