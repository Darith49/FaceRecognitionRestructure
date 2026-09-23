import 'package:face_recognition_attendance/core/services/face_recognition_engine.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CeoPanelController extends GetxController {
  final LocalDatabaseService _db = LocalDatabaseService();
  final FaceRecognitionEngine _faceEngine = FaceRecognitionEngine();

  final RxBool isLoading = false.obs;

  // Reactive state lists
  final RxList<Map<String, dynamic>> employees = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> branches = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> departments = <Map<String, dynamic>>[].obs;
  final RxList<Person> registeredPersons = <Person>[].obs;
  final RxList<Map<String, dynamic>> attendanceRecords = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pendingLeaves = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pendingOvertimes = <Map<String, dynamic>>[].obs;

  // Biometric thresholds
  final RxDouble identifyThreshold = 0.80.obs;
  final RxDouble livenessThreshold = 0.70.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      await _db.init();

      employees.assignAll(_db.getEmployees());
      branches.assignAll(_db.getBranches());
      departments.assignAll(_db.getDepartments());
      registeredPersons.assignAll(_db.getPersons());
      attendanceRecords.assignAll(_db.getAttendanceRecords());

      pendingLeaves.assignAll(
        _db.getLeaves().where((l) => (l['status'] ?? '').toString().toLowerCase() == 'pending'),
      );
      pendingOvertimes.assignAll(
        _db.getOvertimes().where((o) => (o['status'] ?? '').toString().toLowerCase() == 'pending'),
      );

      identifyThreshold.value = _faceEngine.defaultIdentifyThreshold;
      livenessThreshold.value = _faceEngine.defaultLivenessThreshold;
    } catch (e) {
      debugPrint('[CeoPanelController] Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Computed Metrics
  int get totalEmployees => employees.length;

  int get activeEmployees => employees.where((e) => (e['status'] ?? 'active') == 'active').length;

  int get presentToday {
    final now = DateTime.now();
    return attendanceRecords.where((a) {
      final dateStr = a['date'] ?? a['check_in_time'];
      if (dateStr == null) return false;
      final parsed = DateTime.tryParse(dateStr.toString());
      if (parsed == null) return false;
      return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
    }).length;
  }

  int get onLeaveToday {
    return _db.getLeaves().where((l) => (l['status'] ?? '') == 'approved').length;
  }

  int get biometricEnrolledCount => registeredPersons.length;

  double get biometricEnrollmentRate {
    if (totalEmployees == 0) return 0.0;
    return (biometricEnrolledCount / totalEmployees).clamp(0.0, 1.0);
  }

  int get totalBranches => branches.length;

  int get totalDepartments => departments.length;

  int get pendingApprovalsCount => pendingLeaves.length + pendingOvertimes.length;

  void updateSecurityThresholds({required double identify, required double liveness}) {
    identifyThreshold.value = identify;
    livenessThreshold.value = liveness;
    _faceEngine.initSettings(identifyThreshold: identify, livenessThreshold: liveness);

    Get.snackbar(
      'Security Thresholds Updated',
      'Match: ${(identify * 100).toStringAsFixed(0)}% • Liveness: ${(liveness * 100).toStringAsFixed(0)}%',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      icon: const Icon(Icons.shield_rounded, color: Color(0xFF34C759)),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> quickApproveLeave(int leaveId) async {
    _db.updateLeaveStatus(leaveId, 'approved');
    await fetchDashboardData();
    Get.snackbar(
      'Request Approved',
      'Leave request #$leaveId approved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Future<void> quickRejectLeave(int leaveId) async {
    _db.updateLeaveStatus(leaveId, 'rejected');
    await fetchDashboardData();
    Get.snackbar(
      'Request Rejected',
      'Leave request #$leaveId has been declined.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}
