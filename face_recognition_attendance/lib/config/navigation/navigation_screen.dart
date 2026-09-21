import 'dart:ui';
import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/features/home_screen/view/home_screen.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/myteam_screen.dart';
import 'package:face_recognition_attendance/features/profile_screen/view/profile_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
import 'package:face_recognition_attendance/features/schedule_screen/view/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NavigationScreen extends GetView<NavigationController> {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.canvasParchment,
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
      bottomNavigationBar: _LiquidGlassFloatingNavBar(controller: controller),
    );
  }
}

class _LiquidGlassFloatingNavBar extends StatelessWidget {
  const _LiquidGlassFloatingNavBar({required this.controller});

  final NavigationController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  fontFamily: 'Inter',
                ),
                child: SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      // ─── Main Pill Capsule (4 Tabs) ───────────────────────────
                      Expanded(
                        child: _MainNavBarCapsule(
                          controller: controller,
                          isDark: isDark,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ─── Standalone Alone Profile Button ──────────────────────
                      _StandaloneProfileButton(
                        controller: controller,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainNavBarCapsule extends StatelessWidget {
  const _MainNavBarCapsule({
    required this.controller,
    required this.isDark,
  });

  final NavigationController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.75),
                width: 1.2,
              ),
            ),
            child: Obx(() {
              final activeIndex = controller.currentIndex.value;

              return Row(
                children: [
                  Expanded(
                    child: _NavCapsuleItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'nav_home'.tr,
                      isSelected: activeIndex == 0,
                      isDark: isDark,
                      onTap: () => _onTabTap(0),
                    ),
                  ),
                  Expanded(
                    child: _NavCapsuleItem(
                      index: 1,
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month_rounded,
                      label: 'nav_schedule'.tr,
                      isSelected: activeIndex == 1,
                      isDark: isDark,
                      onTap: () => _onTabTap(1),
                    ),
                  ),
                  Expanded(
                    child: _NavCapsuleItem(
                      index: 2,
                      icon: Icons.people_alt_outlined,
                      activeIcon: Icons.people_alt_rounded,
                      label: 'nav_myteam'.tr,
                      isSelected: activeIndex == 2,
                      isDark: isDark,
                      onTap: () => _onTabTap(2),
                    ),
                  ),
                  Expanded(
                    child: _NavCapsuleItem(
                      index: 3,
                      icon: Icons.assignment_outlined,
                      activeIcon: Icons.assignment_rounded,
                      label: 'nav_request'.tr,
                      isSelected: activeIndex == 3,
                      isDark: isDark,
                      onTap: () => _onTabTap(3),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    HapticFeedback.lightImpact();
    controller.changePage(index);
  }
}

class _NavCapsuleItem extends StatelessWidget {
  const _NavCapsuleItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBgColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE5E5EA).withValues(alpha: 0.85);

    final selectedIconColor = AppColors.primary;
    final unselectedIconColor = isDark ? Colors.white70 : AppColors.ink;

    final selectedTextColor = AppColors.primary;
    final unselectedTextColor = isDark ? Colors.white60 : const Color(0xFF3C3C43);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 21,
              color: isSelected ? selectedIconColor : unselectedIconColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedTextColor : unselectedTextColor,
                decoration: TextDecoration.none,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandaloneProfileButton extends StatelessWidget {
  const _StandaloneProfileButton({
    required this.controller,
    required this.isDark,
  });

  final NavigationController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.currentIndex.value == 4;

      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.changePage(4);
                },
                customBorder: const CircleBorder(),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.95))
                        : (isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.88)),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.65)
                          : (isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.75)),
                      width: isSelected ? 1.8 : 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
                      size: 25,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white70 : AppColors.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}