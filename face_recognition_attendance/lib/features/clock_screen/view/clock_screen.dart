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

/// Card with the live time, check in / check out / total hours and the Request button.
class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.controller});

  final ClockController controller;

  String _time(DateTime? value) =>
      value == null ? '-- : --' : DateText.clock(value);

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
          Row(
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
              Obx(
                () => Column(
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
            ],
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
                    value: _time(controller.checkInTime.value),
                  ),
                  const VerticalDivider(width: 1),
                  _Stat(
                    label: 'Check out',
                    value: _time(controller.checkOutTime.value),
                  ),
                  const VerticalDivider(width: 1),
                  _Stat(
                    label: 'Total Hours',
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

/// The big round Check In / Check Out button.
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
          child: Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? const Color(0xFF9AA3B5) : RequestColors.primary,
              border: Border.all(color: Colors.white, width: 5),
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
