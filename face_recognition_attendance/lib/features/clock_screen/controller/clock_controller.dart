import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:get/get.dart';

typedef ClockState = CheckState;

class ClockController extends GetxController {
  HomeController get _home => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController(), permanent: true);

  Rx<DateTime> get now => _home.now;
  Rx<CheckState> get state => _home.state;
  Rx<DateTime?> get checkInTime => _home.checkInTime;
  Rx<DateTime?> get checkOutTime => _home.checkOutTime;

  double get goalHours => _home.goalHours;
  double get goalProgress => _home.goalProgress;
  String get remainingGoalText => _home.remainingGoalText;
  String get buttonLabel => _home.buttonLabel;
  String get totalHoursText => _home.totalHoursText;
  String get checkInText => _home.checkInText;
  String get checkOutText => _home.checkOutText;

  void onMainButtonPressed() => _home.onMainButtonPressed();
}
