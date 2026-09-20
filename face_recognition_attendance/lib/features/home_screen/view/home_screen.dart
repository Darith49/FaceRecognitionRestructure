import 'dart:math' as math;

import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
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
          padding: const EdgeInsets.only(bottom: 120),
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

              const SizedBox(height: 20),

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

              const SizedBox(height: 40),

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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Obx(
        () => Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RequestColors.primary.withValues(alpha: 0.12),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.greeting}, ${controller.userName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Have a productive day',
                    style: TextStyle(
                      fontSize: 13,
                      color: RequestColors.textSecondary,
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: RequestColors.textPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: RequestColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateText.fullDate(controller.now.value),
                        style: const TextStyle(
                          fontSize: 12,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _GoalProgressRing(controller: controller),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Obx(
            () => IntrinsicHeight(
              child: Row(
                children: [
                  _AnimatedStatColumn(
                    label: 'Check in',
                    value: controller.checkInText,
                  ),
                  const VerticalDivider(width: 1),
                  _AnimatedStatColumn(
                    label: 'Check out',
                    value: controller.checkOutText,
                  ),
                  const VerticalDivider(width: 1),
                  _AnimatedStatColumn(
                    label: 'Total Hrs',
                    value: controller.totalHoursText,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          RequestButton(
            label: 'Request',
            onPressed: () => Get.toNamed(AppRoutes.request),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressRing extends StatelessWidget {
  const _GoalProgressRing({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.goalProgress;
    final reached = progress >= 1.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _GoalRingPainter(
              progress: animatedProgress,
              reached: reached,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reached ? '✓' : 'Goal',
                    style: TextStyle(
                      fontSize: reached ? 12 : 9,
                      fontWeight: FontWeight.w600,
                      color: reached
                          ? const Color(0xFF1B9A3A)
                          : RequestColors.primary,
                    ),
                  ),
                  if (!reached)
                    Text(
                      controller.remainingGoalText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: RequestColors.primary,
                      ),
                    ),
                  if (reached)
                    Text(
                      'Done!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B9A3A),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter({required this.progress, required this.reached});

  final double progress;
  final bool reached;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    const strokeWidth = 4.0;

    final bgPaint = Paint()
      ..color = (reached ? const Color(0xFF1B9A3A) : RequestColors.primary)
          .withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = reached ? const Color(0xFF1B9A3A) : RequestColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.reached != reached;
}

class _AnimatedStatColumn extends StatelessWidget {
  const _AnimatedStatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                fontSize: 12,
                color: RequestColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _tapScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _tapController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _tapController.reverse();
    widget.controller.onMainButtonPressed();
  }

  void _onTapCancel() {
    _tapController.reverse();
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
              onTapDown: done ? null : _onTapDown,
              onTapUp: done ? null : _onTapUp,
              onTapCancel: done ? null : _onTapCancel,
              child: Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  width: 132,
                  height: 132,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: buttonColor,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withValues(
                            alpha: done ? 0.0 : 0.15 + pulseValue * 0.25),
                        blurRadius: 20 + pulseValue * 16,
                        spreadRadius: 1 + pulseValue * 4,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      widget.controller.buttonLabel,
                      key: ValueKey(widget.controller.buttonLabel),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
