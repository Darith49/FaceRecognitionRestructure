import 'dart:typed_data';
import 'package:face_recognition_attendance/core/utils/file_picker_helper.dart';
import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Leave_screen/controller/leave_controller.dart';
import 'package:face_recognition_attendance/features/Leave_screen/model/leave_request.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Redesigned Apple-Style Leave Screen featuring:
/// 1. Segmented Control ("Request Leave" and "History & Pending")
/// 2. Apple-inspired Leave Request Form with Section Selection, Early Leave Time, Reason, and Attachment
/// 3. Leave Request History & Status list
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({
    super.key,
    this.initialTab = 0,
    this.editId,
  });

  final int initialTab;
  final String? editId;

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveController _controller = Get.find<LeaveController>();
  final TextEditingController _reasonController = TextEditingController();

  late int _tabIndex;
  late DateTime _selectedDate;
  int _session = 1; // 1: Section 1, 2: Section 2, 0: Full Day
  String _leaveMode = 'full_section'; // 'full_section' or 'early_leave'
  TimeOfDay _earlyLeaveTime = const TimeOfDay(hour: 9, minute: 30);
  bool _hasAttachment = false;
  String? _attachmentName;
  Uint8List? _attachmentBytes;
  int? _attachmentSize;
  String? _attachmentPath;
  String? _editId;
  bool _isSubmitting = false;
  String _historyFilter = 'All';

  bool get _isEditing => _editId != null;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;

    final today = DateUtils.dateOnly(DateTime.now());
    _selectedDate = today;

    // Check for arguments (passed when editing a pending request or from early checkout prompt)
    final args = widget.editId ?? Get.arguments;
    if (args is String) {
      final existing = _controller.findById(args);
      if (existing != null && existing.status == LeaveStatus.pending) {
        _editId = existing.id;
        _selectedDate = existing.fromDate;
        _session = existing.session;
        _leaveMode = existing.leaveMode;
        if (existing.earlyLeaveTime != null && existing.earlyLeaveTime!.isNotEmpty) {
          final parts = existing.earlyLeaveTime!.split(':');
          if (parts.length >= 2) {
            _earlyLeaveTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts[1]) ?? 30,
            );
          }
        }
        _hasAttachment = existing.hasAttachment;
        _attachmentName = existing.attachmentName;
        _attachmentBytes = existing.attachmentBytes;
        _attachmentSize = existing.attachmentSize;
        _attachmentPath = existing.attachmentPath;
        _reasonController.text = existing.reason;
        _tabIndex = 0; // Force to form when editing
      }
    } else if (args is Map) {
      if (args['tab'] is int) _tabIndex = args['tab'] as int;
      if (args['session'] is int) _session = args['session'] as int;
      if (args['leaveMode'] is String) _leaveMode = args['leaveMode'] as String;
      if (args['reason'] is String) _reasonController.text = args['reason'] as String;
      if (args['earlyLeaveTime'] is TimeOfDay) _earlyLeaveTime = args['earlyLeaveTime'] as TimeOfDay;
    }
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
      initialDate: _selectedDate,
      firstDate: _selectedDate.isBefore(today) ? _selectedDate : today,
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickEarlyLeaveTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _earlyLeaveTime,
    );
    if (picked != null && mounted) {
      setState(() => _earlyLeaveTime = picked);
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      RequestSnack.show(messenger, 'Please provide a reason for your leave.');
      return;
    }

    setState(() => _isSubmitting = true);

    final earlyTimeStr = (_session != 0 && _leaveMode == 'early_leave')
        ? '${_earlyLeaveTime.hour.toString().padLeft(2, '0')}:${_earlyLeaveTime.minute.toString().padLeft(2, '0')}:00'
        : null;

    final dayTypeStr = _session == 1
        ? 'Section 1 (Morning)'
        : (_session == 2 ? 'Section 2 (Afternoon)' : 'Full Day');

    if (_isEditing) {
      final ok = await _controller.updateRequest(
        _editId!,
        fromDate: _selectedDate,
        toDate: _selectedDate,
        session: _session,
        leaveMode: _leaveMode,
        earlyLeaveTime: earlyTimeStr,
        dayType: dayTypeStr,
        reason: reason,
        hasAttachment: _hasAttachment,
        attachmentName: _attachmentName,
        attachmentBytes: _attachmentBytes,
        attachmentSize: _attachmentSize,
        attachmentPath: _attachmentPath,
      );
      if (ok) {
        RequestSnack.show(messenger, 'Leave request updated successfully.');
        setState(() {
          _editId = null;
          _tabIndex = 1;
        });
      } else {
        RequestSnack.show(messenger, 'Failed to update leave request.');
      }
    } else {
      final ok = await _controller.addRequest(
        fromDate: _selectedDate,
        toDate: _selectedDate,
        session: _session,
        leaveMode: _leaveMode,
        earlyLeaveTime: earlyTimeStr,
        dayType: dayTypeStr,
        reason: reason,
        hasAttachment: _hasAttachment,
        attachmentName: _attachmentName,
        attachmentBytes: _attachmentBytes,
        attachmentSize: _attachmentSize,
        attachmentPath: _attachmentPath,
      );
      if (ok) {
        RequestSnack.show(messenger, 'Leave request submitted successfully.');
        _reasonController.clear();
        setState(() {
          _hasAttachment = false;
          _attachmentName = null;
          _attachmentBytes = null;
          _attachmentSize = null;
          _attachmentPath = null;
          _tabIndex = 1;
        });
      } else {
        RequestSnack.show(messenger, 'Failed to submit leave request.');
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
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
      title: 'Request Leave',
      backLabel: 'Back',
      centerTitle: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Control
            AppleSegmentedControl(
              tabs: const ['Request Leave', 'History & Pending'],
              selectedIndex: _tabIndex,
              onChanged: (index) => setState(() => _tabIndex = index),
            ),

            const SizedBox(height: 20),

            // Body according to active tab
            if (_tabIndex == 0) _buildRequestForm() else _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSelector() {
    final sections = [
      {
        'id': 1,
        'title': 'Section 1',
        'subtitle': '07:00 – 11:00 AM',
        'label': 'Morning',
        'icon': FluentIcons.weather_sunny_24_regular,
      },
      {
        'id': 2,
        'title': 'Section 2',
        'subtitle': '01:00 – 05:00 PM',
        'label': 'Afternoon',
        'icon': FluentIcons.weather_moon_24_regular,
      },
      {
        'id': 0,
        'title': 'Full Day',
        'subtitle': '07:00 – 17:00',
        'label': 'Both Shifts',
        'icon': FluentIcons.calendar_ltr_24_regular,
      },
    ];

    return Row(
      children: sections.map((s) {
        final id = s['id'] as int;
        final isSelected = _session == id;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _session = id;
                if (id == 1) {
                  _earlyLeaveTime = const TimeOfDay(hour: 9, minute: 30);
                } else if (id == 2) {
                  _earlyLeaveTime = const TimeOfDay(hour: 15, minute: 30);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? RequestColors.primary.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? RequestColors.primary : const Color(0xFFE5E5EA),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: RequestColors.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    s['icon'] as IconData,
                    size: 24,
                    color: isSelected ? RequestColors.primary : RequestColors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (s['title'] as String).tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? RequestColors.primary : RequestColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (s['label'] as String).tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? RequestColors.primary : RequestColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaveModeSelector() {
    final isEarly = _leaveMode == 'early_leave';
    final secName = _session == 1 ? 'Section 1' : 'Section 2';
    final shiftHours = _session == 1 ? '07:00 AM – 11:00 AM' : '01:00 PM – 05:00 PM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FluentIcons.options_24_regular, size: 18, color: RequestColors.primary),
              const SizedBox(width: 8),
              Text(
                '${'Leave Option for'.tr} ${secName.tr}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RequestColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _leaveMode = 'full_section'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !isEarly ? RequestColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isEarly ? RequestColors.primary : const Color(0xFFD1D1D6),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${'Full'.tr} ${secName.tr}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !isEarly ? Colors.white : RequestColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _leaveMode = 'early_leave'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isEarly ? RequestColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEarly ? RequestColors.primary : const Color(0xFFD1D1D6),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Leave Early'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isEarly ? Colors.white : RequestColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isEarly) ...[
            GestureDetector(
              onTap: _pickEarlyLeaveTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RequestColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(FluentIcons.clock_24_regular, size: 24, color: RequestColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Departure Time'.tr,
                            style: const TextStyle(fontSize: 11, color: RequestColors.textSecondary),
                          ),
                          Text(
                            _earlyLeaveTime.format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: RequestColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Change'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${'Leave Early'.tr}: ${_earlyLeaveTime.format(context)} (${secName.tr} $shiftHours)',
              style: const TextStyle(fontSize: 12, color: RequestColors.textSecondary),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(FluentIcons.info_24_regular, size: 14, color: RequestColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Full Day Leave excuses both morning (Section 1) and afternoon (Section 2) shifts.'.tr,
                    style: const TextStyle(fontSize: 12, color: RequestColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Workday'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RequestColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _DateSelectionCard(
          icon: FluentIcons.calendar_ltr_24_regular,
          iconColor: RequestColors.primary,
          dateText: DateText.fullDate(_selectedDate),
          subtitle: DateUtils.isSameDay(_selectedDate, DateTime.now())
              ? 'Today • Workday'.tr
              : 'Selected Date'.tr,
          onTapChange: _pickDate,
        ),

        const SizedBox(height: 18),

        // Section to Leave
        Text(
          'Work Section to Leave'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RequestColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildSectionSelector(),

        // Leave Mode (Full Section vs Leave Early)
        if (_session == 1 || _session == 2) ...[
          const SizedBox(height: 16),
          _buildLeaveModeSelector(),
        ] else ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RequestColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RequestColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.info_24_regular, size: 16, color: RequestColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Full Day Leave excuses both morning (Section 1) and afternoon (Section 2) shifts.'.tr,
                    style: const TextStyle(fontSize: 12, color: RequestColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Reason *
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: '${'Reason'.tr} ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: RequestColors.textPrimary,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: RequestColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Max 250 characters'.tr,
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
            style: const TextStyle(
              fontSize: 15,
              color: RequestColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Please provide details about your leave request...'.tr,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: RequestColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Attach Document or Image Section
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
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    _attachmentName!.toLowerCase().endsWith('.pdf')
                        ? FluentIcons.document_pdf_24_regular
                        : (_attachmentName!.toLowerCase().endsWith('.png') ||
                                _attachmentName!.toLowerCase().endsWith('.jpg') ||
                                _attachmentName!.toLowerCase().endsWith('.jpeg') ||
                                _attachmentName!.toLowerCase().endsWith('.webp'))
                            ? FluentIcons.image_24_regular
                            : FluentIcons.document_24_regular,
                    color: RequestColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),
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
                            ? '${(_attachmentSize! / 1024).toStringAsFixed(1)} KB'
                            : 'Document Attached'.tr,
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
                  child: Text('Change'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: _removeAttachment,
                  icon: const Icon(FluentIcons.dismiss_circle_24_regular, size: 20, color: RequestColors.danger),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove'.tr,
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
                children: [
                  const Icon(
                    FluentIcons.arrow_upload_24_regular,
                    size: 22,
                    color: RequestColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Attach Document or Image (PDF, JPG, PNG)'.tr,
                    style: const TextStyle(
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

        // Submit Button (Apple style pill)
        RequestButton(
          label: _isSubmitting
              ? 'Submitting...'.tr
              : (_isEditing ? 'Update Leave Request'.tr : 'Submit Leave Request'.tr),
          onPressed: _isSubmitting ? null : _submit,
        ),

        const SizedBox(height: 10),

        Center(
          child: Text(
            'Requests require approval from your direct manager'.tr,
            style: const TextStyle(
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
      final allItems = _controller.requests;

      final items = _historyFilter == 'All'
          ? allItems
          : (_historyFilter == 'Pending'
              ? allItems.where((r) => r.status == LeaveStatus.pending).toList()
              : (_historyFilter == 'Approved'
                  ? allItems.where((r) => r.status == LeaveStatus.approved).toList()
                  : allItems.where((r) => r.status == LeaveStatus.rejected).toList()));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((f) {
                final isSelected = _historyFilter == f;
                final count = f == 'All'
                    ? allItems.length
                    : (f == 'Pending'
                        ? allItems.where((r) => r.status == LeaveStatus.pending).length
                        : (f == 'Approved'
                            ? allItems.where((r) => r.status == LeaveStatus.approved).length
                            : allItems.where((r) => r.status == LeaveStatus.rejected).length));

                return GestureDetector(
                  onTap: () => setState(() => _historyFilter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? RequestColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? RequestColors.primary : const Color(0xFFE5E5EA),
                      ),
                    ),
                    child: Text(
                      '${f.tr} ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : RequestColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    FluentIcons.calendar_empty_24_regular,
                    size: 36,
                    color: RequestColors.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _historyFilter == 'All'
                        ? 'No Leave Requests Yet'.tr
                        : '${_historyFilter.tr} (0)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your submitted leave requests will appear here with live review status.'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                final isPending = req.status == LeaveStatus.pending;
                final isApproved = req.status == LeaveStatus.approved;
                final isRejected = req.status == LeaveStatus.rejected;

                final statusBgColor = isPending
                    ? RequestColors.gold.withValues(alpha: 0.15)
                    : (isApproved
                        ? RequestColors.approvedStatus.withValues(alpha: 0.15)
                        : RequestColors.danger.withValues(alpha: 0.15));

                final statusTextColor = isPending
                    ? RequestColors.gold
                    : (isApproved
                        ? RequestColors.approvedStatus
                        : RequestColors.danger);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: appleCardDecoration(radius: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Date & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  req.session == 1
                                      ? FluentIcons.weather_sunny_24_regular
                                      : (req.session == 2
                                          ? FluentIcons.weather_moon_24_regular
                                          : FluentIcons.calendar_ltr_24_regular),
                                  size: 22,
                                  color: RequestColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                req.dateRangeLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: RequestColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              req.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Schedule / Section Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req.scheduleLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: RequestColors.textPrimary,
                          ),
                        ),
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

                      if (req.reviewNotes != null && req.reviewNotes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isRejected
                                ? RequestColors.danger.withValues(alpha: 0.08)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${'Review note:'.tr} ${req.reviewNotes}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isRejected ? RequestColors.danger : RequestColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 8),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPending) ...[
                            TextButton(
                              onPressed: () => _confirmCancel(req.id),
                              child: Text(
                                'Cancel'.tr,
                                style: const TextStyle(
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
                                  _selectedDate = req.fromDate;
                                  _session = req.session;
                                  _leaveMode = req.leaveMode;
                                  if (req.earlyLeaveTime != null && req.earlyLeaveTime!.isNotEmpty) {
                                    final parts = req.earlyLeaveTime!.split(':');
                                    if (parts.length >= 2) {
                                      _earlyLeaveTime = TimeOfDay(
                                        hour: int.tryParse(parts[0]) ?? 9,
                                        minute: int.tryParse(parts[1]) ?? 30,
                                      );
                                    }
                                  }
                                  _hasAttachment = req.hasAttachment;
                                  _reasonController.text = req.reason;
                                  _tabIndex = 0;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RequestColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Edit'.tr,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ] else ...[
                            TextButton.icon(
                              onPressed: () => Get.toNamed(
                                AppRoutes.leaveDetail,
                                arguments: req.id,
                              ),
                              icon: const Icon(
                                FluentIcons.arrow_right_24_regular,
                                size: 16,
                                color: RequestColors.primary,
                              ),
                              label: Text(
                                'View Details'.tr,
                                style: const TextStyle(
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

  void _confirmCancel(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Request'.tr),
        content: Text('Are you sure you want to cancel this leave request?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.cancelRequest(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestColors.danger,
              foregroundColor: Colors.white,
            ),
            child: Text('Yes, Cancel'.tr),
          ),
        ],
      ),
    );
  }
}

/// Apple Date / Time card with change pill
class _DateSelectionCard extends StatelessWidget {
  const _DateSelectionCard({
    this.icon = FluentIcons.calendar_ltr_24_regular,
    this.iconColor = RequestColors.primary,
    required this.dateText,
    required this.subtitle,
    required this.onTapChange,
  });

  final IconData icon;
  final Color iconColor;
  final String dateText;
  final String subtitle;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appleCardDecoration(radius: 14),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: RequestColors.textSecondary,
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
