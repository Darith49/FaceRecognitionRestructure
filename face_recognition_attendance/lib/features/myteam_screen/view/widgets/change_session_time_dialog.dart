import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/myteam_screen/model/my_team_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeSessionTimeDialog extends StatefulWidget {
  final int memberId;
  final String memberName;
  final String memberRole;
  final String memberSubtitle;
  final String? initialSection1Start;
  final String? initialSection1End;
  final String? initialSection2Start;
  final String? initialSection2End;
  final String? initialWorkDays;
  final Future<bool> Function({
    required int memberId,
    required String section1Start,
    required String section1End,
    required String section2Start,
    required String section2End,
    required String workDays,
  }) onSave;

  const ChangeSessionTimeDialog({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.memberRole,
    required this.memberSubtitle,
    this.initialSection1Start,
    this.initialSection1End,
    this.initialSection2Start,
    this.initialSection2End,
    this.initialWorkDays,
    required this.onSave,
  });

  /// Factory helper for MyTeamMember
  static Future<bool?> showForMember(
    BuildContext context, {
    required MyTeamMember member,
    required Future<bool> Function({
      required int memberId,
      required String section1Start,
      required String section1End,
      required String section2Start,
      required String section2End,
      required String workDays,
    }) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeSessionTimeDialog(
        memberId: member.id,
        memberName: member.fullname,
        memberRole: member.displayRole,
        memberSubtitle: member.organizationSubtitle,
        initialSection1Start: member.section1Start,
        initialSection1End: member.section1End,
        initialSection2Start: member.section2Start,
        initialSection2End: member.section2End,
        initialWorkDays: member.workDays,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ChangeSessionTimeDialog> createState() => _ChangeSessionTimeDialogState();
}

class _ChangeSessionTimeDialogState extends State<ChangeSessionTimeDialog> {
  late TimeOfDay _s1Start;
  late TimeOfDay _s1End;
  late TimeOfDay _s2Start;
  late TimeOfDay _s2End;

  late Set<String> _selectedDays;
  bool _isSubmitting = false;
  String? _validationError;

  static const List<Map<String, String>> _allDays = [
    {'code': 'mon', 'label': 'Mon'},
    {'code': 'tue', 'label': 'Tue'},
    {'code': 'wed', 'label': 'Wed'},
    {'code': 'thu', 'label': 'Thu'},
    {'code': 'fri', 'label': 'Fri'},
    {'code': 'sat', 'label': 'Sat'},
    {'code': 'sun', 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _s1Start = _parseTime(widget.initialSection1Start, const TimeOfDay(hour: 7, minute: 0));
    _s1End = _parseTime(widget.initialSection1End, const TimeOfDay(hour: 11, minute: 0));
    _s2Start = _parseTime(widget.initialSection2Start, const TimeOfDay(hour: 13, minute: 0));
    _s2End = _parseTime(widget.initialSection2End, const TimeOfDay(hour: 17, minute: 0));

    final rawDays = widget.initialWorkDays?.toLowerCase() ?? 'mon,tue,wed,thu,fri';
    _selectedDays = rawDays
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toSet();
    if (_selectedDays.isEmpty) {
      _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri'};
    }
  }

  TimeOfDay _parseTime(String? timeStr, TimeOfDay fallback) {
    if (timeStr == null || timeStr.trim().isEmpty) return fallback;
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return fallback;
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _formatDisplayTime(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _timeToMinutes(TimeOfDay tod) => tod.hour * 60 + tod.minute;

  String _calcDuration(TimeOfDay start, TimeOfDay end) {
    final diff = _timeToMinutes(end) - _timeToMinutes(start);
    if (diff <= 0) return '0h 00m';
    final hours = diff ~/ 60;
    final mins = diff % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  String _calcTotalHours() {
    final diff1 = _timeToMinutes(_s1End) - _timeToMinutes(_s1Start);
    final diff2 = _timeToMinutes(_s2End) - _timeToMinutes(_s2Start);
    final total = (diff1 > 0 ? diff1 : 0) + (diff2 > 0 ? diff2 : 0);
    final hours = total ~/ 60;
    final mins = total % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  void _validate() {
    final s1StartMin = _timeToMinutes(_s1Start);
    final s1EndMin = _timeToMinutes(_s1End);
    final s2StartMin = _timeToMinutes(_s2Start);
    final s2EndMin = _timeToMinutes(_s2End);

    if (s1StartMin >= s1EndMin) {
      _validationError = 'Session 1: End time must be after start time.';
      return;
    }
    if (s2StartMin < s1EndMin) {
      _validationError = 'Session 2: Cannot start before Session 1 ends.';
      return;
    }
    if (s2StartMin >= s2EndMin) {
      _validationError = 'Session 2: End time must be after start time.';
      return;
    }
    if (_selectedDays.isEmpty) {
      _validationError = 'Please select at least one active work day.';
      return;
    }

    _validationError = null;
  }

  Future<void> _pickTime({
    required BuildContext context,
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: RequestColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: RequestColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        onSelected(picked);
        _validate();
      });
    }
  }

  Future<void> _handleSave() async {
    _validate();
    if (_validationError != null) {
      setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final workDaysString = _allDays
          .where((d) => _selectedDays.contains(d['code']))
          .map((d) => d['code']!)
          .join(',');

      final success = await widget.onSave(
        memberId: widget.memberId,
        section1Start: _formatTimeOfDay(_s1Start),
        section1End: _formatTimeOfDay(_s1End),
        section2Start: _formatTimeOfDay(_s2Start),
        section2End: _formatTimeOfDay(_s2End),
        workDays: workDaysString,
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        Get.snackbar(
          'Session Updated',
          'Work schedule for ${widget.memberName} was successfully updated.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Dialog Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RequestColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.more_time_rounded,
                    color: RequestColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Change Session Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: RequestColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.memberName} • ${widget.memberRole}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: RequestColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Daily Work Hours Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          RequestColors.primary.withValues(alpha: 0.08),
                          RequestColors.primary.withValues(alpha: 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: RequestColors.primary.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timelapse_rounded,
                          color: RequestColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Total Daily Scheduled Work:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: RequestColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: RequestColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _calcTotalHours(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Session 1 (Morning)
                  _buildSessionCard(
                    title: 'Session 1 (Morning Shift)',
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFD97706),
                    startVal: _s1Start,
                    endVal: _s1End,
                    duration: _calcDuration(_s1Start, _s1End),
                    onPickStart: () => _pickTime(
                      context: context,
                      initial: _s1Start,
                      onSelected: (t) => _s1Start = t,
                    ),
                    onPickEnd: () => _pickTime(
                      context: context,
                      initial: _s1End,
                      onSelected: (t) => _s1End = t,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Session 2 (Afternoon)
                  _buildSessionCard(
                    title: 'Session 2 (Afternoon Shift)',
                    icon: Icons.wb_twilight_rounded,
                    iconColor: const Color(0xFF2563EB),
                    startVal: _s2Start,
                    endVal: _s2End,
                    duration: _calcDuration(_s2Start, _s2End),
                    onPickStart: () => _pickTime(
                      context: context,
                      initial: _s2Start,
                      onSelected: (t) => _s2Start = t,
                    ),
                    onPickEnd: () => _pickTime(
                      context: context,
                      initial: _s2End,
                      onSelected: (t) => _s2End = t,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Active Work Days Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ACTIVE WORK DAYS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: RequestColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          _presetLink('Mon-Fri', () {
                            setState(() {
                              _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri'};
                              _validate();
                            });
                          }),
                          const SizedBox(width: 8),
                          _presetLink('All', () {
                            setState(() {
                              _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
                              _validate();
                            });
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Work day selection chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allDays.map((day) {
                      final isSelected = _selectedDays.contains(day['code']);
                      return FilterChip(
                        label: Text(day['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day['code']!);
                            } else {
                              if (_selectedDays.length > 1) {
                                _selectedDays.remove(day['code']!);
                              }
                            }
                            _validate();
                          });
                        },
                        selectedColor: RequestColors.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : RequestColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: RequestColors.softSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? RequestColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Validation error alert
                  if (_validationError != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: RequestColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: RequestColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: RequestColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: const TextStyle(
                                color: RequestColors.danger,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: RequestColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RequestColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Text(
                                  'Save Session Schedule',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required TimeOfDay startVal,
    required TimeOfDay endVal,
    required String duration,
    required VoidCallback onPickStart,
    required VoidCallback onPickEnd,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RequestColors.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: RequestColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _timeField(
                  label: 'Start (Check-in)',
                  displayValue: _formatDisplayTime(startVal),
                  onTap: onPickStart,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: RequestColors.textSecondary,
                ),
              ),
              Expanded(
                child: _timeField(
                  label: 'End (Check-out)',
                  displayValue: _formatDisplayTime(endVal),
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String displayValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: RequestColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: RequestColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: RequestColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: RequestColors.primary,
          ),
        ),
      ),
    );
  }
}
