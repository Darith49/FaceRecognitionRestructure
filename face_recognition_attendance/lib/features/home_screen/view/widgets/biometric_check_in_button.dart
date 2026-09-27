import 'dart:math' as math;
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Animated pulsing biometric Face Check-In & Check-Out trigger button.
class BiometricCheckInButton extends StatefulWidget {
  const BiometricCheckInButton({super.key, required this.controller});

  final HomeController controller;

  @override
  State<BiometricCheckInButton> createState() => _BiometricCheckInButtonState();
}

class _BiometricCheckInButtonState extends State<BiometricCheckInButton>
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

    _tapScale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Color _buttonColor(CheckState state) {
    if (!widget.controller.hasFaceRegistered) {
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
    if (!widget.controller.hasFaceRegistered) {
      return FluentIcons.camera_24_regular;
    }
    switch (state) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
      case CheckState.session2NotCheckedIn:
        return FluentIcons.wifi_1_24_regular;
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
      case CheckState.session2CheckedIn:
        return FluentIcons.sign_out_24_regular;
      case CheckState.completed:
      case CheckState.checkedOut:
        return FluentIcons.checkmark_24_regular;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = widget.controller.state.value;
      final done =
          state == CheckState.completed || state == CheckState.checkedOut;
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
                        color: buttonColor.withValues(
                          alpha: 0.15 + pulseValue * 0.10,
                        ),
                        strokeWidth: 1.5,
                        dashWidth: 6,
                        dashSpace: 4,
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkCard
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withValues(
                              alpha: done ? 0.0 : 0.08 + pulseValue * 0.12,
                            ),
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
