import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/controller/overtime_controller.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Redesigned Apple-Style Overtime Screen
class RequestOvertimeScreen extends StatefulWidget {
  const RequestOvertimeScreen({super.key, this.initialTab = 0, this.editId});

  final int initialTab;
  final String? editId;

  @override
  State<RequestOvertimeScreen> createState() => _RequestOvertimeScreenState();
}

class _RequestOvertimeScreenState extends State<RequestOvertimeScreen> {
  final OvertimeController _controller = Get.find<OvertimeController>();
  final TextEditingController _reasonController = TextEditingController();

  late int _tabIndex;
  late DateTime _date;
  late DateTime _fromTime;
  late DateTime _toTime;
  String? _editId;

  bool get _isEditing => _editId != null;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;

    final now = DateTime.now();
    _date = DateUtils.dateOnly(now);
    int sec2Hour = 17;
    int sec2Min = 0;
    if (Get.isRegistered<HomeController>()) {
      final s2 = Get.find<HomeController>().session2SchedOut.value;
      final parts = s2.split(':');
      if (parts.length >= 2) {
        sec2Hour = int.tryParse(parts[0]) ?? 17;
        sec2Min = int.tryParse(parts[1]) ?? 0;
      }
    }
    _fromTime = DateTime(_date.year, _date.month, _date.day, sec2Hour, sec2Min);
    _toTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      (sec2Hour + 3) % 24,
      sec2Min,
    );

    _controller.fetchRequests();

    final args = widget.editId ?? Get.arguments;
    if (args is String) {
      final existing = _controller.findById(args);
      if (existing != null && existing.status == OvertimeStatus.pending) {
        _editId = existing.id;
        _date = existing.date;
        _fromTime = existing.fromTime;
        _toTime = existing.toTime;
        _reasonController.text = existing.reason;
        _tabIndex = 0;
      }
    } else if (args is Map && args['tab'] is int) {
      _tabIndex = args['tab'] as int;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Duration get _duration {
    if (_toTime.isBefore(_fromTime)) return Duration.zero;
    return _toTime.difference(_fromTime);
  }

  String get _durationBadgeText {
    final minutes = _duration.inMinutes;
    if (minutes <= 0) return '0 HOURS';
    final hours = minutes / 60.0;
    if (hours == hours.truncateToDouble()) {
      final h = hours.toInt();
      return '$h ${h == 1 ? 'HOUR' : 'HOURS'}';
    }
    return '${hours.toStringAsFixed(1)} HOURS';
  }

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

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      RequestSnack.show(messenger, 'Please input reason.');
      return;
    }
    if (!_toTime.isAfter(_fromTime)) {
      RequestSnack.show(
        messenger,
        'To time must be after the section end time (${DateText.time(_fromTime)}).',
      );
      return;
    }

    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_date, now);
    if (isToday) {
      final nowTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
      );
      if (!_toTime.isAfter(nowTime)) {
        RequestSnack.show(
          messenger,
          'To time must be later than the current time.',
        );
        return;
      }
    }

    if (_isEditing) {
      final updated = _controller.updateRequest(
        _editId!,
        date: _date,
        fromTime: _fromTime,
        toTime: _toTime,
        reason: reason,
        hasAttachment: false,
      );

      RequestSnack.show(
        messenger,
        updated
            ? 'Your overtime request was updated.'
            : 'This request was already approved, so it cannot be edited.',
      );
      if (updated) {
        setState(() {
          _editId = null;
          _tabIndex = 1;
        });
      }
    } else {
      final success = await _controller.addRequest(
        date: _date,
        fromTime: _fromTime,
        toTime: _toTime,
        reason: reason,
      );
      if (success) {
        RequestSnack.show(messenger, 'Overtime request submitted.');
        _reasonController.clear();
        setState(() {
          _tabIndex = 1;
        });
      } else {
        RequestSnack.show(
          messenger,
          'Failed to submit overtime request. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Overtime',
      backLabel: 'Back',
      actions: const [],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Control
            AppleSegmentedControl(
              tabs: const ['Request Overtime', 'History'],
              selectedIndex: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),

            const SizedBox(height: 20),

            // Tab view
            if (_tabIndex == 0) _buildRequestForm() else _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DATE Section
        const Text(
          'DATE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: RequestColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        _OvertimeItemCard(
          title: 'Selected Date',
          value: DateText.fullDate(_date),
          onTapChange: _pickDate,
        ),

        const SizedBox(height: 18),

        // TIME Section
        const Text(
          'OVERTIME UNTIL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: RequestColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: appleCardDecoration(radius: 14),
          clipBehavior: Clip.antiAlias,
          child: _IntervalRow(
            title: 'To Time',
            value: DateText.time(_toTime),
            onTapChange: () => _pickTime(false),
          ),
        ),

        const SizedBox(height: 14),

        // Total Duration Highlight Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: RequestColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: RequestColors.gold.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Total Duration:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: RequestColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: RequestColors.gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _durationBadgeText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // REASON FOR OVERTIME Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'REASON FOR OVERTIME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RequestColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${_reasonController.text.length} / 250',
              style: const TextStyle(
                fontSize: 12,
                color: RequestColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: appleCardDecoration(radius: 14),
          child: TextField(
            controller: _reasonController,
            minLines: 4,
            maxLines: 5,
            maxLength: 250,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 15,
              color: RequestColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Please write your detailed reason here...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: RequestColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Submit Button
        RequestButton(
          label: _isEditing
              ? 'Update Overtime Request'
              : 'Submit Overtime Request',
          onPressed: _submit,
        ),

        const SizedBox(height: 10),

        const Center(
          child: Text(
            'Requests are subject to manager approval within 24 hours.',
            style: TextStyle(fontSize: 12, color: RequestColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      final items = _controller.requests;

      return Column(
        children: [
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text(
                    'No Overtime Requests',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Submitted overtime logs and approval updates will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: RequestColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final req = items[index];
                final isPending = req.status == OvertimeStatus.pending;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: appleCardDecoration(radius: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateText.fullDate(req.date),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: RequestColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? RequestColors.gold.withValues(alpha: 0.15)
                                  : RequestColors.approvedStatus.withValues(
                                      alpha: 0.15,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              req.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPending
                                    ? RequestColors.gold
                                    : RequestColors.approvedStatus,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Time range and duration
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              req.timeRangeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: RequestColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            req.durationLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      if (req.reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          req.reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: RequestColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 8),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPending) ...[
                            TextButton(
                              onPressed: () =>
                                  _controller.cancelRequest(req.id),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: RequestColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _editId = req.id;
                                  _date = req.date;
                                  _fromTime = req.fromTime;
                                  _toTime = req.toTime;
                                  _reasonController.text = req.reason;
                                  _tabIndex = 0;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RequestColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else ...[
                            TextButton.icon(
                              onPressed: () => Get.toNamed(
                                AppRoutes.overtimeDetail,
                                arguments: req.id,
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: RequestColors.primary,
                              ),
                              label: const Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: RequestColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      );
    });
  }
}

class _OvertimeItemCard extends StatelessWidget {
  const _OvertimeItemCard({
    required this.title,
    required this.value,
    required this.onTapChange,
  });

  final String title;
  final String value;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appleCardDecoration(radius: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RequestColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ChangePill(onTap: onTapChange),
        ],
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.title,
    required this.value,
    required this.onTapChange,
  });

  final String title;
  final String value;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RequestColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ChangePill(onTap: onTapChange),
        ],
      ),
    );
  }
}
