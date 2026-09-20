import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());

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
              // ── Greeting Header ──
              _GreetingHeader(controller: controller),

              const SizedBox(height: 20),

              // ── Time & Attendance Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AttendanceCard(controller: controller),
              ),

              const SizedBox(height: 40),

              // ── Check In Button ──
              _CheckInButton(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Header
// ─────────────────────────────────────────────────────────────────────────────

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
            // Avatar
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

  /// Return up to two initials from the full name.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance Info Card
// ─────────────────────────────────────────────────────────────────────────────

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
          // ── Top row: clock icon + time/date + goal badge ──
          Obx(
            () => Row(
              children: [
                // Clock icon box
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
                // Time + date
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
                // Goal badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RequestColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: RequestColors.primary.withValues(alpha: 0.3),
                      width: 2.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Goal',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: RequestColors.primary,
                        ),
                      ),
                      Text(
                        '${controller.goalHours.toInt()}h',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: RequestColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Stats row: check in / check out / total hrs ──
          Obx(
            () => IntrinsicHeight(
              child: Row(
                children: [
                  _StatColumn(
                    label: 'Check in',
                    value: controller.checkInText,
                  ),
                  const VerticalDivider(width: 1),
                  _StatColumn(
                    label: 'Check out',
                    value: controller.checkOutText,
                  ),
                  const VerticalDivider(width: 1),
                  _StatColumn(
                    label: 'Total Hrs',
                    value: controller.totalHoursText,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Request button ──
          RequestButton(
            label: 'Request',
            onPressed: () => Get.toNamed(AppRoutes.request),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Column (reusable for the Check in / Check out / Total Hrs row)
// ─────────────────────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

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

// ─────────────────────────────────────────────────────────────────────────────
// Check In Button (large circular button)
// ─────────────────────────────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final done = controller.state.value == CheckState.checkedOut;

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
          child: Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF9AA3B5) : RequestColors.primary,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: done
                  ? null
                  : [
                      BoxShadow(
                        color: RequestColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
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
