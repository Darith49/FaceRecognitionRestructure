import 'dart:math' as math;

import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/clock_screen/controller/clock_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Redesigned Clock Attendance screen matching the Home screen design:
/// - RequestScaffold with back to Requests
/// - User Greeting Header (avatar, initials, online dot, role badge)
/// - Apple Attendance Card (live clock, full date, goal ring/badge, 3 stat columns)
/// - Interactive Animated Concentric Check-In Button (pulsing dashed ring, tap bounce, state transitions)
/// - Wi-Fi Status Pill & Next Schedule info
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with TickerProviderStateMixin {
  final ClockController controller = Get.isRegistered<ClockController>()
      ? Get.find<ClockController>()
      : Get.put(ClockController(), permanent: true);

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
    return RequestScaffold(
      title: 'Clock Attendance',
      backLabel: 'Requests',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            // User Greeting Header with Slide & Fade
            AnimatedBuilder(
              animation: _entranceController,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _greetingSlide.value),
                child: Opacity(
                  opacity: _greetingFade.value,
                  child: child,
                ),
              ),
              child: _ClockGreetingHeader(controller: controller),
            ),

            const SizedBox(height: 12),

            // Attendance Card with Slide & Fade
            AnimatedBuilder(
              animation: _entranceController,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _cardSlide.value),
                child: Opacity(
                  opacity: _cardFade.value,
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ClockAttendanceCard(controller: controller),
              ),
            ),

            const SizedBox(height: 28),

            // Concentric Animated Check In/Out Button with Scale & Fade
            AnimatedBuilder(
              animation: _entranceController,
              builder: (_, child) => Transform.scale(
                scale: _buttonScale.value,
                child: Opacity(
                  opacity: _buttonFade.value,
                  child: child,
                ),
              ),
              child: _ClockCheckInButton(controller: controller),
            ),

            const SizedBox(height: 24),

            // Wi-Fi Status Pill
            _ClockWifiStatusPill(),

            const SizedBox(height: 16),

            // Next schedule footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: RequestColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Obx(
                    () => Text(
                      controller.nextScheduleText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Greeting Header ─────────────────────────────────────────────────────────

class _ClockGreetingHeader extends StatelessWidget {
  const _ClockGreetingHeader({required this.controller});

  final ClockController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Obx(
        () {
          final loginController = Get.isRegistered<LoginController>()
              ? Get.find<LoginController>()
              : null;
          final user = loginController?.currentuser.value;
          final role = user?.role.name ?? 'Employee';

          return Row(
            children: [
              // Avatar with online dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RequestColors.primary.withValues(alpha: 0.10),
                      border: Border.all(
                        color: RequestColors.primary.withValues(alpha: 0.20),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials(controller.userName),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: RequestColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: RequestColors.approvedStatus,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            controller.userName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: RequestColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: RequestColors.approvedStatus
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.approvedStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.greeting} • Have a productive day',
                      style: const TextStyle(
                        fontSize: 12,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: RequestColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─── Attendance Card ─────────────────────────────────────────────────────────

class _ClockAttendanceCard extends StatelessWidget {
  const _ClockAttendanceCard({required this.controller});

  final ClockController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: appleCardDecoration(radius: 20),
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: RequestColors.textPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: child,
                        ),
                        child: Text(
                          DateText.clock(controller.now.value),
                          key: ValueKey(DateText.clock(controller.now.value)),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: RequestColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Text(
                        DateText.fullDate(controller.now.value),
                        style: const TextStyle(
                          fontSize: 13,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _ClockGoalBadge(controller: controller),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // ─── 2 Attendance Sessions ──────────────────────────────────────────
          Obx(
            () => Column(
              children: [
                // Session 1 Tile (Morning)
                _ClockSessionTile(
                  sessionNumber: 1,
                  sessionName: 'MORNING',
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  checkInTime: controller.session1CheckInText,
                  checkOutTime: controller.session1CheckOutText,
                  scheduledIn: controller.session1SchedIn,
                  scheduledOut: controller.session1SchedOut,
                  statusText: controller.session1StatusText,
                  isActive: controller.isSession1Active,
                  isDone: controller.isSession1Done,
                ),

                const SizedBox(height: 10),

                // Session 2 Tile (Afternoon)
                _ClockSessionTile(
                  sessionNumber: 2,
                  sessionName: 'AFTERNOON',
                  icon: Icons.wb_twilight_rounded,
                  iconColor: const Color(0xFF6366F1),
                  checkInTime: controller.session2CheckInText,
                  checkOutTime: controller.session2CheckOutText,
                  scheduledIn: controller.session2SchedIn,
                  scheduledOut: controller.session2SchedOut,
                  statusText: controller.session2StatusText,
                  isActive: controller.isSession2Active,
                  isDone: controller.isSession2Done,
                ),

                const SizedBox(height: 12),

                // Total Hours Summary Banner with Progress Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: controller.goalProgress >= 1.0
                        ? RequestColors.approvedStatus.withValues(alpha: 0.08)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: controller.goalProgress >= 1.0
                                    ? RequestColors.approvedStatus
                                    : RequestColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'TOTAL HOURS WORKED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: RequestColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            controller.totalHoursText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: controller.goalProgress >= 1.0
                                  ? RequestColors.approvedStatus
                                  : RequestColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: controller.goalProgress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE5E5EA),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            controller.goalProgress >= 1.0
                                ? RequestColors.approvedStatus
                                : RequestColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(controller.goalProgress * 100).toInt()}% of 8.0h goal',
                            style: const TextStyle(
                              fontSize: 11,
                              color: RequestColors.textSecondary,
                            ),
                          ),
                          Text(
                            controller.remainingGoalText == 'Done!'
                                ? 'Goal Reached!'
                                : '${controller.remainingGoalText} remaining',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: controller.goalProgress >= 1.0
                                  ? RequestColors.approvedStatus
                                  : RequestColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Request Time Adjustment button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.request),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text('Request Time Adjustment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RequestColors.textPrimary,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockGoalBadge extends StatelessWidget {
  const _ClockGoalBadge({required this.controller});

  final ClockController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'GOAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: RequestColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${controller.goalHours.toStringAsFixed(1)} hrs',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: RequestColors.approvedStatus,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockSessionTile extends StatelessWidget {
  const _ClockSessionTile({
    required this.sessionNumber,
    required this.sessionName,
    required this.icon,
    required this.iconColor,
    required this.checkInTime,
    required this.checkOutTime,
    required this.scheduledIn,
    required this.scheduledOut,
    required this.statusText,
    required this.isActive,
    required this.isDone,
  });

  final int sessionNumber;
  final String sessionName;
  final IconData icon;
  final Color iconColor;
  final String checkInTime;
  final String checkOutTime;
  final String scheduledIn;
  final String scheduledOut;
  final String statusText;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeBg;
    Color badgeText;
    if (isDone) {
      badgeBg = RequestColors.approvedStatus.withValues(alpha: 0.12);
      badgeText = RequestColors.approvedStatus;
    } else if (isActive && checkInTime != '-- : --') {
      badgeBg = RequestColors.primary.withValues(alpha: 0.12);
      badgeText = RequestColors.primary;
    } else {
      badgeBg = isDark ? AppColors.darkBorder : const Color(0xFFF0F0F2);
      badgeText = RequestColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? RequestColors.primary.withValues(alpha: 0.35)
              : (isDark ? AppColors.darkBorder : const Color(0xFFEBECEF)),
          width: isActive ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 13, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SESSION $sessionNumber • $sessionName',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? RequestColors.primary
                          : (isDark ? AppColors.darkText : RequestColors.textPrimary),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ClockSessionStatItem(
                  label: 'CHECK IN',
                  value: checkInTime,
                  subLabel: 'Scheduled $scheduledIn',
                  isFilled: checkInTime != '-- : --',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
              ),
              Expanded(
                child: _ClockSessionStatItem(
                  label: 'CHECK OUT',
                  value: checkOutTime,
                  subLabel: 'Scheduled $scheduledOut',
                  isFilled: checkOutTime != '-- : --',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockSessionStatItem extends StatelessWidget {
  const _ClockSessionStatItem({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.isFilled,
  });

  final String label;
  final String value;
  final String subLabel;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: RequestColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isFilled
                  ? (isDark ? AppColors.darkText : RequestColors.textPrimary)
                  : const Color(0xFF8E8E93),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: const TextStyle(
              fontSize: 11,
              color: RequestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wi-Fi Status Pill ───────────────────────────────────────────────────────

class _ClockWifiStatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: RequestColors.approvedStatus,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Office Wi-Fi Connected • Main HQ',
            style: TextStyle(
              fontSize: 13,
              color: RequestColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Check In Button ─────────────────────────────────────────────────────────

class _ClockCheckInButton extends StatefulWidget {
  const _ClockCheckInButton({required this.controller});

  final ClockController controller;

  @override
  State<_ClockCheckInButton> createState() => _ClockCheckInButtonState();
}

class _ClockCheckInButtonState extends State<_ClockCheckInButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Color _buttonColor(CheckState state) {
    if (!widget.controller.isCeo && !widget.controller.hasFaceRegistered) {
      return const Color(0xFF7C3AED);
    }
    switch (state) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
      case CheckState.session2NotCheckedIn:
        return RequestColors.primary;
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
      case CheckState.session2CheckedIn:
        return RequestColors.danger;
      case CheckState.completed:
      case CheckState.checkedOut:
        return RequestColors.approvedStatus;
    }
  }

  IconData _buttonIcon(CheckState state) {
    if (!widget.controller.isCeo && !widget.controller.hasFaceRegistered) {
      return Icons.face_retouching_natural_rounded;
    }
    switch (state) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
      case CheckState.session2NotCheckedIn:
        return Icons.wifi_tethering_rounded;
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
      case CheckState.session2CheckedIn:
        return Icons.logout_rounded;
      case CheckState.completed:
      case CheckState.checkedOut:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = widget.controller.state.value;
      final done = state == CheckState.completed || state == CheckState.checkedOut;
      final buttonColor = _buttonColor(state);

      if (done && _pulseController.isAnimating) {
        _pulseController.stop();
      } else if (!done && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }

      return AnimatedBuilder(
        animation: Listenable.merge([_pulseAnim, _tapScale]),
        builder: (context, child) {
          final pulseValue = done ? 0.0 : _pulseAnim.value;

          return Transform.scale(
            scale: _tapScale.value,
            child: GestureDetector(
              onTapDown: done ? null : (_) => _tapController.forward(),
              onTapUp: done
                  ? null
                  : (_) {
                      _tapController.reverse();
                      widget.controller.onMainButtonPressed();
                    },
              onTapCancel: done ? null : () => _tapController.reverse(),
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer dashed ring (ambient)
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _ClockDashedCirclePainter(
                        color: buttonColor.withValues(
                            alpha: 0.15 + pulseValue * 0.10),
                        strokeWidth: 1.5,
                        dashWidth: 6,
                        dashSpace: 4,
                      ),
                    ),
                    // Middle white ring
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withValues(
                                alpha: done ? 0.0 : 0.08 + pulseValue * 0.12),
                            blurRadius: 20 + pulseValue * 10,
                            spreadRadius: 2 + pulseValue * 4,
                          ),
                        ],
                      ),
                    ),
                    // Inner colored button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            buttonColor,
                            Color.lerp(buttonColor, Colors.black, 0.15)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _buttonIcon(state),
                              size: 34,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                widget.controller.buttonLabel,
                                key: ValueKey(widget.controller.buttonLabel),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _ClockDashedCirclePainter extends CustomPainter {
  _ClockDashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashWidth + dashSpace)) / radius - math.pi / 2;
      final sweepAngle = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ClockDashedCirclePainter old) => old.color != color;
}
