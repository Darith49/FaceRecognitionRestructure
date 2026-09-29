import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:face_recognition_attendance/core/services/face_recognition_engine.dart';
import 'package:face_recognition_attendance/core/utils/date_text.dart';
import 'package:face_recognition_attendance/core/utils/image_compressor.dart';
import 'package:face_recognition_attendance/core/services/local_auth_service.dart';
import 'package:face_recognition_attendance/core/services/local_database_service.dart';
import 'package:face_recognition_attendance/core/services/secure_storage_service.dart';
import 'package:face_recognition_attendance/features/auth/controller/login_controller.dart';
import 'package:face_recognition_attendance/features/ceo_manage/service/ceo_report_service.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';
import 'package:get/get.dart';

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
      final vault = _db.getUserAccountData(user.email);
      final empCode = emp?['employee_id']?.toString() ?? '';
      final enrolled = (vault?['has_face_registered'] == true) ||
          (emp != null && emp['has_face_registered'] == true) ||
          _db.getPersons().any(
            (p) =>
                p.id == user.uid ||
                (empCode.isNotEmpty && p.employeeId == empCode) ||
                p.employeeId == user.uid ||
                (emp != null && p.id == emp['firebase_uid']),
          );
      return {'registered': enrolled};
    }

    // 5. Attendance
    if (clean.contains('/attendance/status/')) {
      final user = _auth.getCurrentUser();
      return _db.getAttendanceStatus(user?.uid ?? 1);
    }
    if (clean.contains('/attendance/department-summary/')) {
      final user = _auth.getCurrentUser();
      final emp = user != null
          ? (_db.getEmployeeByUid(user.uid) ?? _db.getEmployeeByEmail(user.email))
          : null;
      final role = (emp?['role'] ?? 'employee').toString().toLowerCase();
      final allEmployees = _db.getEmployees();
      
      List<Map<String, dynamic>> scoped;
      if (role == 'leader') {
        final dept = emp?['department']?.toString();
        scoped = allEmployees.where((e) =>
          e['id']?.toString() != emp?['id']?.toString() &&
          e['role']?.toString().toLowerCase() == 'employee' &&
          (dept == null || dept.isEmpty || e['department']?.toString() == dept)
        ).toList();
      } else if (role == 'manager') {
        final branch = emp?['branch']?.toString();
        scoped = allEmployees.where((e) =>
          e['id']?.toString() != emp?['id']?.toString() &&
          (e['role']?.toString().toLowerCase() == 'leader' || e['role']?.toString().toLowerCase() == 'employee') &&
          (branch == null || branch.isEmpty || e['branch']?.toString() == branch)
        ).toList();
      } else {
        scoped = allEmployees.where((e) => e['role']?.toString().toLowerCase() != 'ceo').toList();
      }

      final todayStr = DateText.ymd(DateText.nowCambodia());
      final records = _db.getAttendanceRecords(date: todayStr);
      final activeIds = records.map((r) => r['employee_id']?.toString() ?? r['employee_uid']?.toString()).toSet();
      
      final present = scoped.where((e) => activeIds.contains(e['id']?.toString()) || activeIds.contains(e['firebase_uid']?.toString())).length;
      final onLeave = _db.getLeaves(status: 'approved').where((l) =>
        (l['from_date']?.toString().compareTo(todayStr) ?? 1) <= 0 &&
        (l['to_date']?.toString().compareTo(todayStr) ?? -1) >= 0
      ).length;
      final lateCount = records.where((r) => r['is_late'] == true).length;
      final absent = (scoped.length - present - onLeave).clamp(0, scoped.length);

      return {
        'total_employees': scoped.length,
        'present': present,
        'late': lateCount,
        'absent': absent,
        'on_leave': onLeave,
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

    // Current user helper
    final currentUser = _auth.getCurrentUser();
    final currentEmp = currentUser != null
        ? (_db.getEmployeeByUid(currentUser.uid) ?? _db.getEmployeeByEmail(currentUser.email))
        : null;
    final currentRole = (currentEmp?['role'] ?? 'employee').toString().toLowerCase();
    final filterEmpId = currentRole == 'employee' && currentEmp != null ? currentEmp['id'] : null;

    // 6. Requests (Leave, Overtime, Permissions, Suggestions, Incoming)
    if (clean.contains('/requests/leave/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3 && int.tryParse(parts[2]) != null) {
        final id = parts[2];
        final item = _db.getLeaveById(id);
        return item ?? {'error': 'Leave request not found'};
      }
      final list = _db.getLeaves(employeeId: filterEmpId);
      return list;
    }

    if (clean.contains('/requests/overtime/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3 && int.tryParse(parts[2]) != null) {
        final id = parts[2];
        final item = _db.getOvertimeById(id);
        return item ?? {'error': 'Overtime request not found'};
      }
      final list = _db.getOvertimes(employeeId: filterEmpId);
      return list;
    }

    if (clean.contains('/requests/permissions/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3 && int.tryParse(parts[2]) != null) {
        final id = parts[2];
        final item = _db.getPermissionById(id);
        return item ?? {'error': 'Permission request not found'};
      }
      final list = _db.getPermissions(employeeId: filterEmpId);
      return list;
    }

    if (clean.contains('/requests/suggestions/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3 && int.tryParse(parts[2]) != null) {
        final id = parts[2];
        final item = _db.getSuggestionById(id);
        return item ?? {'error': 'Suggestion not found'};
      }
      final list = _db.getSuggestionsForRole(
        currentRole,
        employeeId: currentEmp?['id'],
        branchId: currentEmp?['branch'],
        statusFilter: queryParams?['status']?.toString(),
      );
      return list;
    }

    if (clean.contains('/requests/incoming/')) {
      return _db.getIncomingRequests(
        role: currentRole,
        employeeId: currentEmp?['id'],
        branchId: currentEmp?['branch'],
        departmentId: currentEmp?['department'],
      );
    }

    // 7. Notifications
    if (clean.contains('/notifications/')) {
      final list = _db.getNotifications(
        employeeId: currentEmp?['id'],
        firebaseUid: currentUser?.uid,
      );
      final unread = list.where((n) => n['is_read'] != true).length;
      return {
        'results': list,
        'unread_count': unread,
        'count': list.length,
      };
    }

    // 8. CEO Attendance Reports
    if (clean.contains('/reports/attendance/branches-summary')) {
      final period = queryParams?['period']?.toString() ?? 'this_month';
      final y = int.tryParse(queryParams?['year']?.toString() ?? '');
      final m = int.tryParse(queryParams?['month']?.toString() ?? '');
      final service = CeoReportService();
      final rep = await service.getBranchesSummary(period: period, year: y, month: m);
      return rep.toJson();
    }
    if (clean.contains('/reports/attendance/branch/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      final branchId = int.tryParse(parts.lastWhere((p) => int.tryParse(p) != null, orElse: () => '1')) ?? 1;
      final period = queryParams?['period']?.toString() ?? 'this_month';
      final y = int.tryParse(queryParams?['year']?.toString() ?? '');
      final m = int.tryParse(queryParams?['month']?.toString() ?? '');
      final service = CeoReportService();
      final rep = await service.getBranchDetail(branchId: branchId, period: period, year: y, month: m);
      return rep.toJson();
    }
    if (clean.contains('/reports/attendance/employee/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      final empId = int.tryParse(parts.lastWhere((p) => int.tryParse(p) != null, orElse: () => '1')) ?? 1;
      final period = queryParams?['period']?.toString() ?? 'this_month';
      final y = int.tryParse(queryParams?['year']?.toString() ?? '');
      final m = int.tryParse(queryParams?['month']?.toString() ?? '');
      final service = CeoReportService();
      final rep = await service.getEmployeeDetail(employeeId: empId, period: period, year: y, month: m);
      return rep.toJson();
    }

    return {'results': []};
  }

  /// GET request returning raw bytes (e.g., Excel/CSV export)
  Future<List<int>> getBytes(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final clean = endpoint.toLowerCase();
    if (clean.contains('/reports/attendance/export')) {
      final scope = queryParams?['scope']?.toString() ?? 'all';
      final branchId = int.tryParse(queryParams?['branch_id']?.toString() ?? '');
      final period = queryParams?['period']?.toString() ?? 'this_month';
      final y = int.tryParse(queryParams?['year']?.toString() ?? '');
      final m = int.tryParse(queryParams?['month']?.toString() ?? '');
      final service = CeoReportService();
      return await service.exportExcelBytes(scope: scope, branchId: branchId, period: period, year: y, month: m);
    }
    return [];
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    await _db.init();
    final clean = endpoint.toLowerCase();
    final data = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final currentUser = _auth.getCurrentUser();
    final currentEmp = currentUser != null
        ? (_db.getEmployeeByUid(currentUser.uid) ?? _db.getEmployeeByEmail(currentUser.email))
        : null;
    final currentRole = (currentEmp?['role'] ?? 'employee').toString().toLowerCase();

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

    // Reviews (Leave, Overtime, Permission)
    if (clean.contains('/requests/leave/') && clean.contains('/review/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      final id = parts.length >= 3 ? parts[2] : '';
      final leave = _db.getLeaveById(id);
      if (leave == null) return {'error': 'Leave request not found'};
      final reqRole = (leave['employee_role'] ?? 'employee').toString();
      if (!_db.canUserReviewRequester(currentRole, reqRole)) {
        return {'error': 'You do not have permission to review this request'};
      }
      final updated = _db.reviewLeave(
        id,
        status: data['status'] ?? 'approved',
        reviewerName: currentEmp?['fullname'] ?? 'Supervisor',
        reviewerRole: currentRole,
        reviewNotes: data['review_notes']?.toString(),
      );
      return updated ?? {'error': 'Could not update leave'};
    }

    if (clean.contains('/requests/overtime/') && clean.contains('/review/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      final id = parts.length >= 3 ? parts[2] : '';
      final ot = _db.getOvertimeById(id);
      if (ot == null) return {'error': 'Overtime request not found'};
      final reqRole = (ot['employee_role'] ?? 'employee').toString();
      if (!_db.canUserReviewRequester(currentRole, reqRole)) {
        return {'error': 'You do not have permission to review this request'};
      }
      final updated = _db.reviewOvertime(
        id,
        status: data['status'] ?? 'approved',
        reviewerName: currentEmp?['fullname'] ?? 'Supervisor',
        reviewerRole: currentRole,
        reviewNotes: data['review_notes']?.toString(),
      );
      return updated ?? {'error': 'Could not update overtime'};
    }

    if (clean.contains('/requests/permissions/') && clean.contains('/review/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      final id = parts.length >= 3 ? parts[2] : '';
      final perm = _db.getPermissionById(id);
      if (perm == null) return {'error': 'Permission request not found'};
      final reqRole = (perm['employee_role'] ?? 'employee').toString();
      if (!_db.canUserReviewRequester(currentRole, reqRole)) {
        return {'error': 'You do not have permission to review this request'};
      }
      final updated = _db.reviewPermission(
        id,
        status: data['status'] ?? 'approved',
        reviewerName: currentEmp?['fullname'] ?? 'Supervisor',
        reviewerRole: currentRole,
        reviewNotes: data['review_notes']?.toString(),
      );
      return updated ?? {'error': 'Could not update permission'};
    }

    // Creating Requests
    if (clean.contains('/requests/leave/')) {
      if (currentEmp != null) {
        data['employee_id'] ??= currentEmp['id'];
        data['employee_name'] ??= currentEmp['fullname'];
        data['employee_code'] ??= currentEmp['employee_id'];
        data['employee_id_code'] ??= currentEmp['employee_id'];
        data['employee_role'] ??= currentEmp['role'];
        data['employee_uid'] ??= currentEmp['firebase_uid'];
        data['employee_email'] ??= currentEmp['email'];
        data['employee_profile_url'] ??= currentEmp['profile_picture'];
        data['branch'] ??= currentEmp['branch'];
        data['department'] ??= currentEmp['department'];
      }
      return _db.addLeave(data);
    }

    if (clean.contains('/requests/overtime/')) {
      if (currentEmp != null) {
        data['employee_id'] ??= currentEmp['id'];
        data['employee_name'] ??= currentEmp['fullname'];
        data['employee_code'] ??= currentEmp['employee_id'];
        data['employee_id_code'] ??= currentEmp['employee_id'];
        data['employee_role'] ??= currentEmp['role'];
        data['employee_uid'] ??= currentEmp['firebase_uid'];
        data['employee_email'] ??= currentEmp['email'];
        data['employee_profile_url'] ??= currentEmp['profile_picture'];
        data['branch'] ??= currentEmp['branch'];
        data['department'] ??= currentEmp['department'];
      }
      return _db.addOvertime(data);
    }

    if (clean.contains('/requests/permissions/')) {
      if (currentEmp != null) {
        data['employee_id'] ??= currentEmp['id'];
        data['employee_name'] ??= currentEmp['fullname'];
        data['employee_code'] ??= currentEmp['employee_id'];
        data['employee_id_code'] ??= currentEmp['employee_id'];
        data['employee_role'] ??= currentEmp['role'];
        data['employee_uid'] ??= currentEmp['firebase_uid'];
        data['employee_email'] ??= currentEmp['email'];
        data['employee_profile_url'] ??= currentEmp['profile_picture'];
        data['branch'] ??= currentEmp['branch'];
        data['department'] ??= currentEmp['department'];
      }
      return _db.addPermission(data);
    }

    if (clean.contains('/requests/suggestions/') && clean.contains('/read/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      final id = parts.length >= 3 ? parts[2] : 1;
      _db.markSuggestionRead(id, readByName: currentEmp?['fullname']);
      return {'status': 'ok'};
    }

    if (clean.contains('/requests/suggestions/')) {
      if (currentEmp != null) {
        data['employee_id'] ??= currentEmp['id'];
        data['employee_role'] ??= currentEmp['role'];
        data['branch'] ??= currentEmp['branch'];
      }
      return _db.addSuggestion(data);
    }

    // Notifications
    if (clean.contains('/notifications/mark-all-read/')) {
      _db.markAllNotificationsReadForUser(
        employeeId: currentEmp?['id'],
        firebaseUid: currentUser?.uid,
      );
      return {'status': 'ok'};
    }
    if (clean.contains('/notifications/') && clean.contains('/read/')) {
      final parts = endpoint.split('/').where((p) => p.isNotEmpty).toList();
      final id = parts.length >= 2 ? parts[1] : null;
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

    if (clean.contains('/employees/me/')) {
      final user = _auth.getCurrentUser();
      if (user != null) {
        final emp = _db.getEmployeeByUid(user.uid) ?? _db.getEmployeeByEmail(user.email);
        if (emp != null) {
          if (data.containsKey('profile_url') && !data.containsKey('profile_picture')) {
            data['profile_picture'] = data['profile_url'];
          }
          if (data.containsKey('profile_picture') && data['profile_picture'] != null) {
            data['profile_picture'] = ImageCompressor.compressProfilePicture(data['profile_picture'].toString());
          }
          final res = _db.updateEmployee(emp['id'], data);
          if (data.containsKey('profile_picture')) {
            _db.saveUserAccountData(user.email, {'profile_picture': data['profile_picture']});
          }
          return res;
        }
      }
      return data;
    }

    if (clean.contains('/employees/')) {
      final id = parts.length >= 2 ? parts[1] : 1;
      return _db.updateEmployee(id, data);
    }

    if (clean.contains('/requests/leave/')) {
      final id = parts.length >= 3 ? parts[2] : 1;
      return _db.updateLeave(id, data);
    }

    if (clean.contains('/requests/overtime/')) {
      final id = parts.length >= 3 ? parts[2] : 1;
      return _db.updateOvertime(id, data);
    }

    if (clean.contains('/requests/permissions/')) {
      final id = parts.length >= 3 ? parts[2] : 1;
      return _db.updatePermission(id, data);
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

    if (clean.contains('/requests/permissions/')) {
      final id = parts.length >= 3 ? parts[2] : null;
      if (id != null) _db.deletePermission(id);
      return {'status': 'deleted'};
    }

    if (clean.contains('/requests/suggestions/')) {
      final id = parts.length >= 3 ? parts[2] : null;
      if (id != null) _db.deleteSuggestion(id);
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

      // Compress thumbnail for efficient browser storage (~5KB)
      final compressedThumb = ImageCompressor.compressFaceReference(bytes);
      final person = Person(
        id: personId,
        name: personName,
        employeeId: employeeId,
        faceJpg: compressedThumb,
        templates: template,
        enrolledAt: DateTime.now(),
      );

      _db.savePerson(person);

      // Save directly to the persistent user vault so it permanently survives
      _db.saveUserAccountData(user.email, {
        'has_face_registered': true,
        'face_templates': template,
        'face_jpg': base64Encode(compressedThumb),
        'face_registered_at': DateTime.now().toIso8601String(),
      });

      // Keep LoginController & session in sync immediately with the saved face
      if (Get.isRegistered<LoginController>()) {
        final loginCtrl = Get.find<LoginController>();
        loginCtrl.hasFaceRegistered.value = true;
        if (loginCtrl.currentuser.value != null) {
          final updated = loginCtrl.currentuser.value!.copyWith(
            hasFaceRegistered: true,
            faceTemplates: template,
            faceJpg: base64Encode(compressedThumb),
          );
          loginCtrl.currentuser.value = updated;
          SecureStorageService().updateCachedUserData(updated.toJson());
        }
      }

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
        if (p.id == user.uid ||
            (empCode.isNotEmpty && p.employeeId == empCode) ||
            p.employeeId == user.uid ||
            p.id == emp['firebase_uid']) {
          enrolledPerson = p;
          break;
        }
      }

      // Self-healing fallback: If not in cache but saved in employee account
      if (enrolledPerson == null &&
          emp['face_templates'] is List &&
          (emp['face_templates'] as List).isNotEmpty) {
        enrolledPerson = Person(
          id: user.uid,
          name: empName,
          employeeId: empCode.isNotEmpty ? empCode : user.uid,
          faceJpg: emp['face_jpg'] != null ? base64Decode(emp['face_jpg']) : Uint8List(0),
          templates: (emp['face_templates'] as List).map((e) => (e as num).toDouble()).toList(),
          enrolledAt: emp['face_registered_at'] != null
              ? (DateTime.tryParse(emp['face_registered_at']) ?? DateTime.now())
              : DateTime.now(),
        );
        _db.savePerson(enrolledPerson);
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
        if (p.id == user.uid ||
            (empCode.isNotEmpty && p.employeeId == empCode) ||
            p.employeeId == user.uid ||
            p.id == emp['firebase_uid']) {
          enrolledPerson = p;
          break;
        }
      }

      // Self-healing fallback: If not in cache but saved in employee account
      if (enrolledPerson == null &&
          emp['face_templates'] is List &&
          (emp['face_templates'] as List).isNotEmpty) {
        enrolledPerson = Person(
          id: user.uid,
          name: empName,
          employeeId: empCode.isNotEmpty ? empCode : user.uid,
          faceJpg: emp['face_jpg'] != null ? base64Decode(emp['face_jpg']) : Uint8List(0),
          templates: (emp['face_templates'] as List).map((e) => (e as num).toDouble()).toList(),
          enrolledAt: emp['face_registered_at'] != null
              ? (DateTime.tryParse(emp['face_registered_at']) ?? DateTime.now())
              : DateTime.now(),
        );
        _db.savePerson(enrolledPerson);
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
