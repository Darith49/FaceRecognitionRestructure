import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Form: Pick Date, Schedule, Reason. "Add" puts the session in the Request List.
class RequestPermissionScreen extends StatefulWidget {
  const RequestPermissionScreen({super.key});

  @override
  State<RequestPermissionScreen> createState() =>
      _RequestPermissionScreenState();
}

class _RequestPermissionScreenState extends State<RequestPermissionScreen> {
  final PermissionController _controller = Get.find<PermissionController>();
  final TextEditingController _reasonController = TextEditingController();

  DateTime? _date;
  String _schedule = kSessionSchedules.first;

  /// True when the user came from the Request List ("Add another session").
  late final bool _openedFromSessionList;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _openedFromSessionList = args is Map && args['fromSessionList'] == true;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _add() {
    final messenger = ScaffoldMessenger.of(context);
    final date = _date;
    final reason = _reasonController.text.trim();

    if (date == null) {
      RequestSnack.show(messenger, 'Pick a date first.'.tr);
      return;
    }
    if (reason.isEmpty) {
      RequestSnack.show(messenger, 'Enter the reason for your request.'.tr);
      return;
    }

    final added = _controller.addSession(
      PermissionSession(date: date, schedule: _schedule, reason: reason),
    );
    if (!added) {
      RequestSnack.show(
        messenger,
        'You already have a request for that date and schedule.'.tr,
      );
      return;
    }

    _goToSessionList();
  }

  void _goToSessionList() {
    if (_openedFromSessionList) {
      Get.back();
    } else {
      // Replace the form with the list, so "back" returns to the Permission menu.
      Get.offNamed(AppRoutes.permissionSessions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Request Permission'.tr,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RequestLabel('Pick Date'.tr),
                    RequestDateField(
                      value: _date,
                      onChanged: (date) => setState(() => _date = date),
                    ),
                    const SizedBox(height: 16),
                    RequestLabel('Schedule'.tr),
                    RequestDropdownField<String>(
                      value: _schedule,
                      items: kSessionSchedules
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: (schedule) =>
                          setState(() => _schedule = schedule),
                    ),
                    const SizedBox(height: 16),
                    RequestLabel('Reason'.tr),
                    RequestTextArea(controller: _reasonController),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            RequestButton(label: 'Add'.tr, onPressed: _add),
            const SizedBox(height: 10),
            RequestButton(
              label: 'Back to session list'.tr,
              filled: false,
              onPressed: _goToSessionList,
            ),
          ],
        ),
      ),
    );
  }
}
