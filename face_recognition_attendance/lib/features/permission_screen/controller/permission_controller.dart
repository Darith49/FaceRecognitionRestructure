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
    ]);
  }

  List<PermissionRequest> requestsWithStatus(RequestStatus status) {
    return requests.where((request) => request.status == status).toList();
  }

  /// Returns false when the same date + schedule is already in the list.
  bool addSession(PermissionSession session) {
    final alreadyAdded = draftSessions.any((item) => item.isSameSlot(session));
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

  void cancelRequest(String id) {
    requests.removeWhere((request) => request.id == id);
  }
}
