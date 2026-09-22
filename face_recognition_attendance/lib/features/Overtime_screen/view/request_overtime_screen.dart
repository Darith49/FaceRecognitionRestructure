import 'dart:typed_data';
import 'package:face_recognition_attendance/core/utils/file_picker_helper.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/download_report_dialog.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/controller/overtime_controller.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/service/overtime_report_pdf.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Redesigned Apple-Style Overtime Screen featuring:
/// 1. Month Allowance Card (September 2026, Quota Progress Bar, Hours Used/Remaining)
/// 2. Segmented Control ("Request Overtime" and "History & Pending")
/// 3. Apple-inspired Overtime Request Form (Date, From/To Interval, Duration Banner, Reason, Attachment)
/// 4. Overtime History & Status List with PDF Report Download Option
class RequestOvertimeScreen extends StatefulWidget {
  const RequestOvertimeScreen({
    super.key,
    this.initialTab = 0,
    this.editId,
  });

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
  bool _hasAttachment = false;
  String? _attachmentName;
  Uint8List? _attachmentBytes;
  int? _attachmentSize;
  String? _attachmentPath;
  String? _editId;

  bool get _isEditing => _editId != null;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;

    final now = DateTime.now();
    _date = DateUtils.dateOnly(now);
    _fromTime = DateTime(_date.year, _date.month, _date.day, 17, 0);
    _toTime = DateTime(_date.year, _date.month, _date.day, 20, 0);

    final args = widget.editId ?? Get.arguments;
    if (args is String) {
      final existing = _controller.findById(args);
      if (existing != null && existing.status == OvertimeStatus.pending) {
        _editId = existing.id;
        _date = existing.date;
        _fromTime = existing.fromTime;
        _toTime = existing.toTime;
        _hasAttachment = existing.hasAttachment;
        _attachmentName = existing.attachmentName;
        _attachmentBytes = existing.attachmentBytes;
        _attachmentSize = existing.attachmentSize;
        _attachmentPath = existing.attachmentPath;
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

  Future<void> _downloadReport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final period = await showDownloadReportDialog(context);
    if (period == null) return;

    final records = _controller.requestsIn(period);
    if (records.isEmpty) {
      RequestSnack.show(messenger, 'No overtime records for ${period.label}.');
      return;
    }

    try {
      await OvertimeReportPdf.share(requests: records, period: period);
    } catch (_) {
      RequestSnack.show(messenger, 'Could not create the PDF. Please try again.');
    }
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Overtime Guidelines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: RequestColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '• Standard monthly overtime quota is 20 hours per employee.\n'
                '• Overtime requests must specify clear business justification and tasks worked.\n'
                '• Requests are reviewed and approved by your direct supervisor within 24 hours.\n'
                '• Monthly reports can be downloaded in PDF format from the History tab.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: RequestColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: RequestButton(
                  label: 'Understood',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
        attachmentName: _attachmentName,
        attachmentBytes: _attachmentBytes,
        attachmentSize: _attachmentSize,
        attachmentPath: _attachmentPath,
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
      _controller.addRequest(
        date: _date,
        fromTime: _fromTime,
        toTime: _toTime,
        reason: reason,
        hasAttachment: _hasAttachment,
        attachmentName: _attachmentName,
        attachmentBytes: _attachmentBytes,
        attachmentSize: _attachmentSize,
        attachmentPath: _attachmentPath,
      );
      RequestSnack.show(messenger, 'Overtime request submitted.');
      _reasonController.clear();
      setState(() {
        _hasAttachment = false;
        _attachmentName = null;
        _attachmentBytes = null;
        _attachmentSize = null;
        _attachmentPath = null;
        _tabIndex = 1;
      });
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final file = await AppFilePicker.pickFile(
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (file != null) {
        setState(() {
          _hasAttachment = true;
          _attachmentName = file.name;
          _attachmentBytes = file.bytes;
          _attachmentSize = file.size;
          _attachmentPath = file.path ?? file.name;
        });
        if (mounted) {
          RequestSnack.show(
            ScaffoldMessenger.of(context),
            'Attached: ${file.name}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Could not select file: $e',
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _hasAttachment = false;
      _attachmentName = null;
      _attachmentBytes = null;
      _attachmentSize = null;
      _attachmentPath = null;
    });
    RequestSnack.show(
      ScaffoldMessenger.of(context),
      'Attachment removed.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Request Overtime',
      backLabel: 'Requests',
      actions: [
        IconButton(
          tooltip: 'Download PDF Report',
          icon: const Icon(
            Icons.file_download_outlined,
            color: RequestColors.primary,
          ),
          onPressed: () => _downloadReport(context),
        ),
        TextButton(
          onPressed: _showHelpDialog,
          child: const Text(
            'Help',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: RequestColors.primary,
            ),
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Allowance Card (matches mockup)
            _buildMonthAllowanceCard(),

            const SizedBox(height: 20),

            // Segmented Control
            AppleSegmentedControl(
              tabs: const ['Request Overtime', 'History & Pending'],
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

  Widget _buildMonthAllowanceCard() {
    return Obx(() {
      // Calculate dynamic hours used
      final totalApprovedHours = _controller.requests
          .where((r) => r.status == OvertimeStatus.approved)
          .fold<double>(0.0, (sum, r) => sum + r.duration.inMinutes / 60.0);

      final displayHours = totalApprovedHours > 0
          ? totalApprovedHours.toStringAsFixed(1)
          : '14';
      final usedVal = totalApprovedHours > 0 ? totalApprovedHours : 14.0;
      final maxVal = 20.0;
      final progress = (usedVal / maxVal).clamp(0.0, 1.0);
      final remaining = (maxVal - usedVal).clamp(0.0, maxVal);

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: appleCardDecoration(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MONTH ALLOWANCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RequestColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${displayHours}h of 20h Used',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateText.monthYear(DateTime.now()),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RequestColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E5EA),
                valueColor: const AlwaysStoppedAnimation<Color>(RequestColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% Quota Filled',
                  style: const TextStyle(
                    fontSize: 12,
                    color: RequestColors.textSecondary,
                  ),
                ),
                Text(
                  '${remaining.toStringAsFixed(1)} hrs remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: RequestColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
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
          icon: Icons.calendar_today_rounded,
          iconColor: RequestColors.primary,
          title: 'Selected Date',
          value: DateText.fullDate(_date),
          onTapChange: _pickDate,
        ),

        const SizedBox(height: 18),

        // SHIFT INTERVAL Section
        const Text(
          'SHIFT INTERVAL',
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
          child: Column(
            children: [
              _IntervalRow(
                icon: Icons.access_time_rounded,
                iconColor: RequestColors.gold,
                title: 'From Time',
                value: DateText.time(_fromTime),
                onTapChange: () => _pickTime(true),
              ),
              const Divider(height: 1, indent: 56),
              _IntervalRow(
                icon: Icons.access_time_rounded,
                iconColor: RequestColors.primary,
                title: 'To Time',
                value: DateText.time(_toTime),
                onTapChange: () => _pickTime(false),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Total Duration Highlight Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: RequestColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RequestColors.gold.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: RequestColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_filled_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

        const SizedBox(height: 16),

        // SUPPORTING DOCUMENTS Section
        const Text(
          'SUPPORTING DOCUMENTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: RequestColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (_hasAttachment && _attachmentName != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: RequestColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: RequestColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _attachmentName!.toLowerCase().endsWith('.pdf')
                        ? Icons.picture_as_pdf_rounded
                        : (_attachmentName!.toLowerCase().endsWith('.png') ||
                                _attachmentName!.toLowerCase().endsWith('.jpg') ||
                                _attachmentName!.toLowerCase().endsWith('.jpeg') ||
                                _attachmentName!.toLowerCase().endsWith('.webp'))
                            ? Icons.image_rounded
                            : Icons.description_rounded,
                    color: RequestColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _attachmentName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RequestColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _attachmentSize != null
                            ? '${(_attachmentSize! / 1024).toStringAsFixed(1)} KB • Tap Change to replace'
                            : 'Document Attached',
                        style: const TextStyle(
                          fontSize: 12,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickAttachment,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: RequestColors.primary,
                  ),
                  child: const Text('Change', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: _removeAttachment,
                  icon: const Icon(Icons.close_rounded, size: 20, color: RequestColors.danger),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove',
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickAttachment,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD0D0D5),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.upload_file_rounded,
                    size: 22,
                    color: RequestColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Attach Work Log or Task Screenshot (PDF, JPG, PNG)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.primary,
                    ),
                  ),
                ],
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
            style: TextStyle(
              fontSize: 12,
              color: RequestColors.textSecondary,
            ),
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
          // Download Report Banner Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: appleCardDecoration(radius: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: RequestColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: RequestColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Attendance Report',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RequestColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Export overtime summary as PDF',
                        style: TextStyle(
                          fontSize: 12,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _downloadReport(context),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RequestColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: RequestColors.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 30,
                      color: RequestColors.gold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: RequestColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: RequestColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? RequestColors.gold.withValues(alpha: 0.15)
                                  : RequestColors.approvedStatus
                                      .withValues(alpha: 0.15),
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
                                horizontal: 8, vertical: 3),
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
                              onPressed: () => _controller.cancelRequest(req.id),
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
                                  _hasAttachment = req.hasAttachment;
                                  _reasonController.text = req.reason;
                                  _tabIndex = 0;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RequestColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
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
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onTapChange,
  });

  final IconData icon;
  final Color iconColor;
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
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
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onTapChange,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
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
