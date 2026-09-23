import 'package:face_recognition_attendance/core/services/api_service.dart';
import 'package:face_recognition_attendance/core/widgets/request_ui.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestScreenController extends GetxController {
  final ApiService _apiService = ApiService();

  final RxBool isLoading = false.obs;
  final RxBool canApprove = false.obs;

  final RxList<Map<String, dynamic>> incomingLeaves = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> incomingOvertimes = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> incomingPermissions = <Map<String, dynamic>>[].obs;
  final RxInt totalPending = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _checkRole();
    fetchIncoming();
  }

  void _checkRole() {
    if (Get.isRegistered<LoginController>()) {
      final user = Get.find<LoginController>().currentuser.value;
      if (user != null) {
        canApprove.value = user.role == UserRole.ceo ||
            user.role == UserRole.manager ||
            user.role == UserRole.leader;
      }
    }
  }

  Future<void> fetchIncoming() async {
    _checkRole();
    if (!canApprove.value) return;

    try {
      isLoading.value = true;
      final res = await _apiService.get('/requests/incoming/');
      if (res is Map) {
        totalPending.value = (res['total_pending'] as num?)?.toInt() ?? 0;
        if (res['leaves'] is List) {
          incomingLeaves.assignAll(
            (res['leaves'] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
        if (res['overtimes'] is List) {
          incomingOvertimes.assignAll(
            (res['overtimes'] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
        if (res['permissions'] is List) {
          incomingPermissions.assignAll(
            (res['permissions'] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching incoming requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reviewLeave(int id, bool approve, BuildContext context) async {
    try {
      final res = await _apiService.post(
        '/requests/leave/$id/review/',
        body: {'status': approve ? 'approved' : 'rejected'},
      );
      if (res is Map) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Leave request has been ${approve ? "approved" : "rejected"}.',
        );
        await fetchIncoming();
      }
    } catch (e) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'Failed to review leave request: $e',
      );
    }
  }

  Future<void> reviewOvertime(int id, bool approve, BuildContext context) async {
    try {
      final res = await _apiService.post(
        '/requests/overtime/$id/review/',
        body: {'status': approve ? 'approved' : 'rejected'},
      );
      if (res is Map) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Overtime request has been ${approve ? "approved" : "rejected"}.',
        );
        await fetchIncoming();
      }
    } catch (e) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'Failed to review overtime request: $e',
      );
    }
  }

  Future<void> reviewPermission(int id, bool approve, BuildContext context) async {
    try {
      final res = await _apiService.post(
        '/requests/permissions/$id/review/',
        body: {'status': approve ? 'approved' : 'rejected'},
      );
      if (res is Map) {
        RequestSnack.show(
          ScaffoldMessenger.of(context),
          'Permission request has been ${approve ? "approved" : "rejected"}.',
        );
        await fetchIncoming();
      }
    } catch (e) {
      RequestSnack.show(
        ScaffoldMessenger.of(context),
        'Failed to review permission request: $e',
      );
    }
  }
}
