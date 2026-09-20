import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Details of one request. Opened with: Get.toNamed(AppRoutes.requestDetail, arguments: request)
/// A pending request also shows the red "Cancel Request" button.
class RequestDetailScreen extends GetView<PermissionController> {
  const RequestDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    if (args is! PermissionRequest) {
      return const RequestScaffold(
        title: 'Permission',
        body: Center(child: Text('This request could not be found.')),
      );
    }

    final PermissionRequest request = args;
    final isPending = request.status == RequestStatus.pending;

    return RequestScaffold(
      title: 'Permission',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RequestField(label: 'Request Type', value: request.type),
                const SizedBox(height: 14),
                RequestField(label: 'Full Name', value: request.fullName),
                const SizedBox(height: 14),
                RequestField(label: 'EmployeeID', value: request.employeeId),
                const SizedBox(height: 14),
                RequestField(label: 'Time', value: request.timeLabel),
                const SizedBox(height: 14),
                RequestField(
                  label: 'Reason',
                  value: request.reason,
                  multiline: true,
                ),
                const SizedBox(height: 14),
                RequestField(
                  label: 'Status',
                  value: request.status.label,
                  valueColor: isPending
                      ? RequestColors.pendingText
                      : RequestColors.approvedStatus,
                  valueWeight: FontWeight.w600,
                ),
                if (!isPending && request.authorizedAt != null) ...[
                  const SizedBox(height: 14),
                  RequestField(
                    label: 'Authorized Date',
                    value: DateText.stamp(request.authorizedAt!),
                  ),
                ],
              ],
            ),
          ),
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmCancel(context, request),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequestColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    PermissionRequest request,
  ) async {
    // Get the messenger before the await, so we do not use `context` after it.
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text(
          'The request will be removed from your pending list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep request'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Yes, cancel',
              style: TextStyle(color: RequestColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    controller.cancelRequest(request.id);
    Get.back();
    RequestSnack.show(messenger, 'Your request was cancelled.');
  }
}
