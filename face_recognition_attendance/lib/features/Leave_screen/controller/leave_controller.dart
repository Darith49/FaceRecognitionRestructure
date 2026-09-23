import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/features/Leave_screen/model/leave_request.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class LeaveController extends GetxController {
  final ApiService _apiService = ApiService();
  final RxList<LeaveRequest> requests = <LeaveRequest>[].obs;
  final RxBool isLoading = false.obs;

  String? _ownerUid;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
    fetchRequests();
  }

  UserModel? get _signedInUser => Get.isRegistered<LoginController>()
      ? Get.find<LoginController>().currentuser.value
      : null;

  void _watchSignedInUser() {
    if (!Get.isRegistered<LoginController>()) return;

    final auth = Get.find<LoginController>();
    _ownerUid = _signedInUser?.uid;

    ever(auth.currentuser, (UserModel? user) {
      if (user?.uid == _ownerUid) return;
      _ownerUid = user?.uid;
      requests.clear();
      fetchRequests();
    });
  }

  Future<void> fetchRequests() async {
    try {
      isLoading.value = true;
      final res = await _apiService.get('/requests/leave/');
      if (res is List) {
        final list = res
            .map((e) => LeaveRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        requests.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching leave requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<LeaveRequest> get pending =>
      requests.where((r) => r.status == LeaveStatus.pending).toList();

  List<LeaveRequest> get history =>
      requests.where((r) => r.status != LeaveStatus.pending).toList();

  int get totalApprovedDays =>
      requests.where((r) => r.status == LeaveStatus.approved).fold<int>(0, (sum, r) => sum + r.dayCount);

  Future<bool> addRequest({
    required DateTime fromDate,
    required DateTime toDate,
    int session = 1,
    String leaveMode = 'full_section',
    String? earlyLeaveTime,
    String? dayType,
    required String reason,
    DateTime? fromTime,
    DateTime? toTime,
    bool hasAttachment = false,
    String? attachmentName,
    dynamic attachmentBytes,
    int? attachmentSize,
    String? attachmentPath,
  }) async {
    try {
      final fromStr =
          "${fromDate.year.toString().padLeft(4, '0')}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
      final toStr =
          "${toDate.year.toString().padLeft(4, '0')}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";

      final resolvedDayType = dayType ??
          (session == 1
              ? 'Section 1 (Morning)'
              : (session == 2 ? 'Section 2 (Afternoon)' : 'Full Day'));

      final resolvedLeaveType = session == 1
          ? 'morning_section'
          : (session == 2 ? 'afternoon_section' : 'full_day');

      final Map<String, dynamic> body = {
        'session': session,
        'leave_mode': leaveMode,
        'early_leave_time': earlyLeaveTime,
        'leave_type': resolvedLeaveType,
        'day_type': resolvedDayType,
        'from_date': fromStr,
        'to_date': toStr,
        'reason': reason,
      };

      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        body['attachment_url'] = attachmentPath;
      }

      await _apiService.post('/requests/leave/', body: body);
      await fetchRequests();
      return true;
    } catch (e) {
      debugPrint('Error adding leave request: $e');
      return false;
    }
  }

  LeaveRequest? findById(String id) {
    final index = requests.indexWhere((r) => r.id == id);
    return index == -1 ? null : requests[index];
  }

  Future<bool> updateRequest(
    String id, {
    required DateTime fromDate,
    required DateTime toDate,
    int session = 1,
    String leaveMode = 'full_section',
    String? earlyLeaveTime,
    String? dayType,
    required String reason,
    DateTime? fromTime,
    DateTime? toTime,
    bool hasAttachment = false,
    String? attachmentName,
    dynamic attachmentBytes,
    int? attachmentSize,
    String? attachmentPath,
  }) async {
    final index = requests.indexWhere((r) => r.id == id);
    if (index == -1 || requests[index].status != LeaveStatus.pending) {
      return false;
    }

    try {
      final fromStr =
          "${fromDate.year.toString().padLeft(4, '0')}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
      final toStr =
          "${toDate.year.toString().padLeft(4, '0')}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";

      final Map<String, dynamic> body = {
        'session': session,
        'leave_mode': leaveMode,
        'early_leave_time': earlyLeaveTime,
        'day_type': dayType ?? (session == 1 ? 'Section 1 (Morning)' : (session == 2 ? 'Section 2 (Afternoon)' : 'Full Day')),
        'from_date': fromStr,
        'to_date': toStr,
        'reason': reason,
      };
      if (attachmentPath != null) {
        body['attachment_url'] = attachmentPath;
      }

      await _apiService.patch('/requests/leave/$id/', body: body);
      await fetchRequests();
      return true;
    } catch (e) {
      debugPrint('Error updating leave request: $e');
      return false;
    }
  }

  Future<void> cancelRequest(String id) async {
    try {
      await _apiService.delete('/requests/leave/$id/');
    } catch (e) {
      debugPrint('Error deleting leave request: $e');
    }
    requests.removeWhere((r) => r.id == id && r.status == LeaveStatus.pending);
    await fetchRequests();
  }
}
