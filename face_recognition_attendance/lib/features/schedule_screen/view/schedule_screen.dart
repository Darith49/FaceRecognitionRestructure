import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum DayStatus { worked, absent, dayOff, overtime, none }

class _DayCell {
  final int? day;
  final DayStatus status;
  final bool selected;

  const _DayCell(
    this.day, {
    this.status = DayStatus.none,
    this.selected = false,
  });
}

class _ScheduleDay {
  final String label;
  final List<String> times;
  final List<Color> gradient;
  final IconData icon;

  const _ScheduleDay(this.label, this.times, this.gradient, this.icon);
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
  int _tabIndex = 0;
  final _tabs = const ["Workday", "Holiday", "Leave"];

  // Cooler palette: indigo -> violet, with vivid accent colors per status.
  static const _primary = Color(0xFF6C5DD3);
  static const _primaryDark = Color(0xFF483CC4);
  static const _accent = Color(0xFF00D2C6);

  final List<List<_DayCell>> _weeks = const [
    [
      _DayCell(1, status: DayStatus.worked),
      _DayCell(2, status: DayStatus.worked),
      _DayCell(3, status: DayStatus.absent),
      _DayCell(4, status: DayStatus.worked),
      _DayCell(5, status: DayStatus.worked),
      _DayCell(6, status: DayStatus.worked),
      _DayCell(7, status: DayStatus.dayOff),
    ],
    [
      _DayCell(8, status: DayStatus.worked),
      _DayCell(9, status: DayStatus.worked, selected: true),
      _DayCell(10, status: DayStatus.worked),
      _DayCell(11, status: DayStatus.worked),
      _DayCell(12, status: DayStatus.worked),
      _DayCell(13, status: DayStatus.worked),
      _DayCell(14, status: DayStatus.dayOff),
    ],
    [
      _DayCell(15, status: DayStatus.worked),
      _DayCell(16, status: DayStatus.worked),
      _DayCell(17, status: DayStatus.worked),
      _DayCell(18, status: DayStatus.worked),
      _DayCell(19, status: DayStatus.worked),
      _DayCell(20, status: DayStatus.worked),
      _DayCell(21, status: DayStatus.dayOff),
    ],
    [
      _DayCell(22, status: DayStatus.worked),
      _DayCell(23, status: DayStatus.worked),
      _DayCell(24, status: DayStatus.worked),
      _DayCell(25, status: DayStatus.dayOff),
      _DayCell(26, status: DayStatus.worked),
      _DayCell(27, status: DayStatus.worked),
      _DayCell(28, status: DayStatus.overtime),
    ],
    [
      _DayCell(29, status: DayStatus.worked),
      _DayCell(30, status: DayStatus.worked),
      _DayCell(null),
      _DayCell(null),
      _DayCell(null),
      _DayCell(null),
      _DayCell(null),
    ],
  ];

  final List<_ScheduleDay> _schedule = const [
    _ScheduleDay(
      "Mon",
      ["06:00AM – 12:00PM", "01:00PM – 05:00PM"],
      [Color(0xFF6C5DD3), Color(0xFF836FFF)],
      Icons.wb_sunny_rounded,
    ),
    _ScheduleDay(
      "Tue",
      ["06:00AM – 12:00PM", "01:00PM – 05:00PM"],
      [Color(0xFF00C6AE), Color(0xFF00D2C6)],
      Icons.bolt_rounded,
    ),
    _ScheduleDay(
      "Wed",
      ["06:00AM – 12:00PM", "01:00PM – 05:00PM"],
      [Color(0xFFFF6FA8), Color(0xFFB84FFF)],
      Icons.local_fire_department_rounded,
    ),
  ];

  Color _statusColor(DayStatus s) {
    switch (s) {
      case DayStatus.worked:
        return const Color(0xFF3DDC97);
      case DayStatus.absent:
        return const Color(0xFFFF9F43);
      case DayStatus.dayOff:
        return const Color(0xFFFF5C7C);
      case DayStatus.overtime:
        return const Color(0xFFB48CFF);
      case DayStatus.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF0FB), Color(0xFFF7F7FC), Color(0xFFF6F7FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 22),
                _buildHeroBanner(),
                const SizedBox(height: 22),
                const Text(
                  "September Performance",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                _buildStatsGrid(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Absence Limit : 8",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCalendarCard(),
                const SizedBox(height: 22),
                _buildTabBar(),
                const SizedBox(height: 16),
                ..._schedule.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildScheduleTile(d),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: _primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          "Schedule",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, Color(0xFF836FFF)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color(0xFF836FFF), Color(0xFF00D2C6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're on track 🔥",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "18 / 22 days worked",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: 18 / 22,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      (
        "Days Goal",
        "22",
        Icons.flag_rounded,
        const [Color(0xFF6C5DD3), Color(0xFF836FFF)],
      ),
      (
        "Day Worked",
        "18",
        Icons.check_circle_rounded,
        const [Color(0xFF00C6AE), Color(0xFF00D2C6)],
      ),
      (
        "Days Absence",
        "2",
        Icons.event_busy_rounded,
        const [Color(0xFFFF9F43), Color(0xFFFFC26F)],
      ),
      (
        "On-Time Rate",
        "92%",
        Icons.timer_rounded,
        const [Color(0xFFFF6FA8), Color(0xFFB84FFF)],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) {
        final (label, value, icon, colors) = stats[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarCard() {
    const weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Calendar View",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "September",
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  _navArrow(Icons.chevron_left_rounded),
                  const SizedBox(width: 8),
                  _navArrow(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: weekdayLabels
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ..._weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: week
                    .map((cell) => Expanded(child: _buildDayCell(cell)))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legendDot(_statusColor(DayStatus.worked), "Worked"),
              _legendDot(_statusColor(DayStatus.absent), "Absent"),
              _legendDot(_statusColor(DayStatus.dayOff), "Day off"),
              _legendDot(_statusColor(DayStatus.overtime), "Over time"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: _primaryDark),
    );
  }

  Widget _buildDayCell(_DayCell cell) {
    if (cell.day == null) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }

    final bool hasStatus = cell.status != DayStatus.none;
    final color = _statusColor(cell.status);

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: hasStatus
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.75)],
                  )
                : null,
            color: hasStatus ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: cell.selected
                ? Border.all(color: _primary, width: 2.4)
                : null,
            boxShadow: hasStatus
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            "${cell.day}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cell.selected && !hasStatus
                  ? _primary
                  : (hasStatus ? Colors.white : Colors.black87),
            ),
          ),
        ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == _tabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [_primary, Color(0xFF836FFF)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected ? Colors.white : Colors.grey.shade500,
                  ),
                  child: Text(_tabs[i], textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScheduleTile(_ScheduleDay day) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: day.gradient[0].withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: day.gradient,
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(day.icon, color: Colors.white, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    day.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: day.gradient[0],
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Shifts",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...day.times.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
