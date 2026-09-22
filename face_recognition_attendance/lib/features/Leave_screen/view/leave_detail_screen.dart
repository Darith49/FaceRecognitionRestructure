import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Leave_screen/controller/leave_controller.dart';
import 'package:face_recognition_attendance/features/Leave_screen/model/leave_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Read-only view of one leave request (used for Approved ones).
/// Opened with: Get.toNamed(AppRoutes.leaveDetail, arguments: request.id)
class LeaveDetailScreen extends GetView<LeaveController> {
  const LeaveDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final request = args is String ? controller.findById(args) : null;

    if (request == null) {
      return const RequestScaffold(
        title: 'Leave',
        body: Center(child: Text('This request could not be found.')),
      );
    }

    final isPending = request.status == LeaveStatus.pending;

    return RequestScaffold(
      title: 'Leave',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RequestField(label: 'Full Name', value: request.fullName),
          const SizedBox(height: 14),
          RequestField(label: 'EmployeeID', value: request.employeeId),
          const SizedBox(height: 14),
          RequestField(label: 'Date', value: request.dateRangeLabel),
          const SizedBox(height: 14),
          RequestField(label: 'Leave Time', value: request.scheduleLabel),
          const SizedBox(height: 14),
          RequestField(
            label: 'Total Days',
            value: '${request.dayCount} day${request.dayCount == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 14),
          RequestField(label: 'Reason', value: request.reason, multiline: true),
          if (request.hasAttachment) ...[
            const SizedBox(height: 14),
            RequestField(
              label: 'Supporting Document',
              value: request.attachmentName ?? 'Document Attached',
              valueColor: RequestColors.primary,
              valueWeight: FontWeight.w600,
            ),
          ],
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
