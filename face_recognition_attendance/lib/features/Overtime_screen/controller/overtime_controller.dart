import 'package:face_recognition_attendance/core/utils/report_period.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:get/get.dart';

/// Keeps the overtime requests for the Overtime feature.
/// For now the data lives in memory only (it is lost when the app closes).
class OvertimeController extends GetxController {
  final RxList<OvertimeRequest> requests = <OvertimeRequest>[].obs;

  String? _ownerUid;
  int _idCounter = 0;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
  }

  UserModel? get _signedInUser => Get.isRegistered<LoginController>()
      ? Get.find<LoginController>().currentuser.value
      : null;

  /// If another user logs in on the same phone, do not show the old user's requests.
  void _watchSignedInUser() {
    if (!Get.isRegistered<LoginController>()) return;

    final auth = Get.find<LoginController>();
    _ownerUid = auth.currentuser.value?.uid;

    ever(auth.currentuser, (UserModel? user) {
      if (user?.uid == _ownerUid) return;
      _ownerUid = user?.uid;
      requests.clear();
    });
  }

  /// Adds a new overtime request as Pending.
  void addRequest({
    required DateTime date,
    required DateTime fromTime,
    required DateTime toTime,
    required String reason,
    bool hasAttachment = false,
  }) {
    final user = _signedInUser;
    _idCounter++;

    requests.insert(
      0,
      OvertimeRequest(
        id: '${DateTime.now().microsecondsSinceEpoch}-$_idCounter',
        fullName: user?.fullname ?? 'Unknown',
        employeeId: user?.employeeId ?? '-',
        date: date,
        fromTime: fromTime,
        toTime: toTime,
        reason: reason,
        status: OvertimeStatus.pending,
        hasAttachment: hasAttachment,
      ),
    );
  }

  /// The requests whose date is inside [period], oldest first (for the PDF report).
  List<OvertimeRequest> requestsIn(ReportPeriod period) {
    final list = requests.where((r) => period.contains(r.date)).toList();
    list.sort((a, b) => a.fromTime.compareTo(b.fromTime));
    return list;
  }

  OvertimeRequest? findById(String id) {
    final index = requests.indexWhere((r) => r.id == id);
    return index == -1 ? null : requests[index];
  }

  /// Only allowed while the request is still Pending.
  /// Returns false if it was not changed (missing, or already Approved).
  bool updateRequest(
    String id, {
    required DateTime date,
    required DateTime fromTime,
    required DateTime toTime,
    required String reason,
    bool hasAttachment = false,
  }) {
    final index = requests.indexWhere((r) => r.id == id);
    if (index == -1 || requests[index].status != OvertimeStatus.pending) {
      return false;
    }

    final old = requests[index];
    requests[index] = OvertimeRequest(
      id: old.id,
      fullName: old.fullName,
      employeeId: old.employeeId,
      date: date,
      fromTime: fromTime,
      toTime: toTime,
      reason: reason,
      status: old.status,
      hasAttachment: hasAttachment,
    );
    return true;
  }

  /// Only Pending requests can be cancelled.
  void cancelRequest(String id) {
    requests.removeWhere((r) => r.id == id && r.status == OvertimeStatus.pending);
  }
}
