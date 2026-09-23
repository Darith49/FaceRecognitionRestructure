import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/permission_screen/model/permission_request.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class PermissionController extends GetxController {
  final ApiService _apiService = ApiService();

  /// Submitted requests (Pending + Approved).
  final RxList<PermissionRequest> requests = <PermissionRequest>[].obs;

  /// Sessions added in the "Request List" that are not submitted yet.
  final RxList<PermissionSession> draftSessions = <PermissionSession>[].obs;

  final RxBool isLoading = false.obs;

  String? _ownerUid;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
    fetchRequests();
  }

  void _watchSignedInUser() {
    if (!Get.isRegistered<LoginController>()) return;

    final auth = Get.find<LoginController>();
    _ownerUid = auth.currentuser.value?.uid;

    ever(auth.currentuser, (UserModel? user) {
      if (user?.uid == _ownerUid) return;
      _ownerUid = user?.uid;
      draftSessions.clear();
      requests.clear();
      fetchRequests();
    });
  }

  Future<void> fetchRequests() async {
    try {
      isLoading.value = true;
      final res = await _apiService.get('/requests/permissions/');
      if (res is List) {
        final list = res
            .map((e) => PermissionRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        requests.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching permission requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<PermissionRequest> requestsWithStatus(RequestStatus status) {
    return requests.where((request) => request.status == status).toList();
  }

  bool _slotTaken(DateTime date, String schedule, {String? excludeId}) {
    final day = DateText.ymd(date);
    return requests.any(
      (request) =>
          request.id != excludeId &&
          DateText.ymd(request.date) == day &&
          request.schedule == schedule,
    );
  }

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

  Future<int> submitDraftSessions() async {
    final count = draftSessions.length;
    for (final session in draftSessions) {
      final dateStr =
          "${session.date.year.toString().padLeft(4, '0')}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}";
      int sessionNum = 1;
      if (session.schedule.contains('13:') ||
          session.schedule.contains('14:') ||
          session.schedule.contains('15:') ||
          session.schedule.contains('16:') ||
          session.schedule.contains('17:')) {
        sessionNum = 2;
      }

      try {
        await _apiService.post('/requests/permissions/', body: {
          'date': dateStr,
          'session': sessionNum,
          'schedule_time': session.schedule,
          'reason': session.reason,
        });
      } catch (e) {
        debugPrint('Error creating permission request: $e');
      }
    }

    draftSessions.clear();
    await fetchRequests();
    return count;
  }

  Future<String?> updateRequest({
    required String id,
    required DateTime date,
    required String schedule,
    required String reason,
  }) async {
    final index = requests.indexWhere((request) => request.id == id);
    if (index == -1) return 'This request no longer exists.';

    if (_slotTaken(date, schedule, excludeId: id)) {
      return 'You already have a request for that date and schedule.';
    }

    final dateStr =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    int sessionNum = 1;
    if (schedule.contains('13:') ||
        schedule.contains('14:') ||
        schedule.contains('15:') ||
        schedule.contains('16:') ||
        schedule.contains('17:')) {
      sessionNum = 2;
    }

    try {
      await _apiService.patch('/requests/permissions/$id/', body: {
        'date': dateStr,
        'schedule_time': schedule,
        'session': sessionNum,
        'reason': reason,
      });
      await fetchRequests();
      return null;
    } catch (e) {
      return 'Failed to update request: $e';
    }
  }

  Future<void> cancelRequest(String id) async {
    try {
      await _apiService.delete('/requests/permissions/$id/');
    } catch (e) {
      debugPrint('Error deleting permission request: $e');
    }
    requests.removeWhere((request) => request.id == id);
    await fetchRequests();
  }
}
