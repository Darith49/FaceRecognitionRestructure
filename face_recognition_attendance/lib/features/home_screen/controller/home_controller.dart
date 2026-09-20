import 'dart:async';

import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:get/get.dart';

enum CheckState { notCheckedIn, checkedIn, checkedOut }

class HomeController extends GetxController {
  final LoginController _authController = Get.find<LoginController>();

  final Rx<DateTime> now = DateTime.now().obs;

  final Rx<CheckState> state = CheckState.notCheckedIn.obs;
  final Rx<DateTime?> checkInTime = Rx<DateTime?>(null);
  final Rx<DateTime?> checkOutTime = Rx<DateTime?>(null);

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

  String get checkInText =>
      checkInTime.value == null ? '-- : --' : _formatTime(checkInTime.value!);

  String get checkOutText =>
      checkOutTime.value == null ? '-- : --' : _formatTime(checkOutTime.value!);

  int get workedMinutes {
    final start = checkInTime.value;
    if (start == null) return 0;
    final end = checkOutTime.value ?? now.value;
    return end.difference(start).inMinutes;
  }

  double get goalProgress {
    if (checkInTime.value == null) return 0.0;
    final total = goalHours * 60;
    return (workedMinutes / total).clamp(0.0, 1.0);
  }

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

  String get totalHoursText {
    final start = checkInTime.value;
    if (start == null) return '0h';

    final end = checkOutTime.value ?? now.value;
    final minutes = end.difference(start).inMinutes;
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

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

  String _formatTime(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')} : ${d.minute.toString().padLeft(2, '0')} $period';
  }
}
