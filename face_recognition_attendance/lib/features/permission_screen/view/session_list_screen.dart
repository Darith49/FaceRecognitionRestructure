import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Request List": the sessions the user added. Submit sends them all as Pending requests.
class SessionListScreen extends GetView<PermissionController> {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Request Permission',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: () => Get.toNamed(
                AppRoutes.requestPermission,
                arguments: {'fromSessionList': true},
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add another session'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RequestColors.textPrimary,
                side: const BorderSide(color: RequestColors.textPrimary),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const RequestLabel('Request List'),
            Expanded(
              child: Obx(() {
                final count = controller.draftSessions.length;

                if (count == 0) {
                  return const Align(
                    alignment: Alignment.topCenter,
                    child: _EmptyBar(),
                  );
                }

                return ListView.separated(
                  itemCount: count,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _SessionTile(
                    session: controller.draftSessions[index],
                    onDelete: () => controller.removeSessionAt(index),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            RequestButton(label: 'Submit', onPressed: () => _submit(context)),
            const SizedBox(height: 10),
            RequestButton(
              label: 'Cancel',
              filled: false,
              onPressed: _cancel,
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    if (controller.draftSessions.isEmpty) {
      RequestSnack.show(messenger, 'Add at least one session before submitting.');
      return;
    }

    final count = controller.submitDraftSessions();
    Get.back();
    RequestSnack.show(
      messenger,
      count == 1
          ? 'Your permission request was submitted.'
          : '$count permission requests were submitted.',
    );
  }

  void _cancel() {
    controller.clearDrafts();
    Get.back();
  }
}

class _EmptyBar extends StatelessWidget {
  const _EmptyBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Text(
          'No added request',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: RequestColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onDelete});

  final PermissionSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.white,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: RequestColors.teal),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _line(
                              Icons.calendar_month_outlined,
                              DateText.ymd(session.date),
                              RequestColors.textPrimary,
                              FontWeight.w700,
                            ),
                            const SizedBox(height: 6),
                            _line(
                              Icons.timer_outlined,
                              session.schedule,
                              RequestColors.gold,
                              FontWeight.w600,
                            ),
                            const SizedBox(height: 6),
                            _line(
                              Icons.edit_note_rounded,
                              session.reason,
                              RequestColors.textPrimary,
                              FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: const Color(0xFFFFD9D2),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onDelete,
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: RequestColors.danger,
                              size: 20,
                            ),
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
  }

  Widget _line(IconData icon, String text, Color color, FontWeight weight) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: weight, color: color),
          ),
        ),
      ],
    );
  }
}
