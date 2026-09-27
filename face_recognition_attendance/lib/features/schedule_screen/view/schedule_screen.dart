import 'package:face_recognition_attendance/config/theme/app_colors.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/schedule_screen/controller/schedule_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

// ---------------------------------------------------------------------------
// Local design tokens (only used by this screen)
// ---------------------------------------------------------------------------

const Color _primaryDark = Color(0xFF2456C7);

BoxDecoration _cardDecoration({BuildContext? context, double radius = 20}) =>
    appleCardDecoration(context: context, radius: radius);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ScheduleScreen extends GetView<ScheduleController> {
  const ScheduleScreen({super.key, this.showBackButton = false});

  @override
  ScheduleController get controller => Get.isRegistered<ScheduleController>()
      ? Get.find<ScheduleController>()
      : Get.put(ScheduleController());

  /// false = the "Schedule" tab of the bottom bar (no back arrow).
  /// true  = opened on top of another page with AppRoutes.schedule.
  final bool showBackButton;

  // ------------------------------- helpers ---------------------------------

  Color _statusColor(DayStatus s) => switch (s) {
    DayStatus.worked => RequestColors.approvedStatus,
    DayStatus.workday => const Color(0xFF2E7D32),
    DayStatus.absent => RequestColors.danger,
    DayStatus.dayOff => RequestColors.teal,
    DayStatus.overtime => const Color(0xFF7B1FA2),
    DayStatus.leave => RequestColors.gold,
    DayStatus.none => RequestColors.primary,
  };

  String _statusLabel(DayStatus s) => switch (s) {
    DayStatus.worked => 'Worked'.tr,
    DayStatus.workday => 'Workday'.tr,
    DayStatus.absent => 'Absent'.tr,
    DayStatus.dayOff => 'Day off'.tr,
    DayStatus.overtime => 'Overtime'.tr,
    DayStatus.leave => 'Leave'.tr,
    DayStatus.none => 'No record'.tr,
  };

  IconData _statusIcon(DayStatus s) => switch (s) {
    DayStatus.worked => FluentIcons.checkmark_circle_24_regular,
    DayStatus.workday => FluentIcons.briefcase_24_regular,
    DayStatus.absent => FluentIcons.dismiss_circle_24_regular,
    DayStatus.dayOff => FluentIcons.bed_24_regular,
    DayStatus.overtime => FluentIcons.timer_24_regular,
    DayStatus.leave => FluentIcons.beach_24_regular,
    DayStatus.none => FluentIcons.calendar_ltr_24_regular,
  };

  // -------------------------------- build ----------------------------------

  @override
  Widget build(BuildContext context) {
    return RequestScaffold(
      title: 'Schedule'.tr,
      showBackButton: showBackButton,
      body: ListView(
        // Extra space at the bottom in the tab, so the floating bar does not cover the cards.
        padding: EdgeInsets.fromLTRB(16, 16, 16, showBackButton ? 24.0 : 120.0),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          Obx(() {
            final month = controller.focusedDay.value.month;
            final mName = DateText.monthName(month);
            return _SectionTitle('$mName ${'Performance'.tr}');
          }),
          _buildStatsGrid(context),
          const SizedBox(height: 24),
          _buildCalendarCard(context),
          const SizedBox(height: 24),
          _SectionTitle('Work Schedule'.tr),
          _buildTabBar(context),
          const SizedBox(height: 14),
          _buildTabContent(context),
        ],
      ),
    );
  }

  // ------------------------------ summary card -----------------------------

  Widget _buildSummaryCard() {
    return Obx(() {
      final worked = controller.daysWorked.value;
      final goal = controller.daysGoal.value;
      final percent = controller.percentWorked;
      final remaining = controller.daysRemaining.value;
      final progressVal = goal > 0 ? (worked / goal).clamp(0.0, 1.0) : 0.0;

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
                                "You're on track".tr,
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
                                    TextSpan(
                                      text: '$worked',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 34,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / $goal ${'days worked'.tr}',
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
                        const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            FluentIcons.trophy_24_filled,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ProgressBar(
                      value: progressVal,
                      color: Colors.white,
                      trackColor: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$percent% ${'complete'.tr}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$remaining ${'days to go'.tr}',
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
    });
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

  Widget _buildStatsGrid(BuildContext context) {
    return Obx(() {
      final daysGoal = controller.daysGoal.value;
      final daysWorked = controller.daysWorked.value;
      final daysAbsent = controller.daysAbsent.value;
      final absenceLimit = controller.absenceLimit.value;
      final onTimeRate = controller.onTimeRate.value;

      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _statCard(
                    context: context,
                    label: 'Days Goal'.tr,
                    value: '$daysGoal',
                    icon: FluentIcons.flag_24_regular,
                    color: RequestColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context: context,
                    label: 'Days Worked'.tr,
                    value: '$daysWorked',
                    icon: FluentIcons.checkmark_circle_24_regular,
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
                    context: context,
                    label: 'Days Absent'.tr,
                    value: '$daysAbsent',
                    icon: FluentIcons.calendar_cancel_24_regular,
                    color: RequestColors.danger,
                    badge: '${'Limit'.tr} $absenceLimit',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context: context,
                    label: 'On-Time Rate'.tr,
                    value: '$onTimeRate%',
                    icon: FluentIcons.timer_24_regular,
                    color: RequestColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _statCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context: context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(icon, size: 24, color: color),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.12),
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------ calendar card ----------------------------

  Widget _buildCalendarCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar View'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final focused = controller.focusedDay.value;
                    return Text(
                      DateText.monthYear(focused),
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                        fontSize: 12,
                      ),
                    );
                  }),
                ],
              ),
              Row(
                children: [
                  _navArrow(
                    context,
                    FluentIcons.chevron_left_24_regular,
                    controller.previousMonth,
                  ),
                  const SizedBox(width: 8),
                  _navArrow(context, FluentIcons.chevron_right_24_regular, controller.nextMonth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Read the Rx values at the top of Obx, so Obx knows to rebuild.
          Obx(() {
            final focused = controller.focusedDay.value;
            final selected = controller.selectedDay.value;

            return TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: focused,
              selectedDayPredicate: (day) => isSameDay(day, selected),
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerVisible: false,
              // Swipe left / right to change month (vertical scroll stays with the page).
              availableGestures: AvailableGestures.horizontalSwipe,
              rowHeight: 46,
              daysOfWeekHeight: 28,
              calendarStyle: const CalendarStyle(outsideDaysVisible: false),
              calendarBuilders: CalendarBuilders(
                prioritizedBuilder: (ctx, day, focusedDay) =>
                    _buildDayCell(day, selected, context),
                dowBuilder: (ctx, day) => Center(
                  child: Text(
                    DateText.weekdayShort(day.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    ),
                  ),
                ),
              ),
              onCalendarCreated: controller.onCalendarCreated,
              onPageChanged: controller.onPageChanged,
              onDaySelected: controller.onDaySelected,
            );
          }),
          const SizedBox(height: 8),
          _buildSelectedDayInfo(context),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legendDot(_statusColor(DayStatus.worked), 'Worked'.tr, context),
              _legendDot(_statusColor(DayStatus.absent), 'Absent'.tr, context),
              _legendDot(_statusColor(DayStatus.dayOff), 'Day off'.tr, context),
              _legendDot(_statusColor(DayStatus.overtime), 'Overtime'.tr, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navArrow(BuildContext context, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkCard : RequestColors.background.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 20, color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary),
        ),
      ),
    );
  }

  /// Drawn by table_calendar for every day of the month (taps are handled by
  /// the calendar itself and end up in `controller.onDaySelected`).
  Widget _buildDayCell(DateTime day, DateTime selectedDay, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = controller.statusFor(day);
    final selected = isSameDay(day, selectedDay);
    final isToday = isSameDay(day, DateTime.now());
    final hasStatus = status != DayStatus.none;
    final color = _statusColor(status);

    final Color background = selected
        ? color
        : (hasStatus ? color.withValues(alpha: isDark ? 0.22 : 0.12) : Colors.transparent);
    final Color foreground = selected
        ? Colors.white
        : (hasStatus ? color : (isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary));

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
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

  Widget _buildSelectedDayInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final selectedDay = controller.selectedDay.value;
      final status = controller.statusFor(selectedDay);
      final color = _statusColor(status);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(_statusIcon(status), size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${DateText.weekdayShort(selectedDay.weekday)}, ${DateText.monthName(selectedDay.month)} ${selectedDay.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
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
    });
  }

  Widget _legendDot(Color color, String label, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --------------------------------- tabs ----------------------------------

  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = controller.tabs;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: _cardDecoration(context: context, radius: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;

          return Obx(() {
            final current = controller.tabIndex.value;

            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: tabWidth * current,
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
                  children: List.generate(tabs.length, (i) {
                    final selected = i == current;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.changeTab(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary),
                            ),
                            child: Text(tabs[i].tr),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return Obx(() {
      final current = controller.tabIndex.value;

      if (current == 0) {
        if (controller.schedule.isEmpty) {
          return _buildEmptySchedule('No scheduled shifts found for this period.'.tr, context);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: controller.schedule
              .map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildScheduleTile(d, context),
                ),
              )
              .toList(),
        );
      } else if (current == 1) {
        if (controller.holidays.isEmpty) {
          return _buildEmptyTab(isHoliday: true, context: context);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: controller.holidays
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHolidayTile(h, context),
                ),
              )
              .toList(),
        );
      } else {
        if (controller.leaves.isEmpty) {
          return _buildEmptyTab(isHoliday: false, context: context);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: controller.leaves
              .map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLeaveTile(l, context),
                ),
              )
              .toList(),
        );
      }
    });
  }

  Widget _buildHolidayTile(HolidayItem holiday, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context: context, radius: 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RequestColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              holiday.short,
              style: const TextStyle(
                color: RequestColors.teal,
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
                Text(
                  holiday.full,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  holiday.reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RequestColors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Day off'.tr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: RequestColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTile(LeaveItem leave, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context: context, radius: 18),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              FluentIcons.beach_24_regular,
              color: RequestColors.gold,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leave.leaveType.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${leave.fromDate}  →  ${leave.toDate}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
                  ),
                ),
                if (leave.reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    leave.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RequestColors.approvedStatus.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (leave.status.capitalizeFirst ?? 'Approved').tr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: RequestColors.approvedStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule(String message, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: _cardDecoration(context: context),
      child: Column(
        children: [
          const Icon(
            FluentIcons.clock_24_regular,
            color: RequestColors.primary,
            size: 36,
          ),
          const SizedBox(height: 14),
          Text(
            'No Shifts Scheduled'.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab({required bool isHoliday, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: _cardDecoration(context: context),
      child: Column(
        children: [
          Icon(
            isHoliday
                ? FluentIcons.sparkle_24_filled
                : FluentIcons.beach_24_regular,
            color: RequestColors.primary,
            size: 36,
          ),
          const SizedBox(height: 14),
          Text(
            'Nothing here yet'.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHoliday
                ? 'Public holidays will appear here once they are added.'.tr
                : 'Your leave days will appear here once they are approved.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(ScheduleDay day, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context: context, radius: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : RequestColors.textPrimary,
              borderRadius: BorderRadius.circular(14),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
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
                        '${day.totalHours} ${'hrs'.tr}',
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
                for (final shift in day.shifts) _buildShiftRow(shift, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(ScheduleShift shift, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${shift.hours}h',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : RequestColors.textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkTextPrimary : RequestColors.textPrimary,
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
  });

  final double value;
  final Color color;
  final Color trackColor;
  static const double height = 8;

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