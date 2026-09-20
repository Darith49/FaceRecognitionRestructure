import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Leave_screen/controller/leave_controller.dart';
import 'package:face_recognition_attendance/features/Leave_screen/model/leave_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Form: From Date, To Date, Full Day / Morning / Afternoon / Time, Reason.
/// "Submit" adds the request as Pending and returns to the Leave list.
///
/// Edit mode: opened with `arguments: <request id>` for a PENDING request.
/// The form is pre-filled and the button becomes "UPDATE".
class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final LeaveController _controller = Get.find<LeaveController>();
  final TextEditingController _reasonController = TextEditingController();

  late DateTime _fromDate;
  late DateTime _toDate;
  String _dayType = kLeaveDayTypes.first;
  DateTime? _fromTime;
  DateTime? _toTime;

  /// TODO: wire up a real image picker; for now this only marks intent.
  bool _hasAttachment = false;

  /// Set only when editing an existing Pending request.
  String? _editId;

  bool get _isEditing => _editId != null;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _fromDate = today;
    _toDate = today;

    final args = Get.arguments;
    if (args is String) {
      final existing = _controller.findById(args);
      // Approved requests are never editable: they open the read-only page.
      if (existing != null && existing.status == LeaveStatus.pending) {
        _editId = existing.id;
        _fromDate = existing.fromDate;
        _toDate = existing.toDate;
        _dayType = existing.dayType;
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

  Future<void> _pickFromDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: _fromDate.isBefore(today) ? _fromDate : today,
      lastDate: DateTime(_fromDate.year + 2, _fromDate.month, _fromDate.day),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _fromDate = picked;
      if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(_fromDate.year + 2, _fromDate.month, _fromDate.day),
    );
    if (picked != null && mounted) {
      setState(() => _toDate = picked);
    }
  }

  Future<void> _pickTime(bool isFrom) async {
    final initial = isFrom
        ? (_fromTime ?? DateTime.now())
        : (_toTime ?? _fromTime ?? DateTime.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked == null || !mounted) return;

    final result = DateTime(
      _fromDate.year,
      _fromDate.month,
      _fromDate.day,
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
      RequestSnack.show(messenger, 'Enter the reason for your leave.');
      return;
    }
    if (_dayType == 'Time' && (_fromTime == null || _toTime == null)) {
      RequestSnack.show(messenger, 'Pick a from and to time.');
      return;
    }
    if (_dayType == 'Time' &&
        _fromTime != null &&
        _toTime != null &&
        !_toTime!.isAfter(_fromTime!)) {
      RequestSnack.show(messenger, 'To time must be after from time.');
      return;
    }

    if (_isEditing) {
      final updated = _controller.updateRequest(
        _editId!,
        fromDate: _fromDate,
        toDate: _toDate,
        dayType: _dayType,
        reason: reason,
        fromTime: _dayType == 'Time' ? _fromTime : null,
        toTime: _dayType == 'Time' ? _toTime : null,
        hasAttachment: _hasAttachment,
      );

      Get.back();
      RequestSnack.show(
        messenger,
        updated
            ? 'Your leave request was updated.'
            : 'This request was already approved, so it cannot be edited.',
      );
      return;
    }

    _controller.addRequest(
      fromDate: _fromDate,
      toDate: _toDate,
      dayType: _dayType,
      reason: reason,
      fromTime: _dayType == 'Time' ? _fromTime : null,
      toTime: _dayType == 'Time' ? _toTime : null,
      hasAttachment: _hasAttachment,
    );

    Get.back();
    RequestSnack.show(messenger, 'Your leave request was submitted.');
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: _isEditing ? 'Edit Leave' : 'Request Leave',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateRow(
                      label: 'From Date',
                      date: _fromDate,
                      onChange: _pickFromDate,
                    ),
                    const SizedBox(height: 16),
                    _DateRow(
                      label: 'To Date',
                      date: _toDate,
                      onChange: _pickToDate,
                    ),
                    const SizedBox(height: 16),
                    _buildDayTypeChips(),
                    if (_dayType == 'Time') ...[
                      const SizedBox(height: 12),
                      _buildTimeRow(),
                    ],
                    const SizedBox(height: 16),
                    _buildReasonLabel(),
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

  Widget _buildDayTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kLeaveDayTypes.map((type) {
        final isSelected = type == _dayType;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          avatar: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: RequestColors.primary,
                )
              : null,
          onSelected: (_) => setState(() => _dayType = type),
          showCheckmark: false,
          backgroundColor: Colors.white,
          selectedColor: Colors.white,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? RequestColors.primary
                : RequestColors.textSecondary,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected
                  ? RequestColors.primary
                  : const Color(0xFFD1D5DB),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            label: 'From Time',
            time: _fromTime,
            onChange: () => _pickTime(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TimeField(
            label: 'To Time',
            time: _toTime,
            onChange: () => _pickTime(false),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonLabel() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: 'Reason ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: RequestColors.textPrimary,
          ),
          children: [
            TextSpan(
              text: '*',
              style: TextStyle(color: RequestColors.danger),
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
          _hasAttachment ? Icons.check_circle_rounded : Icons.attach_file_rounded,
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

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.onChange,
  });

  final String label;
  final DateTime date;
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
              const Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: RequestColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateText.monthShortDay(date),
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

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onChange,
  });

  final String label;
  final DateTime? time;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequestLabel(label),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onChange,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: RequestColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      time == null ? 'Select' : DateText.time(time!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
