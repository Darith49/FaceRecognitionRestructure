import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:flutter/foundation.dart';
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
  SqliteSyncService._internal();

  final GetConnect _client = GetConnect(
    timeout: const Duration(milliseconds: 2500),
  );

  static const String defaultBaseUrl = 'http://127.0.0.1:8080/api';
  String baseUrl = defaultBaseUrl;

  final RxBool isBackendAvailable = false.obs;
  bool _isSyncing = false;

  /// Initializes connection to the local SQLite backend.
  /// Tries both localhost and 127.0.0.1 to eliminate Private Network Access (PNA) and CORS issues on Web.
  /// If reachable, automatically pulls the complete SQLite state into the app.
  Future<bool> init({String? customUrl}) async {
    final candidateUrls = customUrl != null && customUrl.isNotEmpty
        ? [customUrl]
        : ['http://localhost:8080/api', 'http://127.0.0.1:8080/api'];

    for (final candidate in candidateUrls) {
      try {
        final res = await _client.get('$candidate/health').timeout(const Duration(milliseconds: 3000));
        if (res.isOk && res.body is Map && res.body['status'] == 'healthy') {
          baseUrl = candidate;
          isBackendAvailable.value = true;
          debugPrint('[SqliteSync] Connected to local SQLite backend at $baseUrl');
          await bootstrapFromDatabase();
          return true;
        }
      } catch (e) {
        debugPrint('[SqliteSync] Attempt to connect to $candidate failed: $e');
      }
    }

    isBackendAvailable.value = false;
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
        debugPrint('[SqliteSync] Successfully bootstrapped app from SQLite database.');
      }
    } catch (e) {
      debugPrint('[SqliteSync] Error bootstrapping from SQLite: $e');
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
    if (!isBackendAvailable.value) return;

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
      debugPrint('[SqliteSync] Face registration synchronized with SQLite for $email');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync face registration to SQLite: $e');
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
      debugPrint('[SqliteSync] Cannot sync profile picture: Backend server not reachable.');
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

      debugPrint('[SqliteSync] Profile picture successfully synchronized with SQLite backend for $email (status: ${res.statusCode})');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync profile picture to SQLite: $e');
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
    if (!isBackendAvailable.value) return;

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
      debugPrint('[SqliteSync] Attendance $type synchronized with SQLite for $employeeId');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync attendance to SQLite: $e');
    }
  }

  /// Synchronizes a newly submitted leave request.
  Future<void> syncLeave(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) return;

    try {
      await _client.post('$baseUrl/requests/leave/', data);
      debugPrint('[SqliteSync] Leave request synchronized with SQLite');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync leave to SQLite: $e');
    }
  }

  /// Synchronizes a newly submitted overtime request.
  Future<void> syncOvertime(Map<String, dynamic> data) async {
    if (!isBackendAvailable.value) return;

    try {
      await _client.post('$baseUrl/requests/overtime/', data);
      debugPrint('[SqliteSync] Overtime request synchronized with SQLite');
    } catch (e) {
      debugPrint('[SqliteSync] Failed to sync overtime to SQLite: $e');
    }
  }
}
