import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/view/widgets/attendance_hero_card.dart';
import 'package:face_recognition_attendance/features/home_screen/view/widgets/biometric_check_in_button.dart';
import 'package:face_recognition_attendance/features/home_screen/view/widgets/ceo_action_panel.dart';
import 'package:face_recognition_attendance/features/home_screen/view/widgets/home_greeting_header.dart';
import 'package:face_recognition_attendance/features/home_screen/view/widgets/home_quick_actions_bar.dart';
import 'package:face_recognition_attendance/features/home_screen/view/widgets/supervisor_team_live_card.dart';
import 'package:face_recognition_attendance/features/home_screen/view/widgets/wifi_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final HomeController controller = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController(), permanent: true);

  late final AnimationController _entranceController;
  late final Animation<double> _greetingSlide;
  late final Animation<double> _greetingFade;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _buttonScale;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _greetingSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _greetingFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    _cardSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.60, curve: Curves.easeOut),
      ),
    );

    _buttonScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.85, curve: Curves.elasticOut),
      ),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.70, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : RequestColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _entranceController,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _greetingSlide.value),
                  child: Opacity(opacity: _greetingFade.value, child: child),
                ),
                child: HomeGreetingHeader(controller: controller),
              ),

              const SizedBox(height: 16),

              Obx(() {
                if (controller.isCeo) {
                  return AnimatedBuilder(
                    animation: _entranceController,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _cardSlide.value),
                      child: Opacity(opacity: _cardFade.value, child: child),
                    ),
                    child: CeoActionPanel(controller: controller),
                  );
                }

                return Column(
                  children: [
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _cardSlide.value),
                        child: Opacity(opacity: _cardFade.value, child: child),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AttendanceHeroCard(controller: controller),
                      ),
                    ),

                    if (controller.isLeader || controller.isManager) ...[
                      const SizedBox(height: 16),
                      SupervisorTeamLiveCard(controller: controller),
                    ],

                    const SizedBox(height: 20),
                    const HomeQuickActionsBar(),

                    const SizedBox(height: 28),

                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (_, child) => Transform.scale(
                        scale: _buttonScale.value,
                        child: Opacity(
                          opacity: _buttonFade.value,
                          child: child,
                        ),
                      ),
                      child: BiometricCheckInButton(controller: controller),
                    ),

                    const SizedBox(height: 24),

                    // Wi-Fi Status Pill
                    const WifiStatusPill(),

                    const SizedBox(height: 16),

                    // Next schedule
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        controller.nextScheduleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}
