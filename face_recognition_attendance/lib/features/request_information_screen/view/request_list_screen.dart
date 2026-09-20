import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One screen for both lists:
/// status = pending  -> "Unauthorized"
/// status = approved -> "Authorized"
class RequestListScreen extends GetView<PermissionController> {
  const RequestListScreen({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == RequestStatus.pending;

    return RequestScaffold(
      title: isPending ? 'Unauthorized' : 'Authorized',
      body: Obx(() {
        final items = controller.requestsWithStatus(status);

        if (items.isEmpty) {
          return Center(
            child: Text(
              isPending ? 'No pending requests' : 'No approved requests',
              style: const TextStyle(
                fontSize: 13,
                color: RequestColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _RequestTile(request: items[index]),
        );
      }),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.toNamed(AppRoutes.requestDetail, arguments: request),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateText.weekdayYmd(request.date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.schedule,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == RequestStatus.pending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPending
            ? RequestColors.pendingBackground
            : RequestColors.approvedBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPending
              ? RequestColors.pendingText
              : RequestColors.approvedText,
        ),
      ),
    );
  }
}
