import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/controller/overtime_controller.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Read-only view of one overtime request (used for Approved ones).
/// Opened with: Get.toNamed(AppRoutes.overtimeDetail, arguments: request.id)
class OvertimeDetailScreen extends GetView<OvertimeController> {
  const OvertimeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final request = args is String ? controller.findById(args) : null;

    if (request == null) {
      return const RequestScaffold(
        title: 'Overtime',
        body: Center(child: Text('This request could not be found.')),
      );
    }

    final isPending = request.status == OvertimeStatus.pending;

    return RequestScaffold(
      title: 'Overtime',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RequestField(label: 'Full Name', value: request.fullName),
          const SizedBox(height: 14),
          RequestField(label: 'EmployeeID', value: request.employeeId),
          const SizedBox(height: 14),
          RequestField(
            label: 'Date',
            value: DateText.monthShortDay(request.date),
          ),
          const SizedBox(height: 14),
          RequestField(label: 'Time', value: request.timeRangeLabel),
          const SizedBox(height: 14),
          RequestField(label: 'Duration', value: request.durationLabel),
          const SizedBox(height: 14),
          RequestField(label: 'Reason', value: request.reason, multiline: true),
          const SizedBox(height: 14),
          RequestField(
            label: 'Status',
            value: request.status.label,
            valueColor: isPending
                ? RequestColors.pendingText
                : RequestColors.approvedStatus,
            valueWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
