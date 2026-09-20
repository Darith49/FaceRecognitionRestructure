import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/features/auth/controller/auth_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:get/get.dart';

/// TODO: set to false (and load from Firestore) when the backend is connected.
/// While it is true, two example requests are added so every screen can be tested.
const bool _useSampleData = true;

/// Keeps the permission requests for the Permission and Request Information screens.
/// For now the data lives in memory only (it is lost when the app closes).
class PermissionController extends GetxController {
  /// Submitted requests (Pending + Approved).
  final RxList<PermissionRequest> requests = <PermissionRequest>[].obs;

  /// Sessions added in the "Request List" that are not submitted yet.
  final RxList<PermissionSession> draftSessions = <PermissionSession>[].obs;

  String? _ownerUid;
  int _idCounter = 0;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
    _loadSampleRequests();
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
      draftSessions.clear();
      requests.clear();
      _loadSampleRequests();
    });
  }

  void _loadSampleRequests() {
    if (!_useSampleData) return;

    final user = _signedInUser;
    final name = user?.fullname ?? 'Full Name';
    final employeeId = user?.employeeId ?? '00000';

    requests.assignAll([
      PermissionRequest(
        id: 'sample-pending',
        fullName: name,
        employeeId: employeeId,
        date: DateTime(2026, 9, 21),
        schedule: '07:45-09:15',
        reason: 'Sick',
        status: RequestStatus.pending,
      ),
      PermissionRequest(
        id: 'sample-approved',
        fullName: name,
        employeeId: employeeId,
        date: DateTime(2026, 9, 7),
        schedule: '07:45-09:15',
        reason: 'Sick',
        status: RequestStatus.approved,
        authorizedAt: DateTime(2026, 9, 6, 7, 43, 11),
      ),
      PermissionRequest(
        id: 'sample-approved-2',
        fullName: name,
        employeeId: employeeId,
        date: DateTime(2026, 9, 28),
        schedule: '09:30-11:00',
        reason: 'Family event',
        status: RequestStatus.approved,
        authorizedAt: DateTime(2026, 9, 18, 9, 15, 30),
      ),
    ]);
  }

  List<PermissionRequest> requestsWithStatus(RequestStatus status) {
    return requests.where((request) => request.status == status).toList();
  }

  /// True when a submitted request already uses this date + schedule.
  /// [excludeId] lets a request ignore itself while it is being edited.
  bool _slotTaken(DateTime date, String schedule, {String? excludeId}) {
    final day = DateText.ymd(date);
    return requests.any(
      (request) =>
          request.id != excludeId &&
          DateText.ymd(request.date) == day &&
          request.schedule == schedule,
    );
  }

  /// Returns false when the same date + schedule is already in the list
  /// or already has a request.
  bool addSession(PermissionSession session) {
    final alreadyAdded =
        draftSessions.any((item) => item.isSameSlot(session)) ||
        _slotTaken(session.date, session.schedule);
    if (alreadyAdded) return false;

    draftSessions.add(session);
    return true;
  }

  void removeSessionAt(int index) {
    if (index < 0 || index >= draftSessions.length) return;
    draftSessions.removeAt(index);
  }

  void clearDrafts() => draftSessions.clear();

  /// Turns every session in the Request List into a Pending request.
  /// Returns how many requests were created.
  int submitDraftSessions() {
    final user = _signedInUser;
    final count = draftSessions.length;

    for (final session in draftSessions) {
      _idCounter++;
      requests.insert(
        0,
        PermissionRequest(
          id: '${DateTime.now().microsecondsSinceEpoch}-$_idCounter',
          fullName: user?.fullname ?? 'Unknown',
          employeeId: user?.employeeId ?? '-',
          date: session.date,
          schedule: session.schedule,
          reason: session.reason,
          status: RequestStatus.pending,
        ),
      );
    }

    draftSessions.clear();
    return count;
  }

  /// Saves the changes made on the detail page.
  /// An approved request that is changed goes back to Pending (needs approval again).
  /// Returns null when saved, or a message that explains why it could not be saved.
  String? updateRequest({
    required String id,
    required DateTime date,
    required String schedule,
    required String reason,
  }) {
    final index = requests.indexWhere((request) => request.id == id);
    if (index == -1) return 'This request no longer exists.';

    if (_slotTaken(date, schedule, excludeId: id)) {
      return 'You already have a request for that date and schedule.';
    }

    final current = requests[index];
    requests[index] = PermissionRequest(
      id: current.id,
      type: current.type,
      fullName: current.fullName,
      employeeId: current.employeeId,
      date: date,
      schedule: schedule,
      reason: reason,
      status: RequestStatus.pending,
    );
    return null;
  }

  void cancelRequest(String id) {
    requests.removeWhere((request) => request.id == id);
  }
}
