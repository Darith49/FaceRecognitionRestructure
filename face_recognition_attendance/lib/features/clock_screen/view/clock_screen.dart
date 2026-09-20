import 'dart:math' as math;

import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/clock_screen/controller/clock_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClockScreen extends GetView<ClockController> {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Clock Attendance',
      centerTitle: true,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TimeCard(controller: controller),
          const SizedBox(height: 56),
          Center(child: _CheckButton(controller: controller)),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.controller});

  final ClockController controller;

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
                      Text(
                        DateText.clock(controller.now.value),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: RequestColors.textPrimary,
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
          IntrinsicHeight(
            child: Obx(
              () => Row(
                children: [
                  _Stat(
                    label: 'Check in',
                    value: controller.checkInText,
                  ),
                  const VerticalDivider(width: 1),
                  _Stat(
                    label: 'Check out',
                    value: controller.checkOutText,
                  ),
                  const VerticalDivider(width: 1),
                  _Stat(
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

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
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: RequestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressRing extends StatelessWidget {
  const _GoalProgressRing({required this.controller});

  final ClockController controller;

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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: RequestColors.primary,
                      ),
                    ),
                  if (reached)
                    Text(
                      'Done!',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B9A3A),
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

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.controller});

  final ClockController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final done = controller.state.value == ClockState.checkedOut;

      return GestureDetector(
        onTap: done ? null : controller.onMainButtonPressed,
        child: Container(
          width: 200,
          height: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF9AA3B5) : RequestColors.primary,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: (done ? const Color(0xFF9AA3B5) : RequestColors.primary)
                      .withValues(alpha: done ? 0.0 : 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              controller.buttonLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}
