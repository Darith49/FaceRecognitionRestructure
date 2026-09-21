import 'dart:math' as math;

import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
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
    return Scaffold(
      backgroundColor: RequestColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _entranceController,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _greetingSlide.value),
                  child: Opacity(
                    opacity: _greetingFade.value,
                    child: child,
                  ),
                ),
                child: _GreetingHeader(controller: controller),
              ),

              const SizedBox(height: 16),

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
                  child: _AttendanceCard(controller: controller),
                ),
              ),

              const SizedBox(height: 32),

              AnimatedBuilder(
                animation: _entranceController,
                builder: (_, child) => Transform.scale(
                  scale: _buttonScale.value,
                  child: Opacity(
                    opacity: _buttonFade.value,
                    child: child,
                  ),
                ),
                child: _CheckInButton(controller: controller),
              ),

              const SizedBox(height: 24),

              // Wi-Fi Status Pill
              _WifiStatusPill(),

              const SizedBox(height: 16),

              // Next schedule
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: RequestColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Next schedule: '),
                      TextSpan(
                        text: 'Tomorrow, 09:00 AM',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: RequestColors.textPrimary,
                        ),
                      ),
                      const TextSpan(text: ' (Normal Shift)'),
                    ],
                  ),
                ),
              ),
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

// ─── Greeting Header ─────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                    width: 50,
                    height: 50,
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
                          fontSize: 18,
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
                      width: 14,
                      height: 14,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: RequestColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: RequestColors.approvedStatus.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
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
                        fontSize: 13,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
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

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.controller});

  final HomeController controller;

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
                _GoalBadge(controller: controller),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          Obx(
            () => IntrinsicHeight(
              child: Row(
                children: [
                  _StatColumn(
                    label: 'CHECK IN',
                    value: controller.checkInText,
                    subLabel: 'Scheduled 09:00',
                  ),
                  Container(width: 1, color: const Color(0xFFF0F0F0)),
                  _StatColumn(
                    label: 'CHECK OUT',
                    value: controller.checkOutText,
                    subLabel: 'Standard 18:00',
                  ),
                  Container(width: 1, color: const Color(0xFFF0F0F0)),
                  _StatColumn(
                    label: 'TOTAL HRS',
                    value: controller.totalHoursText,
                    subLabel: '${(controller.goalProgress * 100).toInt()}% reached',
                    subLabelColor: controller.goalProgress >= 1.0
                        ? RequestColors.approvedStatus
                        : RequestColors.gold,
                  ),
                ],
              ),
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

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({required this.controller});

  final HomeController controller;

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

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.subLabel,
    this.subLabelColor,
  });

  final String label;
  final String value;
  final String? subLabel;
  final Color? subLabelColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
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
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: RequestColors.textPrimary,
              ),
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              subLabel!,
              style: TextStyle(
                fontSize: 11,
                color: subLabelColor ?? RequestColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Wi-Fi Status Pill ───────────────────────────────────────────────────────

class _WifiStatusPill extends StatelessWidget {
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

class _CheckInButton extends StatefulWidget {
  const _CheckInButton({required this.controller});

  final HomeController controller;

  @override
  State<_CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<_CheckInButton>
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
    switch (state) {
      case CheckState.notCheckedIn:
        return RequestColors.primary;
      case CheckState.checkedIn:
        return RequestColors.danger;
      case CheckState.checkedOut:
        return RequestColors.approvedStatus;
    }
  }

  IconData _buttonIcon(CheckState state) {
    switch (state) {
      case CheckState.notCheckedIn:
        return Icons.wifi_tethering_rounded;
      case CheckState.checkedIn:
        return Icons.logout_rounded;
      case CheckState.checkedOut:
        return Icons.check_rounded;
    }
  }

  String _buttonSubtext(CheckState state) {
    switch (state) {
      case CheckState.notCheckedIn:
        return 'Face or Tap ID';
      case CheckState.checkedIn:
        return 'Tap to finish shift';
      case CheckState.checkedOut:
        return 'Shift Recorded';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = widget.controller.state.value;
      final done = state == CheckState.checkedOut;
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
                      painter: _DashedCirclePainter(
                        color: buttonColor.withValues(alpha: 0.15 + pulseValue * 0.10),
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
                            color: buttonColor.withValues(alpha: done ? 0.0 : 0.08 + pulseValue * 0.12),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _buttonIcon(state),
                            size: 32,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              widget.controller.buttonLabel,
                              key: ValueKey(widget.controller.buttonLabel),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buttonSubtext(state),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
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

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
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
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
