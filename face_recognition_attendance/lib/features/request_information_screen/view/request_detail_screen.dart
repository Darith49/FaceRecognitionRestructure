import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/permission_screen/controller/permission_controller.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Details of one request (Unauthorized = Pending, Authorized = Approved).
/// Opened with: Get.toNamed(AppRoutes.requestDetail, arguments: request)
///
/// - Date, Schedule and Reason can be changed, then saved with "Save changes".
/// - Request Type, Full Name, EmployeeID, Status and Authorized Date are read-only.
/// - A request whose date has passed cannot be changed.
/// - Changing an approved request sends it back to Pending.
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final PermissionController _controller = Get.find<PermissionController>();
  final TextEditingController _reasonController = TextEditingController();

  PermissionRequest? _request;
  DateTime _date = DateTime.now();
  String _schedule = kSessionSchedules.first;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args is PermissionRequest) {
      _request = args;
      _date = args.date;
      _schedule = args.schedule;
      _reasonController.text = args.reason;
    }

    // Rebuild while typing, so "Save changes" turns on/off.
    _reasonController.addListener(_refresh);
  }

  @override
  void dispose() {
    _reasonController.removeListener(_refresh);
    _reasonController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// True when the user changed something.
  bool get _hasChanges {
    final request = _request!;
    return DateText.ymd(_date) != DateText.ymd(request.date) ||
        _schedule != request.schedule ||
        _reasonController.text.trim() != request.reason;
  }

  Future<void> _save() async {
    final request = _request!;
    final messenger = ScaffoldMessenger.of(context);
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      RequestSnack.show(messenger, 'Enter the reason for your request.');
      return;
    }

    final wasApproved = request.status == RequestStatus.approved;
    if (wasApproved) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Change this approved request?'),
          content: const Text(
            'After you save, the request goes back to Pending and needs approval again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Keep as approved'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Yes, change it'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final error = await _controller.updateRequest(
      id: request.id,
      date: _date,
      schedule: _schedule,
      reason: reason,
    );
    if (error != null) {
      RequestSnack.show(messenger, error);
      return;
    }

    Get.back();
    RequestSnack.show(
      messenger,
      wasApproved
          ? 'Saved. The request is Pending again and needs approval.'
          : 'Your changes were saved.',
    );
  }

  Future<void> _confirmCancel() async {
    final request = _request!;
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

    await _controller.cancelRequest(request.id);
    Get.back();
    RequestSnack.show(messenger, 'Your request was cancelled.');
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    if (request == null) {
      return const RequestScaffold(
        title: 'Permission',
        body: Center(child: Text('This request could not be found.')),
      );
    }

    final isPending = request.status == RequestStatus.pending;
    final editable = !request.hasPassed;

    return RequestScaffold(
      title: 'Permission',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!editable) const _LockedNote(),
                RequestField(label: 'Request Type', value: request.type),
                const SizedBox(height: 14),
                RequestField(label: 'Full Name', value: request.fullName),
                const SizedBox(height: 14),
                RequestField(label: 'EmployeeID', value: request.employeeId),
                const SizedBox(height: 14),
                if (editable) ..._buildEditableFields(request) else ...[
                  RequestField(label: 'Time', value: request.timeLabel),
                  const SizedBox(height: 14),
                  RequestField(
                    label: 'Reason',
                    value: request.reason,
                    multiline: true,
                  ),
                  const SizedBox(height: 14),
                ],
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
          if (editable || isPending) _buildActions(editable, isPending),
        ],
      ),
    );
  }

  /// The inputs the user can change: Date, Schedule, Reason.
  List<Widget> _buildEditableFields(PermissionRequest request) {
    return [
      const RequestLabel('Date'),
      RequestDateField(
        value: _date,
        onChanged: (date) => setState(() => _date = date),
      ),
      const SizedBox(height: 14),
      const RequestLabel('Schedule'),
      RequestDropdownField<String>(
        value: _schedule,
        items: scheduleOptionsFor(request.schedule)
            .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
            .toList(),
        onChanged: (schedule) => setState(() => _schedule = schedule),
      ),
      const SizedBox(height: 14),
      const RequestLabel('Reason'),
      RequestTextArea(controller: _reasonController),
      const SizedBox(height: 14),
    ];
  }

  Widget _buildActions(bool editable, bool isPending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editable)
            RequestButton(
              label: 'Save changes',
              onPressed: _hasChanges ? _save : null,
            ),
          if (editable && isPending) const SizedBox(height: 10),
          if (isPending)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _confirmCancel,
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
        ],
      ),
    );
  }
}

/// Shown at the top when the request date has passed and nothing can be changed.
class _LockedNote extends StatelessWidget {
  const _LockedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RequestColors.pendingBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: RequestColors.pendingText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This date has already passed, so the request can no longer be changed.',
              style: TextStyle(fontSize: 12, color: RequestColors.pendingText),
            ),
          ),
        ],
      ),
    );
  }
}
