import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum DayStatus { worked, absent, dayOff, overtime, leave, workday, none }

class ScheduleShift {
  final int startHour;
  final int endHour;
  final String range;

  const ScheduleShift(this.startHour, this.endHour, {this.range = ''});

  int get hours => (endHour - startHour).clamp(0, 24);
}

class ScheduleDay {
  final String short;
  final String full;
  final List<ScheduleShift> shifts;
  final int totalHours;

  const ScheduleDay(this.short, this.full, this.shifts, {this.totalHours = 0});
}

class HolidayItem {
  final String short;
  final String full;
  final String reason;

  const HolidayItem({
    required this.short,
    required this.full,
    required this.reason,
  });
}

class LeaveItem {
  final int id;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;

  const LeaveItem({
    required this.id,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class ScheduleController extends GetxController {
  final ApiService _apiService = ApiService();

  // ----------------------------- month summary -----------------------------
  final RxInt daysGoal = 0.obs;
  final RxInt daysWorked = 0.obs;
  final RxInt daysAbsent = 0.obs;
  final RxInt daysLeave = 0.obs;
  final RxInt absenceLimit = 8.obs;
  final RxInt onTimeRate = 100.obs;
  final RxInt daysRemaining = 0.obs;
  final RxString monthName = ''.obs;
  final RxBool isLoading = false.obs;

  int get percentWorked =>
      daysGoal.value > 0 ? ((daysWorked.value / daysGoal.value) * 100).round() : 0;

  // -------------------------------- calendar -------------------------------

  /// The month that is shown on the calendar.
  final Rx<DateTime> focusedDay = DateTime.now().obs;

  /// The day the user tapped.
  final Rx<DateTime> selectedDay = DateTime.now().obs;

  /// Map of ISO date strings "YYYY-MM-DD" -> calendar day data
  final RxMap<String, Map<String, dynamic>> calendarDays =
      <String, Map<String, dynamic>>{}.obs;

  /// Work schedule days (Workday tab)
  final RxList<ScheduleDay> schedule = <ScheduleDay>[].obs;

  /// Non-working days / holidays (Holiday tab)
  final RxList<HolidayItem> holidays = <HolidayItem>[].obs;

  /// Approved leaves (Leave tab)
  final RxList<LeaveItem> leaves = <LeaveItem>[].obs;

  /// Given to us by table_calendar, so our arrows can change the month.
  PageController? _pageController;

  @override
  void onInit() {
    super.onInit();
    fetchMonthlySummary(focusedDay.value.year, focusedDay.value.month);
  }

  void onCalendarCreated(PageController controller) {
    _pageController = controller;
  }

  /// Called when the month changes (arrow buttons or swipe).
  void onPageChanged(DateTime day) {
    if (day.month != focusedDay.value.month || day.year != focusedDay.value.year) {
      focusedDay.value = day;
      fetchMonthlySummary(day.year, day.month);
    } else {
      focusedDay.value = day;
    }
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
    if (controller != null && controller.hasClients) {
      if (next) {
        controller.nextPage(duration: duration, curve: Curves.easeOut);
      } else {
        controller.previousPage(duration: duration, curve: Curves.easeOut);
      }
    } else {
      final current = focusedDay.value;
      final newDay = next
          ? DateTime(current.year, current.month + 1, 1)
          : DateTime(current.year, current.month - 1, 1);
      onPageChanged(newDay);
    }
  }

  /// Fetches monthly attendance summary and schedule from Django backend
  Future<void> fetchMonthlySummary(int year, int month) async {
    try {
      isLoading.value = true;
      final res = await _apiService.get(
        '/attendance/monthly-summary/',
        queryParams: {'year': year, 'month': month},
      );

      if (res is Map<String, dynamic>) {
        daysGoal.value = (res['days_goal'] as num?)?.toInt() ?? 0;
        daysWorked.value = (res['days_worked'] as num?)?.toInt() ?? 0;
        daysAbsent.value = (res['days_absent'] as num?)?.toInt() ?? 0;
        daysLeave.value = (res['days_leave'] as num?)?.toInt() ?? 0;
        absenceLimit.value = (res['absence_limit'] as num?)?.toInt() ?? 8;
        onTimeRate.value = (res['on_time_rate'] as num?)?.toInt() ?? 100;
        daysRemaining.value = (res['days_remaining'] as num?)?.toInt() ?? 0;
        monthName.value = res['month_name']?.toString() ?? '';

        // Parse calendar days
        if (res['calendar_days'] is Map) {
          final rawCal = res['calendar_days'] as Map;
          final Map<String, Map<String, dynamic>> parsedCal = {};
          rawCal.forEach((k, v) {
            if (v is Map) {
              parsedCal[k.toString()] = Map<String, dynamic>.from(v);
            }
          });
          calendarDays.value = parsedCal;
        }

        // Parse work schedule days
        if (res['schedule'] is List) {
          final List<ScheduleDay> list = [];
          for (final item in res['schedule']) {
            if (item is Map) {
              final shiftsList = <ScheduleShift>[];
              if (item['shifts'] is List) {
                for (final s in item['shifts']) {
                  shiftsList.add(ScheduleShift(
                    (s['startHour'] as num?)?.toInt() ?? 8,
                    (s['endHour'] as num?)?.toInt() ?? 17,
                    range: s['range']?.toString() ?? '',
                  ));
                }
              }
              list.add(ScheduleDay(
                item['short']?.toString() ?? '',
                item['full']?.toString() ?? '',
                shiftsList,
                totalHours: (item['totalHours'] as num?)?.toInt() ?? 0,
              ));
            }
          }
          schedule.value = list;
        }

        // Parse holidays
        if (res['holidays'] is List) {
          final List<HolidayItem> hList = [];
          for (final item in res['holidays']) {
            if (item is Map) {
              hList.add(HolidayItem(
                short: item['short']?.toString() ?? '',
                full: item['full']?.toString() ?? '',
                reason: item['reason']?.toString() ?? 'Scheduled Day Off',
              ));
            }
          }
          holidays.value = hList;
        }

        // Parse approved leaves
        if (res['leaves'] is List) {
          final List<LeaveItem> lList = [];
          for (final item in res['leaves']) {
            if (item is Map) {
              lList.add(LeaveItem(
                id: (item['id'] as num?)?.toInt() ?? 0,
                leaveType: item['leave_type']?.toString() ?? 'Leave',
                fromDate: item['from_date']?.toString() ?? '',
                toDate: item['to_date']?.toString() ?? '',
                reason: item['reason']?.toString() ?? '',
                status: item['status']?.toString() ?? 'approved',
              ));
            }
          }
          leaves.value = lList;
        }
      }
    } catch (e) {
      debugPrint('Error fetching monthly summary: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns real status for the given day from backend monthly summary
  DayStatus statusFor(DateTime day) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final data = calendarDays[key];
    if (data == null) {
      if (day.weekday == DateTime.sunday) return DayStatus.dayOff;
      return DayStatus.none;
    }

    final s = data['status']?.toString() ?? '';
    switch (s) {
      case 'worked':
        return DayStatus.worked;
      case 'absent':
        return DayStatus.absent;
      case 'dayOff':
        return DayStatus.dayOff;
      case 'overtime':
        return DayStatus.overtime;
      case 'leave':
        return DayStatus.leave;
      case 'workday':
        return DayStatus.workday;
      default:
        return DayStatus.none;
    }
  }

  // ---------------------------- tabs + schedule ----------------------------

  final List<String> tabs = const ['Workday', 'Holiday', 'Leave'];

  final RxInt tabIndex = 0.obs;

  void changeTab(int index) {
    tabIndex.value = index;
  }
}