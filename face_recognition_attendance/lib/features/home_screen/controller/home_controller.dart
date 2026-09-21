import 'dart:async';

import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:get/get.dart';

enum CheckState {
  // 2-Session states
  session1NotCheckedIn, // Morning: awaiting Session 1 Check In
  session1CheckedIn,    // Morning: Session 1 active, awaiting Check Out
  session2NotCheckedIn, // Afternoon: Session 1 done, awaiting Session 2 Check In
  session2CheckedIn,    // Afternoon: Session 2 active, awaiting Check Out
  completed,            // Both sessions finished for the day

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

  // Standard schedules
  static const String session1SchedIn = '08:00';
  static const String session1SchedOut = '12:00';
  static const String session2SchedIn = '13:00';
  static const String session2SchedOut = '17:00';

  final double goalHours = 8.0;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  UserModel? get currentUser => _authController.currentuser.value;

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
      state.value == CheckState.completed || state.value == CheckState.checkedOut;

  String get session1StatusText {
    if (session1CheckOut.value != null) return 'Completed';
    if (session1CheckIn.value != null) return 'In Progress';
    return 'Upcoming';
  }

  String get session2StatusText {
    if (session2CheckOut.value != null) return 'Completed';
    if (session2CheckIn.value != null) return 'In Progress';
    if (session1CheckOut.value != null) return 'Ready';
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
    final end = session1CheckOut.value ??
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
    final end = session2CheckOut.value ??
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

  void onMainButtonPressed() {
    switch (state.value) {
      case CheckState.session1NotCheckedIn:
      case CheckState.notCheckedIn:
        session1CheckIn.value = DateTime.now();
        state.value = CheckState.session1CheckedIn;
        break;
      case CheckState.session1CheckedIn:
      case CheckState.checkedIn:
        session1CheckOut.value = DateTime.now();
        state.value = CheckState.session2NotCheckedIn;
        break;
      case CheckState.session2NotCheckedIn:
        session2CheckIn.value = DateTime.now();
        state.value = CheckState.session2CheckedIn;
        break;
      case CheckState.session2CheckedIn:
        session2CheckOut.value = DateTime.now();
        state.value = CheckState.completed;
        break;
      case CheckState.completed:
      case CheckState.checkedOut:
        // Both sessions already completed
        break;
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
}
