import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum DayStatus { worked, absent, dayOff, overtime, none }

class ScheduleShift {
  /// 24h clock hours, e.g. 6 = 06:00 AM and 17 = 05:00 PM.
  final int startHour;
  final int endHour;

  const ScheduleShift(this.startHour, this.endHour);

  int get hours => endHour - startHour;

  String get range => '${_formatHour(startHour)} – ${_formatHour(endHour)}';
}

class ScheduleDay {
  final String short;
  final String full;
  final List<ScheduleShift> shifts;

  const ScheduleDay(this.short, this.full, this.shifts);

  int get totalHours => shifts.fold(0, (sum, s) => sum + s.hours);
}

String _formatHour(int hour) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${hour12.toString().padLeft(2, '0')}:00 $period';
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class ScheduleController extends GetxController {
  // ----------------------------- month summary -----------------------------
  // TODO: replace these sample numbers with the real data from Firestore.
  final int daysGoal = 22;
  final int daysWorked = 18;
  final int daysAbsent = 2;
  final int absenceLimit = 8;
  final int onTimeRate = 92;

  int get percentWorked => (daysWorked / daysGoal * 100).round();
  int get daysRemaining => daysGoal - daysWorked;

  // -------------------------------- calendar -------------------------------

  /// The month that is shown on the calendar.
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  /// The day the user tapped.
  final Rx<DateTime> selectedDay = DateTime.now().obs;

  /// Given to us by table_calendar, so our arrows can change the month.
  PageController? _pageController;

  void onCalendarCreated(PageController controller) {
    _pageController = controller;
  }

  /// Called when the month changes (arrow buttons or swipe).
  void onPageChanged(DateTime day) {
    focusedDay.value = day;
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
  }

  void previousMonth() => _changeMonth(next: false);

  void nextMonth() => _changeMonth(next: true);

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

  /// SAMPLE DATA ONLY: replace with the real attendance records (Firestore).
  /// Future days have no record yet; Sundays are days off.
  DayStatus statusFor(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(day.year, day.month, day.day);

    if (date.isAfter(today)) return DayStatus.none;
    if (date.weekday == DateTime.sunday) return DayStatus.dayOff;
    if (date.day == 3) return DayStatus.absent;
    if (date.day == 12) return DayStatus.overtime;
    return DayStatus.worked;
  }

  // ---------------------------- tabs + schedule ----------------------------

  final List<String> tabs = const ['Workday', 'Holiday', 'Leave'];

  final RxInt tabIndex = 0.obs;

  void changeTab(int index) {
    tabIndex.value = index;
  }

  // TODO: replace with the real work schedule from Firestore.
  final List<ScheduleDay> schedule = const [
    ScheduleDay('Mon', 'Monday', [ScheduleShift(6, 12), ScheduleShift(13, 17)]),
    ScheduleDay('Tue', 'Tuesday', [
      ScheduleShift(6, 12),
      ScheduleShift(13, 17),
    ]),
    ScheduleDay('Wed', 'Wednesday', [
      ScheduleShift(6, 12),
      ScheduleShift(13, 17),
    ]),
  ];
}