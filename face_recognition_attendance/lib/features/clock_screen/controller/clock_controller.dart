import 'dart:async';

import 'package:get/get.dart';

enum ClockState { notCheckedIn, checkedIn, checkedOut }

class ClockController extends GetxController {
  /// Current time, updated every second so the clock on screen is live.
  final Rx<DateTime> now = DateTime.now().obs;

  final Rx<ClockState> state = ClockState.notCheckedIn.obs;
  final Rx<DateTime?> checkInTime = Rx<DateTime?>(null);
  final Rx<DateTime?> checkOutTime = Rx<DateTime?>(null);

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

  /// Text on the big round button.
  String get buttonLabel {
    switch (state.value) {
      case ClockState.notCheckedIn:
        return 'Check In';
      case ClockState.checkedIn:
        return 'Check Out';
      case ClockState.checkedOut:
        return 'Done';
    }
  }

  /// Example: "6h" or "4h 30m". While the user is checked in it keeps counting.
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
      case ClockState.notCheckedIn:
        // TODO: run face recognition here, then save the check-in to Firestore.
        checkInTime.value = DateTime.now();
        state.value = ClockState.checkedIn;
        break;
      case ClockState.checkedIn:
        // TODO: save the check-out to Firestore.
        checkOutTime.value = DateTime.now();
        state.value = ClockState.checkedOut;
        break;
      case ClockState.checkedOut:
        break;
    }
  }
}
