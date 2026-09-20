import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// ---------------------------------------------------------------------------
// Local design tokens (only used by this screen)
// ---------------------------------------------------------------------------

const Color _primaryDark = Color(0xFF2456C7);

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0F1B2437), blurRadius: 14, offset: Offset(0, 4)),
];

BoxDecoration _cardDecoration({double radius = 20}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: _softShadow,
);

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum DayStatus { worked, absent, dayOff, overtime, none }

class _Shift {
  /// 24h clock hours, e.g. 6 = 06:00 AM and 17 = 05:00 PM.
  final int startHour;
  final int endHour;

  const _Shift(this.startHour, this.endHour);

  int get hours => endHour - startHour;

  String get range => '${_formatHour(startHour)} – ${_formatHour(endHour)}';
}

class _ScheduleDay {
  final String short;
  final String full;
  final List<_Shift> shifts;

  const _ScheduleDay(this.short, this.full, this.shifts);

  int get totalHours => shifts.fold(0, (sum, s) => sum + s.hours);
}

String _formatHour(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${hour12.toString().padLeft(2, '0')}:00 $period';
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const int _daysGoal = 22;
  static const int _daysWorked = 18;
  static const int _daysAbsent = 2;
  static const int _absenceLimit = 8;
  static const int _onTimeRate = 92;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  int _tabIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  PageController? _pageController;
  final _tabs = const ['Workday', 'Holiday', 'Leave'];

  final List<_ScheduleDay> _schedule = const [
    _ScheduleDay('Mon', 'Monday', [_Shift(6, 12), _Shift(13, 17)]),
    _ScheduleDay('Tue', 'Tuesday', [_Shift(6, 12), _Shift(13, 17)]),
    _ScheduleDay('Wed', 'Wednesday', [_Shift(6, 12), _Shift(13, 17)]),
  ];

  // ------------------------------- helpers ---------------------------------

  Color _statusColor(DayStatus s) => switch (s) {
    DayStatus.worked => RequestColors.approvedStatus,
    DayStatus.absent => RequestColors.danger,
    DayStatus.dayOff => RequestColors.teal,
    DayStatus.overtime => RequestColors.gold,
    DayStatus.none => RequestColors.primary,
  };

  String _statusLabel(DayStatus s) => switch (s) {
    DayStatus.worked => 'Worked',
    DayStatus.absent => 'Absent',
    DayStatus.dayOff => 'Day off',
    DayStatus.overtime => 'Overtime',
    DayStatus.none => 'No record',
  };

  IconData _statusIcon(DayStatus s) => switch (s) {
    DayStatus.worked => Icons.check_circle_rounded,
    DayStatus.absent => Icons.cancel_rounded,
    DayStatus.dayOff => Icons.weekend_rounded,
    DayStatus.overtime => Icons.more_time_rounded,
    DayStatus.none => Icons.event_rounded,
  };

  /// SAMPLE DATA ONLY: replace with the real attendance records (Firestore).
  /// Future days have no record yet; Sundays are days off.
  DayStatus _statusFor(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(day.year, day.month, day.day);

    if (date.isAfter(today)) return DayStatus.none;
    if (date.weekday == DateTime.sunday) return DayStatus.dayOff;
    if (date.day == 3) return DayStatus.absent;
    if (date.day == 12) return DayStatus.overtime;
    return DayStatus.worked;
  }

  void _changeMonth({required bool next}) {
    const duration = Duration(milliseconds: 300);
    final controller = _pageController;
    if (controller == null) return;
    if (next) {
      controller.nextPage(duration: duration, curve: Curves.easeOut);
    } else {
      controller.previousPage(duration: duration, curve: Curves.easeOut);
    }
  }

  // -------------------------------- build ----------------------------------

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Schedule',
      showBackButton: false,
      body: ListView(
        // Extra space at the bottom so the floating bar does not cover the last card.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _SectionTitle(
            '${_monthNames[DateTime.now().month - 1]} Performance',
          ),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildCalendarCard(),
          const SizedBox(height: 24),
          const _SectionTitle('Work Schedule'),
          _buildTabBar(),
          const SizedBox(height: 14),
          ..._buildTabContent(),
        ],
      ),
    );
  }

  // ------------------------------ summary card -----------------------------

  Widget _buildSummaryCard() {
    final percent = (_daysWorked / _daysGoal * 100).round();
    final remaining = _daysGoal - _daysWorked;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RequestColors.primary, _primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: RequestColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(top: -36, right: -24, child: _bubble(130, 0.10)),
            Positioned(bottom: -48, right: 70, child: _bubble(100, 0.07)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You're on track",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: '$_daysWorked',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 34,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / $_daysGoal days worked',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProgressBar(
                    value: _daysWorked / _daysGoal,
                    color: Colors.white,
                    trackColor: Colors.white.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$percent% complete',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$remaining days to go',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }

  // ------------------------------- stats grid ------------------------------

  Widget _buildStatsGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(
                  label: 'Days Goal',
                  value: '$_daysGoal',
                  icon: Icons.flag_rounded,
                  color: RequestColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  label: 'Days Worked',
                  value: '$_daysWorked',
                  icon: Icons.check_circle_rounded,
                  color: RequestColors.approvedStatus,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _statCard(
                  label: 'Days Absent',
                  value: '$_daysAbsent',
                  icon: Icons.event_busy_rounded,
                  color: RequestColors.danger,
                  badge: 'Limit $_absenceLimit',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  label: 'On-Time Rate',
                  value: '$_onTimeRate%',
                  icon: Icons.timer_rounded,
                  color: RequestColors.gold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: RequestColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------ calendar card ----------------------------

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calendar View',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: RequestColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_monthNames[_focusedDay.month - 1]} ${_focusedDay.year}',
                    style: const TextStyle(
                      color: RequestColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _navArrow(
                    Icons.chevron_left_rounded,
                    () => _changeMonth(next: false),
                  ),
                  const SizedBox(width: 8),
                  _navArrow(
                    Icons.chevron_right_rounded,
                    () => _changeMonth(next: true),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            // Swipe left / right to change month (vertical scroll stays with the page).
            availableGestures: AvailableGestures.horizontalSwipe,
            rowHeight: 46,
            daysOfWeekHeight: 28,
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: _buildDayCell,
              dowBuilder: (context, day) => Center(
                child: Text(
                  _weekdayLabels[day.weekday - 1],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RequestColors.textSecondary,
                  ),
                ),
              ),
            ),
            onCalendarCreated: (controller) => _pageController = controller,
            onPageChanged: (focusedDay) =>
                setState(() => _focusedDay = focusedDay),
            onDaySelected: (selectedDay, focusedDay) => setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            }),
          ),
          const SizedBox(height: 8),
          _buildSelectedDayInfo(),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legendDot(_statusColor(DayStatus.worked), 'Worked'),
              _legendDot(_statusColor(DayStatus.absent), 'Absent'),
              _legendDot(_statusColor(DayStatus.dayOff), 'Day off'),
              _legendDot(_statusColor(DayStatus.overtime), 'Overtime'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: RequestColors.background.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 20, color: RequestColors.textPrimary),
        ),
      ),
    );
  }

  /// Drawn by table_calendar for every day of the month (taps are handled by
  /// the calendar itself and end up in `onDaySelected`).
  Widget _buildDayCell(BuildContext context, DateTime day, DateTime focused) {
    final status = _statusFor(day);
    final selected = isSameDay(day, _selectedDay);
    final isToday = isSameDay(day, DateTime.now());
    final hasStatus = status != DayStatus.none;
    final color = _statusColor(status);

    final Color background = selected
        ? color
        : (hasStatus ? color.withValues(alpha: 0.12) : Colors.transparent);
    final Color foreground = selected
        ? Colors.white
        : (hasStatus ? color : RequestColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !selected
              ? Border.all(color: RequestColors.primary, width: 1.5)
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayInfo() {
    final status = _statusFor(_selectedDay);
    final color = _statusColor(status);
    final weekday = _weekdayLabels[_selectedDay.weekday - 1];
    final month = _monthNames[_selectedDay.month - 1];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$weekday, $month ${_selectedDay.day}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RequestColors.textPrimary,
              ),
            ),
          ),
          Text(
            _statusLabel(status),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: RequestColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --------------------------------- tabs ----------------------------------

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: _cardDecoration(radius: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / _tabs.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: tabWidth * _tabIndex,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: RequestColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: RequestColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = i == _tabIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _tabIndex = i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: selected
                                ? Colors.white
                                : RequestColors.textSecondary,
                          ),
                          child: Text(_tabs[i]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTabContent() {
    if (_tabIndex == 0) {
      return _schedule
          .map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildScheduleTile(d),
            ),
          )
          .toList();
    }
    return [_buildEmptyTab()];
  }

  Widget _buildEmptyTab() {
    final isHoliday = _tabIndex == 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RequestColors.primary.withValues(alpha: 0.10),
            ),
            child: Icon(
              isHoliday
                  ? Icons.celebration_rounded
                  : Icons.beach_access_rounded,
              color: RequestColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing here yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHoliday
                ? 'Public holidays will appear here once they are added.'
                : 'Your leave days will appear here once they are approved.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: RequestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(_ScheduleDay day) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RequestColors.textPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              day.short,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        day.full,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: RequestColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RequestColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${day.totalHours} hrs',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: RequestColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final shift in day.shifts) _buildShiftRow(shift),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(_Shift shift) {
    final color = shift.startHour < 12
        ? RequestColors.gold
        : RequestColors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              shift.range,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RequestColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${shift.hours}h',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RequestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small private widgets
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: RequestColors.textPrimary,
        ),
      ),
    );
  }
}

/// Simple rounded progress bar (drawn by hand so it looks the same on every
/// Flutter version).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    required this.trackColor,
    this.height = 8,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            Container(
              width: width * value.clamp(0.0, 1.0),
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ],
        );
      },
    );
  }
}