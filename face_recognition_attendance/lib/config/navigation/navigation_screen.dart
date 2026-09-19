import 'package:face_recognition_attendance/config/navigation/navigation_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/view/home_screen.dart';
import 'package:face_recognition_attendance/features/myteam_screen/view/myteam_screen.dart';
import 'package:face_recognition_attendance/features/profile_screen/view/profile_screen.dart';
import 'package:face_recognition_attendance/features/request_screen/view/request_screen.dart';
import 'package:face_recognition_attendance/features/schedule_screen/view/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:get/state_manager.dart';
import 'package:hugeicons/hugeicons.dart';

class NavigationScreen extends GetView<NavigationController> {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final List<Widget> screens = [
      const HomeScreen(),
      const ScheduleScreen(),
      const MyteamScreen(),
      const RequestScreen(),
      const ProfileScreen(),
    ];

    return BottomBar(
      showIcon: false,
      layout: BottomBarLayout(
        width: MediaQuery.sizeOf(context).width - 32,
        offset: 16,
        borderRadius: BorderRadius.circular(28),
      ),
      motion: const BottomBarMotion.cupertino(
        preset: BottomBarCupertinoMotion.snappy,
        duration: Duration(milliseconds: 450),
        slideStart: Offset(0, 2),
      ),
      scrollBehavior: const BottomBarScrollBehavior(
        hideOnScroll: true,
        deltaThreshold: 8,
      ),
      theme: BottomBarThemeData(
        barDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
      body: Obx(() => screens[controller.selectedIndex.value]),
      child: _navigationBarView(),
    );
  }

  Widget _navigationBarView() {
    return SizedBox(
      height: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Obx(
          () => BottomBarItems(
            children: [
              BottomBarItem(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01),
                color: controller.selectedIndex.value == 0
                    ? Colors.blue
                    : Colors.grey,
                selectedColor: Colors.blue,
                label: Text(
                  'Home',
                  style: TextStyle(
                    color: controller.selectedIndex.value == 0
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
                onTap: () {
                  controller.changeIndex(0);
                },
              ),

              BottomBarItem(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedCalendarAnalysis),
                color: controller.selectedIndex.value == 1
                    ? Colors.blue
                    : Colors.grey,
                selectedColor: Colors.blue,
                label: Text(
                  'Schedule',
                  style: TextStyle(
                    color: controller.selectedIndex.value == 1
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
                onTap: () {
                  controller.changeIndex(1);
                },
              ),

              BottomBarItem(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedTeamWork),
                color: controller.selectedIndex.value == 2
                    ? Colors.blue
                    : Colors.grey,
                selectedColor: Colors.blue,
                label: Text(
                  'MyTeam',
                  style: TextStyle(
                    color: controller.selectedIndex.value == 2
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
                onTap: () {
                  controller.changeIndex(2);
                },
              ),

              BottomBarItem(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedGitPullRequest),
                color: controller.selectedIndex.value == 3
                    ? Colors.blue
                    : Colors.grey,
                selectedColor: Colors.blue,
                label: Text(
                  'Request',
                  style: TextStyle(
                    color: controller.selectedIndex.value == 3
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
                onTap: () {
                  controller.changeIndex(3);
                },
              ),

              BottomBarItem(
                icon: HugeIcon(icon: HugeIcons.strokeRoundedProfile),
                color: controller.selectedIndex.value == 4
                    ? Colors.blue
                    : Colors.grey,
                selectedColor: Colors.blue,
                label: Text(
                  'Profile',
                  style: TextStyle(
                    color: controller.selectedIndex.value == 4
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
                onTap: () {
                  controller.changeIndex(4);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
