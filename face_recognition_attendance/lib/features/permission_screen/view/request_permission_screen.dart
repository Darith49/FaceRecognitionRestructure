import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
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

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );

    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  void _add() {
    final messenger = ScaffoldMessenger.of(context);
    final date = _date;
    final reason = _reasonController.text.trim();

    if (date == null) {
      RequestSnack.show(messenger, 'Pick a date first.');
      return;
    }
    if (reason.isEmpty) {
      RequestSnack.show(messenger, 'Enter the reason for your request.');
      return;
    }

    final added = _controller.addSession(
      PermissionSession(date: date, schedule: _schedule, reason: reason),
    );
    if (!added) {
      RequestSnack.show(
        messenger,
        'That date and schedule is already in your list.',
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
      title: 'Request Permission',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RequestLabel('Pick Date'),
                    _buildDateButton(),
                    const SizedBox(height: 16),
                    const RequestLabel('Schedule'),
                    _buildScheduleDropdown(),
                    const SizedBox(height: 16),
                    const RequestLabel('Reason'),
                    _buildReasonField(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            RequestButton(label: 'Add', onPressed: _add),
            const SizedBox(height: 10),
            RequestButton(
              label: 'Back to session list',
              filled: false,
              onPressed: _goToSessionList,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickDate,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Center(
            child: Text(
              _date == null ? 'Select Date' : DateText.ymd(_date!),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RequestColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _schedule,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: RequestColors.textPrimary,
          ),
          items: kSessionSchedules
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _schedule = value);
          },
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return TextField(
      controller: _reasonController,
      minLines: 5,
      maxLines: 5,
      style: const TextStyle(fontSize: 13, color: RequestColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Enter reasons for leave',
        hintStyle: const TextStyle(
          fontSize: 13,
          color: RequestColors.textSecondary,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
