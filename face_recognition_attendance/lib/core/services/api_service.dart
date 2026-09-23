import 'dart:async';
import 'dart:typed_data';
import 'package:face_recognition_attendance/core/services/face_recognition_engine.dart';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

/// Standalone local API Service router.
/// Decoupled from Django and remote network servers,
/// routing all requests directly to the LocalDatabaseService and FaceRecognitionEngine.
class ApiService {
  final LocalDatabaseService _db = LocalDatabaseService();
  final LocalAuthService _auth = LocalAuthService();
  final FaceRecognitionEngine _faceEngine = FaceRecognitionEngine();

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    await _db.init();
    _faceEngine.initSettings();
    final clean = endpoint.toLowerCase();

    // 1. Departments
    if (clean.contains('/departments/')) {
      final list = _db.getDepartments();
      return {'results': list, 'count': list.length};
    }

    // 2. Branches
    if (clean.contains('/branches/')) {
      final list = _db.getBranches();
      return {'results': list, 'count': list.length};
    }

    // 3. Employees / My Team
    if (clean.contains('/employees/my-team/')) {
      final user = _auth.getCurrentUser();
      final emp = user != null
          ? (_db.getEmployeeByUid(user.uid) ?? _db.getEmployeeByEmail(user.email))
          : null;
      final role = (emp?['role'] ?? 'employee').toString().toLowerCase();
      final allEmployees = _db.getEmployees();
      return {
        'role': role,
        'user': emp,
        'pinned': allEmployees.take(2).toList(),
        'tabs': [
          {
            'key': 'all',
            'title': 'All Members',
            'badge': allEmployees.length.toString(),
            'is_branch_list': false,
            'items': allEmployees,
          }
        ],
      };
    }
    if (clean.contains('/employees/')) {
      final list = _db.getEmployees();
      return {'results': list, 'count': list.length};
    }

    // 4. Face Enrollment Status
    if (clean.contains('/face/status/')) {
      final user = _auth.getCurrentUser();
      if (user == null) return {'registered': false};
      final emp = _db.getEmployeeByUid(user.uid) ?? _db.getEmployeeByEmail(user.email);
      final enrolled = _db.getPersons().any(
        (p) => p.id == user.uid || (emp != null && p.employeeId == emp['employee_id']) || p.employeeId == user.uid,
      );
      return {'registered': enrolled};
    }

    // 5. Attendance
    if (clean.contains('/attendance/status/')) {
      final user = _auth.getCurrentUser();
      return _db.getAttendanceStatus(user?.uid ?? 1);
    }
    if (clean.contains('/attendance/department-summary/')) {
      return {
        'total_employees': _db.getEmployees().length,
        'present': _db.getAttendanceRecords().where((r) => r['check_out_time'] == null).length,
        'late': 0,
        'absent': 0,
        'on_leave': _db.getLeaves().where((l) => l['status'] == 'approved').length,
      };
    }
    if (clean.contains('/attendance/monthly-summary/')) {
      final user = _auth.getCurrentUser();
      final year = int.tryParse(queryParams?['year']?.toString() ?? '') ?? DateTime.now().year;
      final month = int.tryParse(queryParams?['month']?.toString() ?? '') ?? DateTime.now().month;
      return _db.getMonthlySummary(year: year, month: month, employeeId: user?.uid);
    }
    if (clean.contains('/attendance/')) {
      final list = _db.getAttendanceRecords();
      return {'results': list, 'count': list.length};
    }

    // 6. Requests (Leave, Overtime, Suggestions, Incoming)
    if (clean.contains('/requests/leave/')) {
      final list = _db.getLeaves();
      return {'results': list, 'count': list.length};
    }
    if (clean.contains('/requests/overtime/')) {
      final list = _db.getOvertimes();
      return {'results': list, 'count': list.length};
    }
    if (clean.contains('/requests/suggestions/')) {
      final list = _db.getSuggestions();
      return {'results': list, 'count': list.length};
    }
    if (clean.contains('/requests/incoming/')) {
      final leaves = _db.getLeaves().where((l) => l['status'] == 'pending').toList();
      final overtimes = _db.getOvertimes().where((o) => o['status'] == 'pending').toList();
      return {
        'leaves': leaves,
        'overtimes': overtimes,
        'count': leaves.length + overtimes.length,
      };
    }
    if (clean.contains('/requests/permissions/')) {
      return {'results': [], 'count': 0};
    }

    // 7. Notifications
    if (clean.contains('/notifications/')) {
      final list = _db.getNotifications();
      return {'results': list, 'count': list.length};
    }

    return {'results': []};
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    await _db.init();
    final clean = endpoint.toLowerCase();
    final data = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};

    // Employees
    if (clean.contains('/employees/') && clean.contains('/resend-invitation/')) {
      return {'message': 'Invitation resent successfully.'};
    }
    if (clean.contains('/employees/')) {
      return _db.saveEmployee(data);
    }

    // Departments
    if (clean.contains('/departments/')) {
      return _db.saveDepartment(data);
    }

    // Branches
    if (clean.contains('/branches/')) {
      return _db.saveBranch(data);
    }

    // Requests
    if (clean.contains('/requests/leave/')) {
      return _db.addLeave(data);
    }
    if (clean.contains('/requests/overtime/')) {
      return _db.addOvertime(data);
    }
    if (clean.contains('/requests/suggestions/')) {
      return _db.addSuggestion(data);
    }
    if (clean.contains('/requests/incoming/')) {
      return {'status': 'processed'};
    }
    if (clean.contains('/requests/permissions/')) {
      return {'id': DateTime.now().millisecondsSinceEpoch, ...data};
    }

    // Notifications
    if (clean.contains('/notifications/mark-all-read/')) {
      _db.markAllNotificationsRead();
      return {'status': 'ok'};
    }
    if (clean.contains('/notifications/') && clean.contains('/read/')) {
      final parts = endpoint.split('/');
      final id = parts.length > 2 ? parts[2] : null;
      if (id != null) _db.markNotificationRead(id);
      return {'status': 'ok'};
    }

    return data;
  }

  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    await _db.init();
    final clean = endpoint.toLowerCase();
    final data = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();

    if (clean.contains('/departments/')) {
      final id = parts.length >= 2 ? parts[1] : 1;
      return _db.updateDepartment(id, data);
    }

    if (clean.contains('/branches/')) {
      final id = parts.length >= 2 ? parts[1] : 1;
      return _db.updateBranch(id, data);
    }

    if (clean.contains('/employees/')) {
      final id = parts.length >= 2 ? parts[1] : 1;
      return _db.updateEmployee(id, data);
    }

    if (clean.contains('/requests/leave/')) {
      final id = parts.length >= 3 ? parts[2] : 1;
      return _db.updateLeave(id, data);
    }

    if (clean.contains('/requests/suggestions/') && clean.contains('/read/')) {
      final id = parts.length >= 3 ? parts[2] : 1;
      _db.markSuggestionRead(id);
      return {'status': 'ok'};
    }

    return data;
  }

  Future<dynamic> delete(String endpoint) async {
    await _db.init();
    final clean = endpoint.toLowerCase();
    final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();

    if (clean.contains('/departments/')) {
      final id = parts.length >= 2 ? parts[1] : null;
      if (id != null) _db.deleteDepartment(id);
      return {'status': 'deleted'};
    }

    if (clean.contains('/branches/')) {
      final id = parts.length >= 2 ? parts[1] : null;
      if (id != null) _db.deleteBranch(id);
      return {'status': 'deleted'};
    }

    if (clean.contains('/employees/')) {
      final id = parts.length >= 2 ? parts[1] : null;
      if (id != null) _db.deleteEmployee(id);
      return {'status': 'deleted'};
    }

    if (clean.contains('/requests/leave/')) {
      final id = parts.length >= 3 ? parts[2] : null;
      if (id != null) _db.deleteLeave(id);
      return {'status': 'deleted'};
    }

    if (clean.contains('/requests/overtime/')) {
      final id = parts.length >= 3 ? parts[2] : null;
      if (id != null) _db.deleteOvertime(id);
      return {'status': 'deleted'};
    }

    return {'status': 'deleted'};
  }

  /// Processes multipart biometric face requests (Register, Check In, Check Out)
  /// completely on-device using FaceRecognitionEngine with strict security verification.
  Future<dynamic> postMultipart(
    String endpoint, {
    required Uint8List bytes,
    required String filename,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    await _db.init();
    _faceEngine.initSettings();
    final clean = endpoint.toLowerCase();
    final user = _auth.getCurrentUser();

    // 1. Face Registration
    if (clean.contains('/face/register/')) {
      if (user == null) {
        throw ApiException(statusCode: 401, message: 'Please log in before enrolling your face.');
      }

      final emp = _db.getEmployeeByUid(user.uid) ?? _db.getEmployeeByEmail(user.email) ?? _db.getEmployees().first;
      final personId = user.uid;
      final personName = emp['fullname'] ?? user.displayName ?? 'User';
      final employeeId = emp['employee_id'] ?? personId;

      List<double> template;
      try {
        template = await _faceEngine.extractFaceTemplate(bytes);
      } catch (e) {
        throw ApiException(
          statusCode: 400,
          message: 'Registration failed: $e',
        );
      }

      final liveness = await _faceEngine.calculateLiveness(bytes);
      if (liveness < 0.50) {
        throw ApiException(
          statusCode: 400,
          message: 'Registration quality too low (${(liveness * 100).toStringAsFixed(0)}%). Please face the camera in bright lighting without glare.',
        );
      }

      final person = Person(
        id: personId,
        name: personName,
        employeeId: employeeId,
        faceJpg: bytes,
        templates: template,
        enrolledAt: DateTime.now(),
      );

      _db.savePerson(person);

      return {
        'status': 'success',
        'message': 'Face biometric profile registered successfully for $personName.',
        'person_id': personId,
        'similarity': 1.0,
        'liveness': liveness,
      };
    }

    // 2. Attendance Check-In via Biometrics
    if (clean.contains('/attendance/check-in/')) {
      if (user == null) {
        throw ApiException(statusCode: 401, message: 'Authentication required. Please log in before scanning attendance.');
      }

      final emp = _db.getEmployeeByUid(user.uid) ?? _db.getEmployeeByEmail(user.email) ?? _db.getEmployees().first;
      final empId = emp['id'] ?? 1;
      final empName = emp['fullname'] ?? 'Employee';
      final empCode = emp['employee_id']?.toString() ?? '';

      // SECURITY CHECK 1: Ensure user has enrolled their face
      final enrolledPersons = _db.getPersons();
      Person? enrolledPerson;
      for (final p in enrolledPersons) {
        if (p.id == user.uid || (empCode.isNotEmpty && p.employeeId == empCode) || p.employeeId == user.uid) {
          enrolledPerson = p;
          break;
        }
      }

      if (enrolledPerson == null) {
        throw ApiException(
          statusCode: 400,
          message: 'No enrolled face profile found for $empName. Please go to Profile -> Register Face to enroll your face first.',
        );
      }

      // SECURITY CHECK 2: Strict 1:1 Identity Verification (Prevents anyone else from scanning in)
      final verification = await _faceEngine.verifyUserFace(bytes, enrolledPerson);

      if (!verification.isVerified) {
        // REJECT! DO NOT CHECK IN!
        throw ApiException(
          statusCode: 403,
          message: verification.reason,
          details: {
            'similarity': verification.similarity,
            'liveness': verification.liveness,
            'required_similarity': _faceEngine.defaultIdentifyThreshold,
            'required_liveness': _faceEngine.defaultLivenessThreshold,
          },
        );
      }

      // SECURITY CHECK 3: Only record check-in after strict biometric verification passes
      final lat = fields?['latitude'] != null ? double.tryParse(fields!['latitude']!) : 11.5564;
      final lon = fields?['longitude'] != null ? double.tryParse(fields!['longitude']!) : 104.9282;
      final session = fields?['session'] != null ? int.tryParse(fields!['session']!) : 1;

      final record = _db.recordCheckIn(
        employeeId: empId,
        employeeName: empName,
        latitude: lat,
        longitude: lon,
        session: session,
        similarity: verification.similarity,
      );

      return {
        'status': 'success',
        'message': 'Identity verified! Check-in recorded for $empName.',
        'employee_name': empName,
        'check_in_time': record['check_in_time'],
        'similarity': verification.similarity,
        'liveness': verification.liveness,
      };
    }

    // 3. Attendance Check-Out via Biometrics
    if (clean.contains('/attendance/check-out/')) {
      if (user == null) {
        throw ApiException(statusCode: 401, message: 'Authentication required. Please log in before scanning attendance.');
      }

      final emp = _db.getEmployeeByUid(user.uid) ?? _db.getEmployeeByEmail(user.email) ?? _db.getEmployees().first;
      final empId = emp['id'] ?? 1;
      final empName = emp['fullname'] ?? 'Employee';
      final empCode = emp['employee_id']?.toString() ?? '';

      // SECURITY CHECK 1: Ensure user has enrolled their face
      final enrolledPersons = _db.getPersons();
      Person? enrolledPerson;
      for (final p in enrolledPersons) {
        if (p.id == user.uid || (empCode.isNotEmpty && p.employeeId == empCode) || p.employeeId == user.uid) {
          enrolledPerson = p;
          break;
        }
      }

      if (enrolledPerson == null) {
        throw ApiException(
          statusCode: 400,
          message: 'No enrolled face profile found for $empName. Please go to Profile -> Register Face to enroll your face first.',
        );
      }

      // SECURITY CHECK 2: Strict 1:1 Identity Verification (Prevents anyone else from scanning in)
      final verification = await _faceEngine.verifyUserFace(bytes, enrolledPerson);

      if (!verification.isVerified) {
        // REJECT! DO NOT CHECK OUT!
        throw ApiException(
          statusCode: 403,
          message: verification.reason,
          details: {
            'similarity': verification.similarity,
            'liveness': verification.liveness,
            'required_similarity': _faceEngine.defaultIdentifyThreshold,
            'required_liveness': _faceEngine.defaultLivenessThreshold,
          },
        );
      }

      // SECURITY CHECK 3: Only record check-out after strict biometric verification passes
      final lat = fields?['latitude'] != null ? double.tryParse(fields!['latitude']!) : 11.5564;
      final lon = fields?['longitude'] != null ? double.tryParse(fields!['longitude']!) : 104.9282;
      final session = fields?['session'] != null ? int.tryParse(fields!['session']!) : 1;

      final record = _db.recordCheckOut(
        employeeId: empId,
        employeeName: empName,
        latitude: lat,
        longitude: lon,
        session: session,
        similarity: verification.similarity,
      );

      return {
        'status': 'success',
        'message': 'Identity verified! Check-out recorded for $empName.',
        'employee_name': empName,
        'check_out_time': record['check_out_time'],
        'similarity': verification.similarity,
        'liveness': verification.liveness,
      };
    }

    return {'status': 'success'};
  }
}
