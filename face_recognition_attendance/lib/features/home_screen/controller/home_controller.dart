import 'dart:async';

import 'package:face_recognition_attendance/config/routes/app_routes.dart';
import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/branch/controller/branch_controller.dart';
import 'package:face_recognition_attendance/features/department/controller/department_controller.dart';
import 'package:face_recognition_attendance/features/employee/controller/employee_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum CheckState {
  // 2-Session states
  session1NotCheckedIn, // Morning: awaiting Session 1 Check In
  session1CheckedIn, // Morning: Session 1 active, awaiting Check Out
  session2NotCheckedIn, // Afternoon: Session 1 done, awaiting Session 2 Check In
  session2CheckedIn, // Afternoon: Session 2 active, awaiting Check Out
  completed, // Both sessions finished for the day
  // Backward compatibility aliases
  notCheckedIn,
  checkedIn,
  checkedOut,
}

class HomeController extends GetxController {
  final LoginController _authController = Get.find<LoginController>();

  final Rx<DateTime> now = DateTime.now().obs;

  // State
  final Rx<CheckState> state = CheckState.session1NotCheckedIn.obs;

  // Session 1 (Morning)
  final Rx<DateTime?> session1CheckIn = Rx<DateTime?>(null);
  final Rx<DateTime?> session1CheckOut = Rx<DateTime?>(null);

  // Session 2 (Afternoon)
  final Rx<DateTime?> session2CheckIn = Rx<DateTime?>(null);
  final Rx<DateTime?> session2CheckOut = Rx<DateTime?>(null);

  // Dynamic schedules
  final RxString session1SchedIn = '07:00'.obs;
  final RxString session1SchedOut = '11:00'.obs;
  final RxString session2SchedIn = '13:00'.obs;
  final RxString session2SchedOut = '17:00'.obs;
  final RxString session1ApiStatus = ''.obs;
  final RxString session2ApiStatus = ''.obs;
  final RxBool isWorkDayToday = true.obs;

  final double goalHours = 8.0;

  final ApiService _apiService = ApiService();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    now.value = DateText.nowCambodia();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateText.nowCambodia();
    });
    if (isCeo) {
      refreshAdminOverview();
    } else {
      _authController.checkFaceStatus();
      fetchTodayAttendanceStatus();
    }
  }

  Future<void> fetchTodayAttendanceStatus() async {
    if (isCeo) return;
    try {
      final res = await _apiService.get('/attendance/status/');
      if (res is Map) {
        // 1. Read schedule
        if (res['schedule'] is Map) {
          final sched = res['schedule'] as Map;
          final s1Start = sched['section1_start']?.toString();
          final s1End = sched['section1_end']?.toString();
          final s2Start = sched['section2_start']?.toString();
          final s2End = sched['section2_end']?.toString();

          if (s1Start != null && s1Start.length >= 5) {
            session1SchedIn.value = s1Start.substring(0, 5);
          }
          if (s1End != null && s1End.length >= 5) {
            session1SchedOut.value = s1End.substring(0, 5);
          }
          if (s2Start != null && s2Start.length >= 5) {
            session2SchedIn.value = s2Start.substring(0, 5);
          }
          if (s2End != null && s2End.length >= 5) {
            session2SchedOut.value = s2End.substring(0, 5);
          }
          if (sched['is_work_day_today'] is bool) {
            isWorkDayToday.value = sched['is_work_day_today'] as bool;
          }
        }

        // 2. Read Session 1
        if (res['session1'] is Map) {
          final s1 = res['session1'] as Map;
          session1ApiStatus.value = s1['status']?.toString() ?? '';
          if (s1['record'] is Map) {
            final rec1 = s1['record'] as Map;
            final inTime = rec1['check_in_time']?.toString();
            final outTime = rec1['check_out_time']?.toString();
            if (inTime != null && inTime.isNotEmpty) {
              session1CheckIn.value = DateText.parseCambodia(inTime);
            }
            if (outTime != null && outTime.isNotEmpty) {
              session1CheckOut.value = DateText.parseCambodia(outTime);
            }
          }
        }

        // 3. Read Session 2
        if (res['session2'] is Map) {
          final s2 = res['session2'] as Map;
          session2ApiStatus.value = s2['status']?.toString() ?? '';
          if (s2['record'] is Map) {
            final rec2 = s2['record'] as Map;
            final inTime = rec2['check_in_time']?.toString();
            final outTime = rec2['check_out_time']?.toString();
            if (inTime != null && inTime.isNotEmpty) {
              session2CheckIn.value = DateText.parseCambodia(inTime);
            }
            if (outTime != null && outTime.isNotEmpty) {
              session2CheckOut.value = DateText.parseCambodia(outTime);
            }
          }
        }

        // 4. Update overall check state
        if (session2CheckOut.value != null) {
          state.value = CheckState.completed;
        } else if (session2CheckIn.value != null) {
          state.value = CheckState.session2CheckedIn;
        } else if (session1CheckOut.value != null ||
            session1ApiStatus.value == 'absent') {
          if (session2ApiStatus.value == 'absent') {
            state.value = CheckState.completed;
          } else {
            state.value = CheckState.session2NotCheckedIn;
          }
        } else if (session1CheckIn.value != null) {
          state.value = CheckState.session1CheckedIn;
        } else {
          state.value = CheckState.session1NotCheckedIn;
        }
      }
    } catch (_) {
      // Graceful fallback
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  UserModel? get currentUser => _authController.currentuser.value;
  bool get isCeo => currentUser?.role == UserRole.ceo;
  bool get hasFaceRegistered => _authController.hasFaceRegistered.value;

  BranchController get branchController => Get.isRegistered<BranchController>()
      ? Get.find<BranchController>()
      : Get.put(BranchController());

  DepartmentController get departmentController =>
      Get.isRegistered<DepartmentController>()
      ? Get.find<DepartmentController>()
      : Get.put(DepartmentController());

  EmployeeController get employeeController =>
      Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());

  Future<void> refreshAdminOverview() async {
    if (isCeo) {
      await Future.wait([
        branchController.fetchBranches(),
        departmentController.fetchDepartments(),
        employeeController.fetchEmployees(),
      ]);
    }
  }

  String get greeting {
    final hour = now.value.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get userName => currentUser?.fullname ?? 'User';

  // ─── Status & Active Getters ────────────────────────────────────────────────

  bool get isSession1Active =>
      state.value == CheckState.session1NotCheckedIn ||
      state.value == CheckState.session1CheckedIn ||
      state.value == CheckState.notCheckedIn;

  bool get isSession2Active =>
      state.value == CheckState.session2NotCheckedIn ||
      state.value == CheckState.session2CheckedIn;

  bool get isSession1Done => session1CheckOut.value != null;
  bool get isSession2Done => session2CheckOut.value != null;
  bool get isAllDone =>
      state.value == CheckState.completed ||
      state.value == CheckState.checkedOut;

  String get session1StatusText {
    if (session1CheckOut.value != null) return 'Completed';
    if (session1CheckIn.value != null) return 'In Progress';
    if (session1ApiStatus.value == 'absent') return 'Absent';
    if (session1ApiStatus.value == 'open') return 'Open';
    return 'Upcoming';
  }

  String get session2StatusText {
    if (session2CheckOut.value != null) return 'Completed';
    if (session2CheckIn.value != null) return 'In Progress';
    if (session2ApiStatus.value == 'absent') return 'Absent';
    if (session2ApiStatus.value == 'open') return 'Open';
    if (session1CheckOut.value != null || session1ApiStatus.value == 'absent') {
      return 'Ready';
    }
    return 'Upcoming';
  }

  // ─── Time Text Getters ──────────────────────────────────────────────────────

  String get session1CheckInText => session1CheckIn.value == null
      ? '-- : --'
      : _formatTime(session1CheckIn.value!);

  String get session1CheckOutText => session1CheckOut.value == null
      ? '-- : --'
      : _formatTime(session1CheckOut.value!);

  String get session2CheckInText => session2CheckIn.value == null
      ? '-- : --'
      : _formatTime(session2CheckIn.value!);

  String get session2CheckOutText => session2CheckOut.value == null
      ? '-- : --'
      : _formatTime(session2CheckOut.value!);

  // Backward compatibility getters
  Rx<DateTime?> get checkInTime =>
      (state.value == CheckState.session1NotCheckedIn ||
          state.value == CheckState.session1CheckedIn ||
          state.value == CheckState.notCheckedIn)
      ? session1CheckIn
      : (session2CheckIn.value != null ? session2CheckIn : session1CheckIn);

  Rx<DateTime?> get checkOutTime =>
      session2CheckOut.value != null ? session2CheckOut : session1CheckOut;

  String get checkInText =>
      (state.value == CheckState.session1NotCheckedIn ||
          state.value == CheckState.session1CheckedIn ||
          state.value == CheckState.notCheckedIn)
      ? session1CheckInText
      : session2CheckInText;

  String get checkOutText =>
      (state.value == CheckState.session1NotCheckedIn ||
          state.value == CheckState.session1CheckedIn ||
          state.value == CheckState.notCheckedIn)
      ? session1CheckOutText
      : session2CheckOutText;

  // ─── Hours & Progress Calculation ──────────────────────────────────────────

  int get session1WorkedMinutes {
    final start = session1CheckIn.value;
    if (start == null) return 0;
    final end =
        session1CheckOut.value ??
        (state.value == CheckState.session1CheckedIn ||
                state.value == CheckState.checkedIn
            ? now.value
            : start);
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  int get session2WorkedMinutes {
    final start = session2CheckIn.value;
    if (start == null) return 0;
    final end =
        session2CheckOut.value ??
        (state.value == CheckState.session2CheckedIn ? now.value : start);
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  int get workedMinutes => session1WorkedMinutes + session2WorkedMinutes;

  double get goalProgress {
    final total = goalHours * 60;
    return (workedMinutes / total).clamp(0.0, 1.0);
  }

  String get remainingGoalText {
    final remaining = (goalHours * 60).toInt() - workedMinutes;
    if (remaining <= 0) return 'Done!';
    final h = remaining ~/ 60;
    final m = remaining % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String get totalHoursText {
    final minutes = workedMinutes;
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  // ─── Button Label & Subtext ─────────────────────────────────────────────────

  String get buttonLabel {
    if (!isCeo && !hasFaceRegistered) {
      return 'Register Face';
    }
    switch (state.value) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
        return 'Check In';
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
        return 'Check Out';
      case CheckState.session2NotCheckedIn:
        return 'Check In';
      case CheckState.session2CheckedIn:
        return 'Check Out';
      case CheckState.completed:
      case CheckState.checkedOut:
        return 'Completed';
    }
  }

  String get buttonSubtext {
    if (!isCeo && !hasFaceRegistered) {
      return 'Enroll your face first';
    }
    switch (state.value) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
        return 'Session 1 • Face or Tap ID';
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
        return 'Session 1 • Tap to check out';
      case CheckState.session2NotCheckedIn:
        return 'Session 2 • Face or Tap ID';
      case CheckState.session2CheckedIn:
        return 'Session 2 • Tap to finish shift';
      case CheckState.completed:
      case CheckState.checkedOut:
        return 'All Sessions Recorded';
    }
  }

  String get nextScheduleText {
    switch (state.value) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
        return 'Next schedule: Today, $session1SchedIn AM (Session 1)';
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
        return 'Scheduled check out: $session1SchedOut PM (Session 1)';
      case CheckState.session2NotCheckedIn:
        return 'Next schedule: Today, $session2SchedIn PM (Session 2)';
      case CheckState.session2CheckedIn:
        return 'Scheduled check out: $session2SchedOut PM (Session 2)';
      case CheckState.completed:
      case CheckState.checkedOut:
        return 'Next schedule: Tomorrow, $session1SchedIn AM (Session 1)';
    }
  }

  // ─── State Progression ──────────────────────────────────────────────────────

  Future<void> onMainButtonPressed() async {
    if (isCeo) return; // CEO does not check in

    // Account without registered face -> directly route to face enrollment
    if (!hasFaceRegistered) {
      final res = await Get.toNamed(
        AppRoutes.faceCapture,
        arguments: {'action': 'register'},
      );
      if (res != null) {
        await _authController.checkFaceStatus();
        await fetchTodayAttendanceStatus();
      }
      return;
    }

    String? action;
    int sessionNum = 1;
    switch (state.value) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
        action = 'check_in';
        sessionNum = 1;
        break;
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
        action = 'check_out';
        sessionNum = 1;
        break;
      case CheckState.session2NotCheckedIn:
        action = 'check_in';
        sessionNum = 2;
        break;
      case CheckState.session2CheckedIn:
        action = 'check_out';
        sessionNum = 2;
        break;
      case CheckState.completed:
      case CheckState.checkedOut:
        return;
    }

    if (action == 'check_out') {
      final scheduledOutStr = sessionNum == 1 ? session1SchedOut.value : session2SchedOut.value;
      final parts = scheduledOutStr.split(':');
      if (parts.isNotEmpty) {
        final targetHour = int.tryParse(parts[0]) ?? (sessionNum == 1 ? 11 : 17);
        final targetMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final current = DateText.nowCambodia();
        final schedTime = DateTime(current.year, current.month, current.day, targetHour, targetMin);
        if (current.isBefore(schedTime)) {
          final proceed = await _showEarlyCheckoutDialog(sessionNum, scheduledOutStr);
          if (proceed != true) return;
        }
      }
    }

    final result = await Get.toNamed(
      AppRoutes.faceCapture,
      arguments: {'action': action, 'session': sessionNum},
    );
    if (result != null) {
      if (action == 'check_in') {
        DateTime time = DateText.nowCambodia();
        if (result is Map && result['check_in_time'] != null) {
          time = DateText.parseCambodia(result['check_in_time'].toString());
        }
        if (state.value == CheckState.session1NotCheckedIn ||
            state.value == CheckState.notCheckedIn) {
          session1CheckIn.value = time;
          state.value = CheckState.session1CheckedIn;
        } else {
          session2CheckIn.value = time;
          state.value = CheckState.session2CheckedIn;
        }
      } else if (action == 'check_out') {
        DateTime time = DateText.nowCambodia();
        if (result is Map && result['check_out_time'] != null) {
          time = DateText.parseCambodia(result['check_out_time'].toString());
        }
        if (state.value == CheckState.session1CheckedIn ||
            state.value == CheckState.checkedIn) {
          session1CheckOut.value = time;
          state.value = CheckState.session2NotCheckedIn;
        } else {
          session2CheckOut.value = time;
          state.value = CheckState.completed;
        }
      }
      await fetchTodayAttendanceStatus();
    }
  }

  void resetAttendance() {
    session1CheckIn.value = null;
    session1CheckOut.value = null;
    session2CheckIn.value = null;
    session2CheckOut.value = null;
    state.value = CheckState.session1NotCheckedIn;
  }

  String _formatTime(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')} : ${d.minute.toString().padLeft(2, '0')} $period';
  }

  /// Shows an alert when the employee attempts to check out before their section end time.
  /// Offers an immediate button to submit a Leave Request or continue checkout.
  Future<bool?> _showEarlyCheckoutDialog(int sessionNum, String scheduledOutStr) {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Early Check-Out Alert',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your scheduled check-out time for Section $sessionNum is $scheduledOutStr.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              'Checking out early will be recorded on your attendance. If you have personal reasons or permission, please submit a Leave Request.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.back(result: false);
                    Get.toNamed(AppRoutes.leave, arguments: {
                      'tab': 0,
                      'session': sessionNum,
                      'leaveMode': 'early_leave',
                      'earlyLeaveTime': TimeOfDay.now(),
                      'reason': 'Early departure from Section $sessionNum',
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: const BorderSide(color: Color(0xFF1565C0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Request Leave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Check Out Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
