import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/utils/report_period.dart';
import 'package:face_recognition_attendance/features/Overtime_screen/model/overtime_request.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Keeps the overtime requests for the Overtime feature.
/// For now the data lives in memory only (it is lost when the app closes).
class OvertimeController extends GetxController {
  final ApiService _apiService = ApiService();
  final RxList<OvertimeRequest> requests = <OvertimeRequest>[].obs;
  final RxBool isLoading = false.obs;

  String? _ownerUid;

  @override
  void onInit() {
    super.onInit();
    _watchSignedInUser();
    fetchRequests();
  }

  /// If another user logs in on the same phone, do not show the old user's requests.
  void _watchSignedInUser() {
    if (!Get.isRegistered<LoginController>()) return;

    final auth = Get.find<LoginController>();
    _ownerUid = auth.currentuser.value?.uid;

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
      final res = await _apiService.get('/requests/overtime/');
      if (res is List) {
        final list = res
            .map((e) => OvertimeRequest.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        requests.assignAll(list);
      }
    } catch (e) {
      debugPrint('Error fetching overtime requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Adds a new overtime request as Pending.
  Future<bool> addRequest({
    required DateTime date,
    required DateTime fromTime,
    required DateTime toTime,
    required String reason,
    bool hasAttachment = false,
    String? attachmentName,
    dynamic attachmentBytes,
    int? attachmentSize,
    String? attachmentPath,
  }) async {
    try {
      final dateStr =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final startStr =
          "${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}:00";
      final endStr =
          "${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}:00";

      final body = {
        'date': dateStr,
        'start_time': startStr,
        'end_time': endStr,
        'reason': reason,
      };

      await _apiService.post('/requests/overtime/', body: body);
      await fetchRequests();
      return true;
    } catch (e) {
      debugPrint('Error adding overtime request: $e');
      return false;
    }
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
    String? attachmentName,
    dynamic attachmentBytes,
    int? attachmentSize,
    String? attachmentPath,
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
      attachmentName: attachmentName ?? old.attachmentName,
      attachmentBytes: attachmentBytes ?? old.attachmentBytes,
      attachmentSize: attachmentSize ?? old.attachmentSize,
      attachmentPath: attachmentPath ?? old.attachmentPath,
    );
    return true;
  }

  /// Only Pending requests can be cancelled.
  Future<void> cancelRequest(String id) async {
    try {
      await _apiService.delete('/requests/overtime/$id/');
    } catch (e) {
      debugPrint('Error deleting overtime request: $e');
    }
    requests.removeWhere((r) => r.id == id && r.status == OvertimeStatus.pending);
    await fetchRequests();
  }
}
