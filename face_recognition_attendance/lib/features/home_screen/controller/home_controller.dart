import 'dart:async';

import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:get/get.dart';

enum CheckState { notCheckedIn, checkedIn, checkedOut }

class HomeController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  /// Current time, updated every second so the clock on screen is live.
  final Rx<DateTime> now = DateTime.now().obs;

  final Rx<CheckState> state = CheckState.notCheckedIn.obs;
  final Rx<DateTime?> checkInTime = Rx<DateTime?>(null);
  final Rx<DateTime?> checkOutTime = Rx<DateTime?>(null);

  /// Target working hours per day.
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

  /// The currently logged-in user (may be null if not yet loaded).
  UserModel? get currentUser => _authController.currentuser.value;

  /// Returns a greeting based on the time of day.
  String get greeting {
    final hour = now.value.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// The user's display name pulled from Firestore.
  String get userName => currentUser?.fullname ?? 'User';

  /// Text on the big round button.
  String get buttonLabel {
    switch (state.value) {
      case CheckState.notCheckedIn:
        return 'Check In';
      case CheckState.checkedIn:
        return 'Check Out';
      case CheckState.checkedOut:
        return 'Done';
    }
  }

  /// Formatted check-in time or placeholder.
  String get checkInText =>
      checkInTime.value == null ? '-- : --' : _formatTime(checkInTime.value!);

  /// Formatted check-out time or placeholder.
  String get checkOutText =>
      checkOutTime.value == null ? '-- : --' : _formatTime(checkOutTime.value!);

  /// Total minutes worked since check-in (live, updates every second).
  int get workedMinutes {
    final start = checkInTime.value;
    if (start == null) return 0;
    final end = checkOutTime.value ?? now.value;
    return end.difference(start).inMinutes;
  }

  /// Progress toward the daily goal as a 0.0 → 1.0 ratio, clamped.
  double get goalProgress {
    if (checkInTime.value == null) return 0.0;
    final total = goalHours * 60;
    return (workedMinutes / total).clamp(0.0, 1.0);
  }

  /// Human-readable remaining time, e.g. "7h 15m left" or "Goal reached!".
  String get remainingGoalText {
    if (checkInTime.value == null) return '${goalHours.toInt()}h';
    final remaining = (goalHours * 60).toInt() - workedMinutes;
    if (remaining <= 0) return 'Done!';
    final h = remaining ~/ 60;
    final m = remaining % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Total hours worked as a string like "6h" or "4h 30m".
  String get totalHoursText {
    final start = checkInTime.value;
    if (start == null) return '0h';

    final end = checkOutTime.value ?? now.value;
    final minutes = end.difference(start).inMinutes;
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  /// Handle the main check-in / check-out button tap.
  void onMainButtonPressed() {
    switch (state.value) {
      case CheckState.notCheckedIn:
        checkInTime.value = DateTime.now();
        state.value = CheckState.checkedIn;
        break;
      case CheckState.checkedIn:
        checkOutTime.value = DateTime.now();
        state.value = CheckState.checkedOut;
        break;
      case CheckState.checkedOut:
        break;
    }
  }

  /// Format a DateTime as "08 : 00 AM".
  String _formatTime(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')} : ${d.minute.toString().padLeft(2, '0')} $period';
  }
}
