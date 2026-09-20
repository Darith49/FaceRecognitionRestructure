import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/controller/overtime_controller.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Form: Date, From Time, To Time (with live Duration), Reason.
/// "Submit" adds the request as Pending and returns to the Overtime List.
///
/// Edit mode: opened with `arguments: <request id>` for a PENDING request.
/// The form is pre-filled and the button becomes "UPDATE".
class RequestOvertimeScreen extends StatefulWidget {
  const RequestOvertimeScreen({super.key});

  @override
  State<RequestOvertimeScreen> createState() => _RequestOvertimeScreenState();
}

class _RequestOvertimeScreenState extends State<RequestOvertimeScreen> {
  final OvertimeController _controller = Get.find<OvertimeController>();
  final TextEditingController _reasonController = TextEditingController();

  late DateTime _date;
  late DateTime _fromTime;
  late DateTime _toTime;

  /// TODO: wire up a real image picker; for now this only marks intent.
  bool _hasAttachment = false;

  /// Set only when editing an existing Pending request.
  String? _editId;

  bool get _isEditing => _editId != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateUtils.dateOnly(now);
    _fromTime = DateTime(_date.year, _date.month, _date.day, 17, 0);
    _toTime = DateTime(_date.year, _date.month, _date.day, 18, 0);

    final args = Get.arguments;
    if (args is String) {
      final existing = _controller.findById(args);
      // Approved requests are never editable: they open the read-only page.
      if (existing != null && existing.status == OvertimeStatus.pending) {
        _editId = existing.id;
        _date = existing.date;
        _fromTime = existing.fromTime;
        _toTime = existing.toTime;
        _hasAttachment = existing.hasAttachment;
        _reasonController.text = existing.reason;
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Duration get _duration => _toTime.difference(_fromTime);

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _date.isBefore(today) ? _date : today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _date = picked;
      _fromTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _fromTime.hour,
        _fromTime.minute,
      );
      _toTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _toTime.hour,
        _toTime.minute,
      );
    });
  }

  Future<void> _pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isFrom ? _fromTime : _toTime),
    );
    if (picked == null || !mounted) return;

    final result = DateTime(
      _date.year,
      _date.month,
      _date.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      if (isFrom) {
        _fromTime = result;
      } else {
        _toTime = result;
      }
    });
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      RequestSnack.show(messenger, 'Enter the reason for the overtime.');
      return;
    }
    if (!_toTime.isAfter(_fromTime)) {
      RequestSnack.show(messenger, 'To time must be after from time.');
      return;
    }

    if (_isEditing) {
      final updated = _controller.updateRequest(
        _editId!,
        date: _date,
        fromTime: _fromTime,
        toTime: _toTime,
        reason: reason,
        hasAttachment: _hasAttachment,
      );

      Get.back();
      RequestSnack.show(
        messenger,
        updated
            ? 'Your overtime request was updated.'
            : 'This request was already approved, so it cannot be edited.',
      );
      return;
    }

    _controller.addRequest(
      date: _date,
      fromTime: _fromTime,
      toTime: _toTime,
      reason: reason,
      hasAttachment: _hasAttachment,
    );

    Get.back();
    RequestSnack.show(messenger, 'Your overtime request was submitted.');
  }

  /// "1 hour" / "1 hour 30 minutes" / "2 hours"
  String get _durationLabel {
    final minutes = _duration.inMinutes;
    if (minutes <= 0) return '—';

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    final parts = <String>[];
    if (hours > 0) parts.add('$hours hour${hours == 1 ? '' : 's'}');
    if (remaining > 0) {
      parts.add('$remaining minute${remaining == 1 ? '' : 's'}');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: _isEditing ? 'Edit Overtime' : 'Request Overtime',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Date:',
                      icon: Icons.calendar_month_outlined,
                      value: DateText.monthShortDay(_date),
                      onChange: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'From Time:',
                      icon: Icons.access_time_rounded,
                      value: DateText.time(_fromTime),
                      onChange: () => _pickTime(true),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'To Time:',
                      icon: Icons.access_time_rounded,
                      value: DateText.time(_toTime),
                      onChange: () => _pickTime(false),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Duration: $_durationLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: RequestColors.gold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const RequestLabel('Reason:'),
                    _buildReasonField(),
                    const SizedBox(height: 12),
                    _buildAttachButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            RequestButton(
              label: _isEditing ? 'UPDATE' : 'SUBMIT',
              onPressed: _submit,
            ),
          ],
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
        hintText: 'Please write your reason here...',
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

  Widget _buildAttachButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          setState(() => _hasAttachment = !_hasAttachment);
          RequestSnack.show(
            ScaffoldMessenger.of(context),
            _hasAttachment ? 'Image attached.' : 'Image removed.',
          );
        },
        icon: Icon(
          _hasAttachment
              ? Icons.check_circle_rounded
              : Icons.attach_file_rounded,
          size: 18,
          color: RequestColors.primary,
        ),
        label: Text(_hasAttachment ? 'Image Attached' : 'Attach Image'),
        style: TextButton.styleFrom(
          foregroundColor: RequestColors.primary,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChange,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequestLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: RequestColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textPrimary,
                  ),
                ),
              ),
              _ChangePill(onTap: onChange),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small blue "Change" pill button, matching the Figma design.
class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDCE9FF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            'Change',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RequestColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
