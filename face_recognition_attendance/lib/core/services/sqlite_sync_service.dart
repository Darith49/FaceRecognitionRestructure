import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Client synchronization service connecting the Flutter app to the local
/// SQLite backend server (`http://127.0.0.1:8080/api`).
///
/// Ensures all face biometrics, registered templates, profile avatars, and attendance
/// logs are permanently preserved in the local disk SQLite database (`database/face_attendance.db`),
/// completely eliminating data loss caused by temporary browser profiles or project restarts.
class SqliteSyncService extends GetxService {
  static final SqliteSyncService _instance = SqliteSyncService._internal();
  factory SqliteSyncService() => _instance;
  SqliteSyncService._internal() {
    _registerDbHook();
  }

  void _registerDbHook() {
    LocalDatabaseService.onSyncHook = ({required type, required payload}) {
      if (type == 'profile_picture') {
        syncProfilePicture(
          email: payload['email']?.toString() ?? '',
          profilePictureBase64: payload['profile_picture']?.toString() ?? '',
        );
      } else if (type == 'face_registration') {
        syncFaceRegistration(
          email: payload['email']?.toString() ?? '',
          uid: payload['uid']?.toString() ?? '',
          employeeId: payload['employeeId']?.toString() ?? '',
          name: payload['name']?.toString() ?? '',
          templates: payload['templates'] as List<double>? ?? [],
          referenceImage: payload['referenceImage']?.toString() ?? '',
        );
      } else if (type == 'attendance') {
        syncAttendance(
          employeeId: payload['employeeId']?.toString() ?? '',
          employeeName: payload['employeeName']?.toString() ?? '',
          type: payload['type']?.toString() ?? 'check-in',
          time: payload['time']?.toString() ?? '',
          date: payload['date']?.toString() ?? '',
          checkType: payload['checkType']?.toString() ?? 'face',
          faceMatched: payload['faceMatched'] == true,
          confidence: (payload['confidence'] as num?)?.toDouble() ?? 0.95,
        );
      } else if (type == 'employee') {
        syncEmployee(payload);
      } else if (type == 'user_vault') {
        final email = payload['email']?.toString() ?? '';
        final vault = payload['vault'] is Map ? Map<String, dynamic>.from(payload['vault'] as Map) : <String, dynamic>{};
        if (email.isNotEmpty) {
          syncUserVault(email: email, vaultData: vault);
        }
      } else if (type == 'branch') {
        syncBranch(payload);
      } else if (type == 'department') {
        syncDepartment(payload);
      } else if (type == 'notification_read') {
        final id = payload['id'];
        if (id != null) syncNotificationRead(id);
      } else if (type == 'notifications_mark_all_read') {
        syncMarkAllNotificationsRead();
      } else if (type == 'notification') {
        syncNotification(payload);
      }
    };
  }

  final GetConnect _client = GetConnect(
    timeout: const Duration(milliseconds: 2500),
  );

  static const String defaultBaseUrl = 'http://127.0.0.1:8080/api';
  String baseUrl = defaultBaseUrl;

  final RxBool isBackendAvailable = false.obs;
  final RxBool hasSyncFailed = false.obs;
  bool _isSyncing = false;

  void _notifySyncError(String item, Object error) {
    hasSyncFailed.value = true;
    debugPrint('[SqliteSync] Failed to sync $item to SQLite: $error');
    if (Get.isSnackbarOpen != true) {
      Get.snackbar(
        'Offline Sync Notice'.tr,
        'Could not sync $item with server. Data saved on this device.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD97706),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _markSyncSuccess() {
    hasSyncFailed.value = false;
  }

  /// Initializes connection to the local SQLite backend.
  /// Tries 127.0.0.1 first with a fast timeout so app launch is instantaneous.
  /// If reachable, automatically pulls the complete SQLite state into the app.
  Future<bool> init({String? customUrl}) async {
    final candidateUrls = customUrl != null && customUrl.isNotEmpty
        ? [customUrl]
        : ['http://127.0.0.1:8080/api', 'http://localhost:8080/api'];

    for (final candidate in candidateUrls) {
      try {
        final res = await _client.get('$candidate/health').timeout(const Duration(milliseconds: 800));
        if (res.isOk && res.body is Map && res.body['status'] == 'healthy') {
          baseUrl = candidate;
          isBackendAvailable.value = true;
          _markSyncSuccess();
          debugPrint('[SqliteSync] Connected to local SQLite backend at $baseUrl');
          await bootstrapFromDatabase();
          return true;
        }
      } catch (e) {
        debugPrint('[SqliteSync] Attempt to connect to $candidate failed: $e');
      }
    }

    isBackendAvailable.value = false;
    hasSyncFailed.value = true;
    debugPrint('[SqliteSync] Local SQLite backend not reachable on candidates. Operating in offline storage mode.');
    return false;
  }

  /// Downloads full database snapshot and populates LocalDatabaseService
  Future<void> bootstrapFromDatabase() async {
    if (!isBackendAvailable.value || _isSyncing) return;
    _isSyncing = true;

    try {
      final res = await _client.get('$baseUrl/bootstrap');
      if (res.isOk && res.body is Map) {
        final data = Map<String, dynamic>.from(res.body as Map);
        LocalDatabaseService().hydrateFromSqlite(data);
        _markSyncSuccess();
        debugPrint('[SqliteSync] Successfully bootstrapped app from SQLite database.');
      }
    } catch (e) {
      _notifySyncError('database records', e);
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchronizes a newly enrolled face with the SQLite backend.
  Future<void> syncFaceRegistration({
    required String email,
    required String uid,
    required String employeeId,
    required String name,
    required dynamic templates,
    String? referenceImage,
  }) async {
    if (!isBackendAvailable.value) {
      await init();
    }
    if (!isBackendAvailable.value) {
      _notifySyncError('face registration', 'Server offline');
      return;
    }

    try {
      await _client.post('$baseUrl/face/register/', {
        'email': email,
        'id': uid,
        'firebase_uid': uid,
        'employee_id': employeeId,
        'name': name,
        'templates': templates,
        'reference_image': referenceImage,
      });
      _markSyncSuccess();
      debugPrint('[SqliteSync] Face registration synchronized with SQLite for $email');
    } catch (e) {
      _notifySyncError('face registration', e);
    }
  }

  /// Synchronizes an updated profile picture with the SQLite backend.
  Future<void> syncProfilePicture({
    required String email,
    String? uid,
    required String profilePictureBase64,
  }) async {
    if (!isBackendAvailable.value) {
      await init();
    }
    if (!isBackendAvailable.value) {
      _notifySyncError('profile picture', 'Server offline');
      return;
    }

    try {
      // 1. Try PATCH /api/employees/me/
      final res = await _client.patch('$baseUrl/employees/me/', {
        'email': email,
        'uid': uid,
        'profile_picture': profilePictureBase64,
      });

      // 2. Also POST to /profile/upload to guarantee persistence across all server endpoints
      await _client.post('$baseUrl/profile/upload', {
        'email': email,
        'uid': uid,
        'profile_picture': profilePictureBase64,
      });

      _markSyncSuccess();
      debugPrint('[SqliteSync] Profile picture successfully synchronized with SQLite backend for $email (status: ${res.statusCode})');
    } catch (e) {
      _notifySyncError('profile picture', e);
    }
  }

  /// Synchronizes attendance check-in or check-out with the SQLite backend.
  Future<void> syncAttendance({
    required String employeeId,
    required String employeeName,
    required String type, // 'check-in' or 'check-out'
    required String time,
    required String date,
    String? checkType,
    int? branchId,
    String? branchName,
    String? notes,
    bool faceMatched = true,
    double confidence = 0.95,
  }) async {
    if (!isBackendAvailable.value) {
      _notifySyncError('attendance record', 'Server offline');
      return;
    }

    try {
      final endpoint = type == 'check-in' ? '$baseUrl/attendance/check-in/' : '$baseUrl/attendance/check-out/';
      await _client.post(endpoint, {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'time': time,
        'date': date,
        'check_in_type': checkType,
        'check_out_type': checkType,
        'branch_id': branchId,
        'branch_name': branchName,
        'notes': notes,
        'face_matched': faceMatched,
        'confidence': confidence,
      });
      _markSyncSuccess();
      debugPrint('[SqliteSync] Attendance $type synchronized with SQLite for $employeeId');
    } catch (e) {
      _notifySyncError('attendance record', e);
    }
  }

  /// Synchronizes a newly submitted leave request.
  Future<void> syncLeave(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) {
      _notifySyncError('leave request', 'Server offline');
      return;
    }

    try {
      await _client.post('$baseUrl/requests/leave/', data);
      _markSyncSuccess();
      debugPrint('[SqliteSync] Leave request synchronized with SQLite');
    } catch (e) {
      _notifySyncError('leave request', e);
    }
  }

  /// Synchronizes a newly submitted overtime request.
  Future<void> syncOvertime(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) {
      _notifySyncError('overtime request', 'Server offline');
      return;
    }

    try {
      await _client.post('$baseUrl/requests/overtime/', data);
      _markSyncSuccess();
      debugPrint('[SqliteSync] Overtime request synchronized with SQLite');
    } catch (e) {
      _notifySyncError('overtime request', e);
    }
  }

  /// Synchronizes an employee account (registration / update) with SQLite
  Future<void> syncEmployee(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) {
      await init();
    }
    if (!isBackendAvailable.value) {
      _notifySyncError('employee record', 'Server offline');
      return;
    }

    try {
      final res = await _client.post('$baseUrl/employees/', data);
      _markSyncSuccess();
      debugPrint('[SqliteSync] Employee synchronized with SQLite backend for ${data['email']} (status: ${res.statusCode})');
    } catch (e) {
      _notifySyncError('employee record', e);
    }
  }

  /// Synchronizes user vault account credentials with SQLite
  Future<void> syncUserVault({
    required String email,
    required Map<String, dynamic> vaultData,
  }) async {
    if (!isBackendAvailable.value) {
      await init();
    }
    if (!isBackendAvailable.value) {
      _notifySyncError('vault data', 'Server offline');
      return;
    }

    try {
      final payload = Map<String, dynamic>.from(vaultData)..['email'] = email;
      final res = await _client.post('$baseUrl/user-vault/', payload);
      _markSyncSuccess();
      debugPrint('[SqliteSync] User vault synchronized with SQLite backend for $email (status: ${res.statusCode})');
    } catch (e) {
      _notifySyncError('vault data', e);
    }
  }

  /// Synchronizes a branch with SQLite
  Future<void> syncBranch(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) {
      _notifySyncError('branch', 'Server offline');
      return;
    }
    try {
      await _client.post('$baseUrl/branches/', data);
      _markSyncSuccess();
      debugPrint('[SqliteSync] Branch synchronized with SQLite backend');
    } catch (e) {
      _notifySyncError('branch', e);
    }
  }

  /// Synchronizes a department with SQLite
  Future<void> syncDepartment(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) {
      _notifySyncError('department', 'Server offline');
      return;
    }
    try {
      await _client.post('$baseUrl/departments/', data);
      _markSyncSuccess();
      debugPrint('[SqliteSync] Department synchronized with SQLite backend');
    } catch (e) {
      _notifySyncError('department', e);
    }
  }

  /// Synchronizes notification read state with SQLite
  Future<void> syncNotificationRead(dynamic id) async {
    if (!isBackendAvailable.value) return;
    try {
      await _client.post('$baseUrl/notifications/$id/read', {});
      _markSyncSuccess();
      debugPrint('[SqliteSync] Notification #$id mark-read synchronized with SQLite backend');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync notification #$id read status: $e');
    }
  }

  /// Synchronizes mark-all-read state with SQLite
  Future<void> syncMarkAllNotificationsRead() async {
    if (!isBackendAvailable.value) return;
    try {
      await _client.post('$baseUrl/notifications/mark-all-read', {});
      _markSyncSuccess();
      debugPrint('[SqliteSync] All notifications marked read in SQLite backend');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync mark-all-read to SQLite: $e');
    }
  }

  /// Synchronizes a new or updated notification with SQLite
  Future<void> syncNotification(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) return;
    try {
      await _client.post('$baseUrl/notifications', data);
      _markSyncSuccess();
      debugPrint('[SqliteSync] Notification synchronized with SQLite backend');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync notification to SQLite: $e');
    }
  }
}
