import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/download_report_dialog.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/controller/overtime_controller.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/service/overtime_report_pdf.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Overtime List": every overtime request the user submitted.
class OvertimeListScreen extends GetView<OvertimeController> {
  const OvertimeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Overtime List',
      body: Obx(() {
        final items = controller.requests;

        if (items.isEmpty) {
          return const _EmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OvertimeTile(
            request: items[index],
            // Pending -> edit form. Approved -> read-only details.
            onTap: () => Get.toNamed(
              items[index].status == OvertimeStatus.pending
                  ? AppRoutes.requestOvertime
                  : AppRoutes.overtimeDetail,
              arguments: items[index].id,
            ),
            onCancel: items[index].status == OvertimeStatus.pending
                ? () => controller.cancelRequest(items[index].id)
                : null,
          ),
        );
      }),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'overtime-download',
            backgroundColor: RequestColors.primary,
            onPressed: () => _downloadReport(context),
            child: const Icon(
              Icons.file_download_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'overtime-add',
            backgroundColor: RequestColors.primary,
            onPressed: () => Get.toNamed(AppRoutes.requestOvertime),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Download button: pick a period, then build the PDF and open the share / save sheet.
  Future<void> _downloadReport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final period = await showDownloadReportDialog(context);
    if (period == null) return;

    final records = controller.requestsIn(period);
    if (records.isEmpty) {
      RequestSnack.show(
        messenger,
        'No overtime records for ${period.label}.',
      );
      return;
    }

    try {
      await OvertimeReportPdf.share(requests: records, period: period);
    } catch (_) {
      RequestSnack.show(
        messenger,
        'Could not create the PDF. Please try again.',
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Color(0xFFC7CBD6),
                ),
                Positioned(
                  right: 4,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No records',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You have no record at the moment.',
            style: TextStyle(fontSize: 12, color: RequestColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OvertimeTile extends StatelessWidget {
  const _OvertimeTile({
    required this.request,
    required this.onTap,
    this.onCancel,
  });

  final OvertimeRequest request;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == OvertimeStatus.pending;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateText.monthShortDay(request.date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? RequestColors.pendingBackground
                          : RequestColors.approvedBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      request.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPending
                            ? RequestColors.pendingText
                            : RequestColors.approvedText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: RequestColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${request.timeRangeLabel}  •  ${request.durationLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                request.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: RequestColors.textSecondary,
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: RequestColors.danger,
                    ),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        color: RequestColors.danger,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
