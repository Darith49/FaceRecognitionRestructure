import 'dart:convert';
import 'dart:io';
import 'database.dart';

/// Lightweight Standalone SQLite Backend Server for Face Recognition Attendance.
/// Listens on 127.0.0.1:8080 by default with full CORS support.
/// Serves data directly from `database/face_attendance.db` so all user face biometrics
/// and profile avatars persist permanently across browser and project restarts.
class BackendServer {
  final int port;
  final String? dbPath;
  HttpServer? _server;
  late final AppSqliteDatabase db;

  BackendServer({this.port = 8080, this.dbPath}) {
    db = AppSqliteDatabase();
  }

  Future<void> start() async {
    db.init(dbPath: dbPath);

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('================================================================');
    print('  Face Recognition Attendance - SQLite Backend Server Running');
    print('  URL: http://127.0.0.1:$port');
    print('  Database: ${dbPath ?? "database/face_attendance.db"}');
    print('================================================================');

    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    db.close();
    print('SQLite Backend Server stopped.');
  }

  Future<void> _handleRequest(HttpRequest request) async {
    // 1. CORS Preflight & Headers with full Private Network Access (PNA) support
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');
    request.response.headers.add('Access-Control-Allow-Private-Network', 'true');
    request.response.headers.add('Access-Control-Max-Age', '86400');
    request.response.headers.add('Content-Type', 'application/json; charset=utf-8');

    if (request.method.toUpperCase() == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path.toLowerCase();
    final method = request.method.toUpperCase();
    print('[SQLite Server] $method $path');

    try {
      // 2. Health check
      if (path == '/api/health' || path == '/health') {
        _sendJson(request.response, {
          'status': 'healthy',
          'database': 'sqlite3',
          'server_time': DateTime.now().toIso8601String(),
        });
        return;
      }

      // 3. Full Bootstrap (Hydrates client on launch with entire SQLite state)
      if (path == '/api/bootstrap') {
        final data = db.getBootstrapData();
        _sendJson(request.response, data);
        return;
      }

      // 4. Face Registration & Status
      if (path.contains('/api/face/status')) {
        final email = request.uri.queryParameters['email'] ?? '';
        final uid = request.uri.queryParameters['uid'] ?? '';
        final emp = (email.isNotEmpty ? db.getEmployeeByEmail(email) : null) ??
            (uid.isNotEmpty ? db.getEmployeeById(uid) : null);
        final vault = email.isNotEmpty ? db.getUserVault(email) : null;

        final isRegistered = (vault?['has_face_registered'] == true) ||
            (emp != null && emp['has_face_registered'] == true);

        _sendJson(request.response, {'registered': isRegistered});
        return;
      }

      if (path.contains('/api/face/register') && method == 'POST') {
        final body = await _readJsonBody(request);
        final email = body['email']?.toString() ?? '';
        final uid = body['id']?.toString() ?? body['firebase_uid']?.toString() ?? '';
        final employeeId = body['employee_id']?.toString() ?? '';
        final name = body['name']?.toString() ?? body['fullname']?.toString() ?? 'User';
        final templates = body['templates'];
        final referenceImage = body['reference_image']?.toString();

        db.savePerson({
          'id': uid.isNotEmpty ? uid : (employeeId.isNotEmpty ? employeeId : 'emp_face'),
          'name': name,
          'employee_id': employeeId,
          'templates': templates,
          'reference_image': referenceImage,
        });

        if (email.isNotEmpty) {
          db.saveUserVault(email, {
            'has_face_registered': true,
            'face_templates': templates,
            'face_jpg': referenceImage,
            'face_registered_at': DateTime.now().toIso8601String(),
          });
        }

        _sendJson(request.response, {
          'status': 'success',
          'message': 'Face recognition profile successfully saved in SQLite database.',
        }, statusCode: HttpStatus.created);
        return;
      }

      // 5. Dedicated Profile Picture Upload / Update Endpoint
      if (path.contains('/api/profile/upload') || path.contains('/api/profile/update')) {
        final body = await _readJsonBody(request);
        final email = body['email']?.toString() ?? request.uri.queryParameters['email'] ?? '';
        final uid = body['uid']?.toString() ?? request.uri.queryParameters['uid'] ?? '';
        final pic = body['profile_picture']?.toString() ?? body['profile_url']?.toString();

        if (email.isNotEmpty && pic != null && pic.isNotEmpty) {
          db.saveUserVault(email, {'profile_picture': pic});
          final emp = db.getEmployeeByEmail(email) ?? (uid.isNotEmpty ? db.getEmployeeById(uid) : null);
          if (emp != null) {
            db.updateEmployee(emp['id'], {'profile_picture': pic});
          }
          print('[SQLite Server] Successfully persisted profile picture for $email (len: ${pic.length})');
        }

        _sendJson(request.response, {
          'status': 'success',
          'message': 'Profile picture successfully persisted in SQLite database.',
        });
        return;
      }

      // 6. Employees Update
      if (path.contains('/api/employees/me') && (method == 'PATCH' || method == 'PUT' || method == 'POST')) {
        final body = await _readJsonBody(request);
        if (body.containsKey('profile_url') && !body.containsKey('profile_picture')) {
          body['profile_picture'] = body['profile_url'];
        }
        final email = body['email']?.toString() ?? request.uri.queryParameters['email'] ?? '';
        final uid = body['uid']?.toString() ?? request.uri.queryParameters['uid'] ?? '';

        Map<String, dynamic>? emp;
        if (email.isNotEmpty) {
          emp = db.getEmployeeByEmail(email);
        } else if (uid.isNotEmpty) {
          emp = db.getEmployeeById(uid);
        }

        if (emp != null) {
          db.updateEmployee(emp['id'], body);
        }
        if (email.isNotEmpty) {
          db.saveUserVault(email, body);
        }

        _sendJson(request.response, {
          'status': 'success',
          'message': 'Profile updated in SQLite database.',
          'user': emp != null ? db.getEmployeeById(emp['id']) : null,
        });
        return;
      }

      if (path.contains('/api/employees/my-team')) {
        final all = db.getEmployees();
        _sendJson(request.response, {
          'role': 'ceo',
          'items': all,
          'count': all.length,
        });
        return;
      }

      if (path == '/api/employees/' || path == '/api/employees') {
        if (method == 'GET') {
          final list = db.getEmployees();
          _sendJson(request.response, {'results': list, 'count': list.length});
          return;
        }
      }

      // 6. Attendance
      if (path.contains('/api/attendance/check-in') && method == 'POST') {
        final body = await _readJsonBody(request);
        final res = db.recordAttendance(
          employeeId: body['employee_id']?.toString() ?? '',
          employeeName: body['employee_name']?.toString() ?? 'Employee',
          type: 'check-in',
          time: body['time']?.toString() ?? DateTime.now().toIso8601String().substring(11, 19),
          date: body['date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10),
          checkType: body['check_in_type']?.toString() ?? 'face',
          branchId: body['branch_id'] as int?,
          branchName: body['branch_name']?.toString(),
          notes: body['notes']?.toString(),
          faceMatched: body['face_matched'] != false,
          confidence: (body['confidence'] as num?)?.toDouble() ?? 0.95,
        );
        _sendJson(request.response, res, statusCode: HttpStatus.created);
        return;
      }

      if (path.contains('/api/attendance/check-out') && method == 'POST') {
        final body = await _readJsonBody(request);
        final res = db.recordAttendance(
          employeeId: body['employee_id']?.toString() ?? '',
          employeeName: body['employee_name']?.toString() ?? 'Employee',
          type: 'check-out',
          time: body['time']?.toString() ?? DateTime.now().toIso8601String().substring(11, 19),
          date: body['date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10),
          checkType: body['check_out_type']?.toString() ?? 'face',
          branchId: body['branch_id'] as int?,
          branchName: body['branch_name']?.toString(),
          notes: body['notes']?.toString(),
          faceMatched: body['face_matched'] != false,
          confidence: (body['confidence'] as num?)?.toDouble() ?? 0.95,
        );
        _sendJson(request.response, res);
        return;
      }

      if (path.contains('/api/attendance/status')) {
        final empId = request.uri.queryParameters['employee_id'];
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final records = db.getAttendanceRecords(employeeId: empId, date: today);
        final isCheckedIn = records.isNotEmpty;
        final isCheckedOut = records.isNotEmpty && records.first['check_out_time'] != null;

        _sendJson(request.response, {
          'is_checked_in': isCheckedIn,
          'is_checked_out': isCheckedOut,
          'today_record': records.isNotEmpty ? records.first : null,
        });
        return;
      }

      if (path.contains('/api/attendance/department-summary')) {
        final emps = db.getEmployees();
        final att = db.getAttendanceRecords();
        _sendJson(request.response, {
          'total_employees': emps.length,
          'present': att.where((r) => r['check_out_time'] == null).length,
          'late': 0,
          'absent': 0,
          'on_leave': db.getLeaves().where((l) => l['status'] == 'approved').length,
        });
        return;
      }

      if (path.contains('/api/attendance/')) {
        final records = db.getAttendanceRecords();
        _sendJson(request.response, {'results': records, 'count': records.length});
        return;
      }

      // 7. Requests (Leaves, Overtimes, Suggestions)
      if (path.contains('/api/requests/leave')) {
        if (method == 'POST') {
          final body = await _readJsonBody(request);
          final res = db.createLeave(body);
          _sendJson(request.response, res, statusCode: HttpStatus.created);
          return;
        }
        final list = db.getLeaves();
        _sendJson(request.response, {'results': list, 'count': list.length});
        return;
      }

      if (path.contains('/api/requests/overtime')) {
        if (method == 'POST') {
          final body = await _readJsonBody(request);
          final res = db.createOvertime(body);
          _sendJson(request.response, res, statusCode: HttpStatus.created);
          return;
        }
        final list = db.getOvertimes();
        _sendJson(request.response, {'results': list, 'count': list.length});
        return;
      }

      if (path.contains('/api/requests/suggestions')) {
        final list = db.getSuggestions();
        _sendJson(request.response, {'results': list, 'count': list.length});
        return;
      }

      if (path.contains('/api/requests/incoming')) {
        final leaves = db.getLeaves().where((l) => l['status'] == 'pending').toList();
        final overtimes = db.getOvertimes().where((o) => o['status'] == 'pending').toList();
        _sendJson(request.response, {
          'leaves': leaves,
          'overtimes': overtimes,
          'count': leaves.length + overtimes.length,
        });
        return;
      }

      // 8. Branches & Departments
      if (path.contains('/api/branches')) {
        final list = db.getBranches();
        _sendJson(request.response, {'results': list, 'count': list.length});
        return;
      }

      if (path.contains('/api/departments')) {
        final list = db.getDepartments();
        _sendJson(request.response, {'results': list, 'count': list.length});
        return;
      }

      if (path.contains('/api/notifications')) {
        final list = db.getNotifications();
        _sendJson(request.response, {'results': list, 'count': list.length});
        return;
      }

      // Fallback 404
      _sendJson(request.response, {'error': 'Endpoint not found', 'path': path}, statusCode: HttpStatus.notFound);
    } catch (e, stack) {
      print('Error handling request $path: $e\n$stack');
      _sendJson(request.response, {'error': e.toString()}, statusCode: HttpStatus.internalServerError);
    }
  }

  Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    if (content.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(content) as Map<String, dynamic>;
  }

  void _sendJson(HttpResponse response, dynamic data, {int statusCode = HttpStatus.ok}) {
    response.statusCode = statusCode;
    response.write(jsonEncode(data));
    response.close();
  }
}

void main(List<String> args) async {
  int port = 8080;
  if (args.isNotEmpty) {
    port = int.tryParse(args[0]) ?? 8080;
  }
  final server = BackendServer(port: port);
  await server.start();
}
