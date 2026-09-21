import 'package:face_recognition_attendance/features/home_screen/controller/home_controller.dart';
import 'package:get/get.dart';

typedef ClockState = CheckState;

class ClockController extends GetxController {
  HomeController get _home => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController(), permanent: true);

  Rx<DateTime> get now => _home.now;
  Rx<CheckState> get state => _home.state;

  // Session 1 & 2 reactive timestamps
  Rx<DateTime?> get session1CheckIn => _home.session1CheckIn;
  Rx<DateTime?> get session1CheckOut => _home.session1CheckOut;
  Rx<DateTime?> get session2CheckIn => _home.session2CheckIn;
  Rx<DateTime?> get session2CheckOut => _home.session2CheckOut;

  // Formatted texts
  String get session1CheckInText => _home.session1CheckInText;
  String get session1CheckOutText => _home.session1CheckOutText;
  String get session2CheckInText => _home.session2CheckInText;
  String get session2CheckOutText => _home.session2CheckOutText;

  // Status texts
  String get session1StatusText => _home.session1StatusText;
  String get session2StatusText => _home.session2StatusText;
  bool get isSession1Active => _home.isSession1Active;
  bool get isSession2Active => _home.isSession2Active;
  bool get isSession1Done => _home.isSession1Done;
  bool get isSession2Done => _home.isSession2Done;
  bool get isAllDone => _home.isAllDone;

  // Backward compatibility
  Rx<DateTime?> get checkInTime => _home.checkInTime;
  Rx<DateTime?> get checkOutTime => _home.checkOutTime;
  String get checkInText => _home.checkInText;
  String get checkOutText => _home.checkOutText;

  // Metrics
  double get goalHours => _home.goalHours;
  double get goalProgress => _home.goalProgress;
  String get remainingGoalText => _home.remainingGoalText;
  String get totalHoursText => _home.totalHoursText;

  // Button & UI texts
  String get buttonLabel => _home.buttonLabel;
  String get buttonSubtext => _home.buttonSubtext;
  String get nextScheduleText => _home.nextScheduleText;
  String get userName => _home.userName;
  String get greeting => _home.greeting;

  void onMainButtonPressed() => _home.onMainButtonPressed();
  void resetAttendance() => _home.resetAttendance();
}
