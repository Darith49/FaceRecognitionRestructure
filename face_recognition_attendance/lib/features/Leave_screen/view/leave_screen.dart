import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/Leave_screen/controller/leave_controller.dart';
import 'package:face_recognition_attendance/features/Leave_screen/model/leave_request.dart';
import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper to format 24h string "11:00" to "11:00 AM"
String _formatTimeStr(String timeStr) {
  try {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final isPm = hour >= 12;
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      final hStr = h12.toString().padLeft(2, '0');
      final mStr = minute.toString().padLeft(2, '0');
      return '$hStr:$mStr ${isPm ? 'PM' : 'AM'}';
    }
  } catch (_) {}
  return timeStr;
}

/// Redesigned Apple-Style Leave Screen featuring:
/// 1. Segmented Control ("Request Leave" and "History & Pending")
/// 2. Early Leave Request Form with Section Selection, Time Picker, and Reason
/// 3. Leave Request History & Status list
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key, this.initialTab = 0, this.editId});

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
  int _session = 1; // 1: Section 1, 2: Section 2
  final String _leaveMode = 'early_leave'; // Always early leave with time
  late TimeOfDay _earlyLeaveTime;
  String? _editId;
  bool _isSubmitting = false;
  String _historyFilter = 'All';

  // Dynamic Shift Section Times from backend
  String _s1Start = '07:00';
  String _s1End = '11:00';
  String _s2Start = '13:00';
  String _s2End = '17:00';

  String? _timeError;
  String? _reasonError;

  String get _s1TimeDisplay =>
      '${_formatTimeStr(_s1Start)} – ${_formatTimeStr(_s1End)}';
  String get _s2TimeDisplay =>
      '${_formatTimeStr(_s2Start)} – ${_formatTimeStr(_s2End)}';

  bool get _isEditing => _editId != null;

  TimeOfDay _defaultEarlyLeaveTimeForSection(int session, [DateTime? date]) {
    final targetDate = date ?? _selectedDate;
    final isToday = DateUtils.isSameDay(targetDate, DateTime.now());
    final endRaw = session == 1 ? _s1End : _s2End;
    final startRaw = session == 1 ? _s1Start : _s2Start;
    final endParts = endRaw.split(':');
    final endH = int.tryParse(endParts[0]) ?? (session == 1 ? 11 : 17);
    final endM = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0;
    final endTotalMin = endH * 60 + endM;

    if (isToday) {
      final now = DateTime.now();
      final candidateMin = (now.minute / 5).ceil() * 5 + 10;
      final candidateHour = now.hour + (candidateMin ~/ 60);
      final candidateTotalMin = candidateHour * 60 + (candidateMin % 60);

      if (candidateTotalMin < endTotalMin) {
        return TimeOfDay(
          hour: candidateHour.clamp(0, 23),
          minute: (candidateMin % 60).clamp(0, 59),
        );
      }
    }

    final startParts = startRaw.split(':');
    final startH = int.tryParse(startParts[0]) ?? (session == 1 ? 7 : 13);
    final startM = startParts.length > 1
        ? (int.tryParse(startParts[1]) ?? 0)
        : 0;
    final startTotalMin = startH * 60 + startM;
    final defaultMin = ((startTotalMin + endTotalMin) ~/ 2);
    return TimeOfDay(
      hour: (defaultMin ~/ 60).clamp(0, 23),
      minute: (defaultMin % 60).clamp(0, 59),
    );
  }

  bool get _isSection1Finished {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(_selectedDate);
    if (selected.isBefore(today)) return true;
    if (selected.isAfter(today)) return false;

    // Today: check if current time is past Section 1 end time
    final now = DateTime.now();
    final parts = _s1End.split(':');
    final endHour = int.tryParse(parts[0]) ?? 11;
    final endMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final s1End = DateTime(now.year, now.month, now.day, endHour, endMinute);
    return now.isAfter(s1End) || now.isAtSameMomentAs(s1End);
  }

  bool get _hasExistingLeaveOnSelectedDate {
    return _controller.requests.any(
      (r) =>
          DateUtils.isSameDay(r.fromDate, _selectedDate) &&
          (r.status == LeaveStatus.pending ||
              r.status == LeaveStatus.approved) &&
          r.id != _editId,
    );
  }

  void _validateTimeOnly() {
    final endRaw = _session == 1 ? _s1End : _s2End;
    final endParts = endRaw.split(':');
    final endH = int.tryParse(endParts[0]) ?? (_session == 1 ? 11 : 17);
    final endM = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0;
    final endTotalMin = endH * 60 + endM;
    final leaveTotalMin = _earlyLeaveTime.hour * 60 + _earlyLeaveTime.minute;

    if (leaveTotalMin >= endTotalMin) {
      _timeError =
          'Time must be before section end time (${_formatTimeStr(endRaw)}).';
    } else {
      final today = DateUtils.dateOnly(DateTime.now());
      final selected = DateUtils.dateOnly(_selectedDate);
      if (DateUtils.isSameDay(selected, today)) {
        final now = DateTime.now();
        final nowTotalMin = now.hour * 60 + now.minute;
        if (leaveTotalMin <= nowTotalMin) {
          _timeError = 'Time must be later than the current time.';
        } else {
          _timeError = null;
        }
      } else {
        _timeError = null;
      }
    }
  }

  bool _validateForm() {
    final reason = _reasonController.text.trim();
    String? reasonErr;
    if (reason.isEmpty) {
      reasonErr = 'Please input Reason';
    }

    _validateTimeOnly();

    setState(() {
      _reasonError = reasonErr;
    });

    return _reasonError == null && _timeError == null;
  }

  Future<void> _fetchSectionTimes() async {
    try {
      final res = await ApiService().get('/attendance/status/');
      if (res is Map && res['schedule'] is Map) {
        final sched = res['schedule'] as Map;
        final s1S =
            sched['base_section1_start']?.toString() ??
            sched['section1_start']?.toString();
        final s1E =
            sched['base_section1_end']?.toString() ??
            sched['section1_end']?.toString();
        final s2S =
            sched['base_section2_start']?.toString() ??
            sched['section2_start']?.toString();
        final s2E =
            sched['base_section2_end']?.toString() ??
            sched['section2_end']?.toString();

        if (mounted) {
          setState(() {
            if (s1S != null && s1S.length >= 5) _s1Start = s1S.substring(0, 5);
            if (s1E != null && s1E.length >= 5) _s1End = s1E.substring(0, 5);
            if (s2S != null && s2S.length >= 5) _s2Start = s2S.substring(0, 5);
            if (s2E != null && s2E.length >= 5) _s2End = s2E.substring(0, 5);
            if (!_isEditing) {
              _earlyLeaveTime = _defaultEarlyLeaveTimeForSection(_session);
            }
            _validateTimeOnly();
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final res = await ApiService().get('/employees/me/');
      if (res is Map) {
        final s1S = res['section1_start']?.toString();
        final s1E = res['section1_end']?.toString();
        final s2S = res['section2_start']?.toString();
        final s2E = res['section2_end']?.toString();

        if (mounted) {
          setState(() {
            if (s1S != null && s1S.length >= 5) _s1Start = s1S.substring(0, 5);
            if (s1E != null && s1E.length >= 5) _s1End = s1E.substring(0, 5);
            if (s2S != null && s2S.length >= 5) _s2Start = s2S.substring(0, 5);
            if (s2E != null && s2E.length >= 5) _s2End = s2E.substring(0, 5);
            if (!_isEditing) {
              _earlyLeaveTime = _defaultEarlyLeaveTimeForSection(_session);
            }
            _validateTimeOnly();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;

    // Pre-populate from HomeController if available
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.session1SchedIn.value.length >= 5) {
        _s1Start = home.session1SchedIn.value;
      }
      if (home.session1SchedOut.value.length >= 5) {
        _s1End = home.session1SchedOut.value;
      }
      if (home.session2SchedIn.value.length >= 5) {
        _s2Start = home.session2SchedIn.value;
      }
      if (home.session2SchedOut.value.length >= 5) {
        _s2End = home.session2SchedOut.value;
      }
    }

    final today = DateUtils.dateOnly(DateTime.now());
    _selectedDate = today;
    _earlyLeaveTime = _defaultEarlyLeaveTimeForSection(_session, today);

    // Fetch up-to-date shift section times directly from backend
    _fetchSectionTimes();

    // Check for arguments (passed when editing a pending request or from early checkout prompt)
    final args = widget.editId ?? Get.arguments;
    if (args is int) {
      _tabIndex = args;
    } else if (args == '1' || args == 'history' || args == 'pending') {
      _tabIndex = 1;
    } else if (args is String) {
      final existing = _controller.findById(args);
      if (existing != null && existing.status == LeaveStatus.pending) {
        _editId = existing.id;
        _selectedDate = existing.fromDate;
        _session = existing.session == 2 ? 2 : 1;
        if (existing.earlyLeaveTime != null &&
            existing.earlyLeaveTime!.isNotEmpty) {
          final parts = existing.earlyLeaveTime!.split(':');
          if (parts.length >= 2) {
            _earlyLeaveTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts[1]) ?? 30,
            );
          }
        }
        _reasonController.text = existing.reason;
        _tabIndex = 0; // Force to form when editing
      }
    } else if (args is Map) {
      if (args['tab'] != null) {
        _tabIndex = int.tryParse(args['tab'].toString()) ?? 0;
      }
      if (args['session'] is int) {
        final s = args['session'] as int;
        _session = s == 2 ? 2 : 1;
      }
      if (args['reason'] is String) {
        _reasonController.text = args['reason'] as String;
      }
      if (args['earlyLeaveTime'] is TimeOfDay) {
        _earlyLeaveTime = args['earlyLeaveTime'] as TimeOfDay;
      }
    }

    _controller.fetchRequests();

    final bool explicitSessionPassed = args is Map && args['session'] != null;
    // Auto switch to Section 2 if Section 1 has ended and no explicit session was passed
    if (!explicitSessionPassed && _isSection1Finished && _session == 1) {
      _session = 2;
      _earlyLeaveTime = _defaultEarlyLeaveTimeForSection(2, today);
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
      setState(() {
        _selectedDate = picked;
        if (_isSection1Finished && _session == 1) {
          _session = 2;
        }
        _earlyLeaveTime = _defaultEarlyLeaveTimeForSection(_session, picked);
        _validateTimeOnly();
      });
    }
  }

  Future<void> _pickEarlyLeaveTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _earlyLeaveTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _earlyLeaveTime = picked;
        _validateTimeOnly();
      });
    }
  }

  Future<void> _submit() async {
    final isValid = _validateForm();
    if (!isValid) {
      return;
    }

    if (!_isEditing && _hasExistingLeaveOnSelectedDate) {
      Get.snackbar(
        'Request Limit',
        'You already have an active leave request for this date. Leave can only be requested once per day.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final reason = _reasonController.text.trim();
    setState(() => _isSubmitting = true);

    final earlyTimeStr =
        '${_earlyLeaveTime.hour.toString().padLeft(2, '0')}:${_earlyLeaveTime.minute.toString().padLeft(2, '0')}:00';

    final dayTypeStr = _session == 1
        ? 'Section 1 (Morning)'
        : 'Section 2 (Afternoon)';

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
        hasAttachment: false,
      );
      if (ok) {
        Get.snackbar(
          'Request Updated',
          'Your leave request has been updated successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
        setState(() {
          _editId = null;
          _reasonError = null;
          _timeError = null;
          _tabIndex = 1;
        });
      } else {
        final err = _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Failed to update leave request. Please check your input and try again.';
        Get.snackbar(
          'Update Failed',
          err,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
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
        hasAttachment: false,
      );
      if (ok) {
        Get.snackbar(
          'Request Submitted',
          'Your early leave request has been submitted successfully.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
        _reasonController.clear();
        setState(() {
          _reasonError = null;
          _timeError = null;
          _tabIndex = 1;
        });
      } else {
        final err = _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Failed to submit leave request. Please check your input and try again.';
        Get.snackbar(
          'Submission Failed',
          err,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
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
              onChanged: (index) {
                setState(() => _tabIndex = index);
                if (index == 0) {
                  _fetchSectionTimes();
                  _controller.fetchRequests().then((_) {
                    if (mounted) setState(() {});
                  });
                }
              },
            ),

            const SizedBox(height: 18),

            // Body according to active tab
            if (_tabIndex == 0) _buildRequestForm() else _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSelector() {
    final s1Disabled = _isSection1Finished;

    return Row(
      children: [
        // Section 1
        Expanded(
          child: GestureDetector(
            onTap: s1Disabled
                ? null
                : () {
                    setState(() {
                      _session = 1;
                      _earlyLeaveTime = _defaultEarlyLeaveTimeForSection(1);
                      _validateTimeOnly();
                    });
                  },
            child: Opacity(
              opacity: s1Disabled ? 0.45 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (!s1Disabled && _session == 1)
                        ? RequestColors.primary
                        : const Color(0xFFE5E5EA),
                    width: (!s1Disabled && _session == 1) ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Section 1',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: (!s1Disabled && _session == 1)
                                ? RequestColors.primary
                                : RequestColors.textPrimary,
                          ),
                        ),
                        if (s1Disabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E8E93)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Ended',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _s1TimeDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: (!s1Disabled && _session == 1)
                            ? RequestColors.primary
                            : RequestColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Section 2
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _session = 2;
                _earlyLeaveTime = _defaultEarlyLeaveTimeForSection(2);
                _validateTimeOnly();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _session == 2
                      ? RequestColors.primary
                      : const Color(0xFFE5E5EA),
                  width: _session == 2 ? 1.8 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Section 2',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _session == 2
                          ? RequestColors.primary
                          : RequestColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _s2TimeDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _session == 2
                          ? RequestColors.primary
                          : RequestColors.textSecondary,
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

  Widget _buildTimePicker() {
    final secName = _session == 1 ? 'Section 1' : 'Section 2';
    final endTimeStr = _session == 1 ? _s1End : _s2End;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _timeError != null
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE5E5EA),
              width: _timeError != null ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time ($secName)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: RequestColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Before ${_formatTimeStr(endTimeStr)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: RequestColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickEarlyLeaveTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: RequestColors.softSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _timeError != null
                          ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                          : RequestColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 22,
                        color: _timeError != null
                            ? const Color(0xFFEF4444)
                            : RequestColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Early Leave At',
                              style: TextStyle(
                                fontSize: 11,
                                color: RequestColors.textSecondary,
                              ),
                            ),
                            Text(
                              _earlyLeaveTime.format(context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _timeError != null
                                    ? const Color(0xFFEF4444)
                                    : RequestColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _timeError != null
                              ? const Color(0xFFEF4444)
                              : RequestColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
        if (_timeError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _timeError!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRequestForm() {
    return Obx(() {
      final hasExisting = _hasExistingLeaveOnSelectedDate;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Workday',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _DateSelectionCard(
            dateText: DateText.fullDate(_selectedDate),
            subtitle: DateUtils.isSameDay(_selectedDate, DateTime.now())
                ? 'Today • Workday'
                : 'Selected Date',
            onTapChange: _pickDate,
          ),

          const SizedBox(height: 16),

          // Section to Leave
          const Text(
            'Work Section to Leave',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSectionSelector(),

          const SizedBox(height: 14),
          _buildTimePicker(),

          const SizedBox(height: 16),

          // Reason *
          RichText(
            text: const TextSpan(
              text: 'Reason ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RequestColors.textPrimary,
              ),
              children: [
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
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _reasonError != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E5EA),
                width: _reasonError != null ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _reasonController,
              onChanged: (val) {
                if (_reasonError != null && val.trim().isNotEmpty) {
                  setState(() => _reasonError = null);
                }
              },
              minLines: 3,
              maxLines: 4,
              maxLength: 250,
              style: const TextStyle(
                fontSize: 14,
                color: RequestColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Please provide details about your leave request...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: RequestColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
          ),
          if (_reasonError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _reasonError!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!_isEditing && hasExisting) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You already have an active leave request for this date. Leave early can only be requested once per day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Submit Button (Apple style pill)
          RequestButton(
            label: _isSubmitting
                ? 'Submitting...'
                : (_isEditing
                      ? 'Update Leave Request'
                      : 'Submit Leave Request'),
            onPressed: (_isSubmitting || (!_isEditing && hasExisting))
                ? null
                : _submit,
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Requests require approval from your direct supervisor',
              style: TextStyle(
                fontSize: 12,
                color: RequestColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHistoryList() {
    return Obx(() {
      final allItems = _controller.requests;

      final items = _historyFilter == 'All'
          ? allItems
          : (_historyFilter == 'Pending'
                ? allItems
                      .where((r) => r.status == LeaveStatus.pending)
                      .toList()
                : (_historyFilter == 'Approved'
                      ? allItems
                            .where((r) => r.status == LeaveStatus.approved)
                            .toList()
                      : allItems
                            .where((r) => r.status == LeaveStatus.rejected)
                            .toList()));

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
                          ? allItems
                                .where((r) => r.status == LeaveStatus.pending)
                                .length
                          : (f == 'Approved'
                                ? allItems
                                      .where(
                                        (r) => r.status == LeaveStatus.approved,
                                      )
                                      .length
                                : allItems
                                      .where(
                                        (r) => r.status == LeaveStatus.rejected,
                                      )
                                      .length));

                return GestureDetector(
                  onTap: () => setState(() => _historyFilter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? RequestColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? RequestColors.primary
                            : const Color(0xFFE5E5EA),
                      ),
                    ),
                    child: Text(
                      '$f ($count)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : RequestColors.textPrimary,
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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: RequestColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 28,
                      color: RequestColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _historyFilter == 'All'
                        ? 'No Leave Requests Yet'
                        : 'No $_historyFilter Requests',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: RequestColors.textPrimary,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.status.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusTextColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Text(
                            DateText.shortDate(req.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: RequestColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            DateText.mediumDate(req.fromDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            req.scheduleLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
                            color: RequestColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF2F2F7)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPending) ...[
                            TextButton(
                              onPressed: () => _confirmCancel(req.id),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: RequestColors.danger,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _editId = req.id;
                                  _selectedDate = req.fromDate;
                                  _session = req.session == 2 ? 2 : 1;
                                  if (req.earlyLeaveTime != null &&
                                      req.earlyLeaveTime!.isNotEmpty) {
                                    final parts = req.earlyLeaveTime!.split(
                                      ':',
                                    );
                                    if (parts.length >= 2) {
                                      _earlyLeaveTime = TimeOfDay(
                                        hour: int.tryParse(parts[0]) ?? 9,
                                        minute: int.tryParse(parts[1]) ?? 30,
                                      );
                                    }
                                  }
                                  _reasonController.text = req.reason;
                                  _tabIndex = 0;
                                  _reasonError = null;
                                  _timeError = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: RequestColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: () => Get.toNamed(
                                AppRoutes.leaveDetail,
                                arguments: req.id,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: RequestColors.primary,
                                  ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _controller.cancelRequest(id);
              if (mounted) {
                setState(() {});
              }
              if (success) {
                Get.snackbar(
                  'Request Cancelled',
                  'Your leave request has been cancelled successfully. You can now submit a new request.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                  ),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                  duration: const Duration(seconds: 4),
                );
              } else {
                final err = _controller.errorMessage.value.isNotEmpty
                    ? _controller.errorMessage.value
                    : 'Failed to cancel the leave request. Please try again.';
                Get.snackbar(
                  'Cancellation Failed',
                  err,
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: const Color(0xFFEF4444),
                  colorText: Colors.white,
                  icon: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                  ),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                  duration: const Duration(seconds: 4),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RequestColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Apple Date selection card
class _DateSelectionCard extends StatelessWidget {
  const _DateSelectionCard({
    required this.dateText,
    required this.subtitle,
    required this.onTapChange,
  });

  final String dateText;
  final String subtitle;
  final VoidCallback onTapChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: appleCardDecoration(radius: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RequestColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: RequestColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
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
