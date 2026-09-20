import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/leave_screen/model/leave_request.dart';
import 'package:get/get.dart';

/// Keeps the leave requests for the Leave feature.
/// For now the data lives in memory only (it is lost when the app closes).
class LeaveController extends GetxController {
  final RxList<LeaveRequest> requests = <LeaveRequest>[].obs;

  String? _ownerUid;
  int _idCounter = 0;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
  }

  UserModel? get _signedInUser => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>().currentuser.value
      : null;

  /// If another user logs in on the same phone, do not show the old user's requests.
  void _watchSignedInUser() {
    if (!Get.isRegistered<AuthController>()) return;

    final auth = Get.find<AuthController>();
    _ownerUid = auth.currentuser.value?.uid;

    ever(auth.currentuser, (UserModel? user) {
      if (user?.uid == _ownerUid) return;
      _ownerUid = user?.uid;
      requests.clear();
    });
  }

  List<LeaveRequest> get pending =>
      requests.where((r) => r.status == LeaveStatus.pending).toList();

  List<LeaveRequest> get history =>
      requests.where((r) => r.status == LeaveStatus.approved).toList();

  /// Total approved leave days, shown inside the circle at the top of the Leave page.
  int get totalApprovedDays =>
      history.fold<int>(0, (sum, r) => sum + r.dayCount);

  /// Adds a new leave request as Pending.
  void addRequest({
    required DateTime fromDate,
    required DateTime toDate,
    required String dayType,
    required String reason,
    DateTime? fromTime,
    DateTime? toTime,
    bool hasAttachment = false,
  }) {
    final user = _signedInUser;
    _idCounter++;

    requests.insert(
      0,
      LeaveRequest(
        id: '${DateTime.now().microsecondsSinceEpoch}-$_idCounter',
        fullName: user?.fullname ?? 'Unknown',
        employeeId: user?.employeeId ?? '-',
        fromDate: fromDate,
        toDate: toDate,
        dayType: dayType,
        reason: reason,
        status: LeaveStatus.pending,
        fromTime: fromTime,
        toTime: toTime,
        hasAttachment: hasAttachment,
      ),
    );
  }

  LeaveRequest? findById(String id) {
    final index = requests.indexWhere((r) => r.id == id);
    return index == -1 ? null : requests[index];
  }

  /// Only allowed while the request is still Pending.
  /// Returns false if it was not changed (missing, or already Approved).
  bool updateRequest(
    String id, {
    required DateTime fromDate,
    required DateTime toDate,
    required String dayType,
    required String reason,
    DateTime? fromTime,
    DateTime? toTime,
    bool hasAttachment = false,
  }) {
    final index = requests.indexWhere((r) => r.id == id);
    if (index == -1 || requests[index].status != LeaveStatus.pending) {
      return false;
    }

    final old = requests[index];
    requests[index] = LeaveRequest(
      id: old.id,
      fullName: old.fullName,
      employeeId: old.employeeId,
      fromDate: fromDate,
      toDate: toDate,
      dayType: dayType,
      reason: reason,
      status: old.status,
      fromTime: fromTime,
      toTime: toTime,
      hasAttachment: hasAttachment,
    );
    return true;
  }

  /// Only Pending requests can be cancelled.
  void cancelRequest(String id) {
    requests.removeWhere((r) => r.id == id && r.status == LeaveStatus.pending);
  }
}
