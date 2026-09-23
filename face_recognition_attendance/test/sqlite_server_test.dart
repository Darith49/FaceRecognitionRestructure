import 'dart:convert';
import 'dart:io';
import '../server/server.dart';

void main() async {
  print('=== STARTING SQLITE BACKEND SERVER INTEGRATION TEST ===');

  final testDbFile = 'test_server_run.db';
  if (File(testDbFile).existsSync()) {
    File(testDbFile).deleteSync();
  }

  final testPort = 8099;
  final server = BackendServer(port: testPort, dbPath: testDbFile);
  await server.start();

  final client = HttpClient();

  try {
    // 1. Health check
    print('[Test 1] Testing GET /api/health...');
    final healthReq = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/health'));
    final healthRes = await healthReq.close();
    final healthBody = await utf8.decoder.bind(healthRes).join();
    assert(healthRes.statusCode == HttpStatus.ok, 'Health check should return 200');
    assert(healthBody.contains('healthy'), 'Health response should contain "healthy"');
    print('Health check test - PASSED');

    // 2. Bootstrap
    print('[Test 2] Testing GET /api/bootstrap...');
    final bootReq = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/bootstrap'));
    final bootRes = await bootReq.close();
    final bootBody = await utf8.decoder.bind(bootRes).join();
    final bootData = jsonDecode(bootBody) as Map<String, dynamic>;
    assert(bootRes.statusCode == HttpStatus.ok, 'Bootstrap should return 200');
    assert((bootData['employees'] as List).length == 5, 'Bootstrap should return 5 employees');
    assert((bootData['branches'] as List).length == 2, 'Bootstrap should return 2 branches');
    print('Bootstrap snapshot test - PASSED');

    // 3. Face Registration
    print('[Test 3] Testing POST /api/face/register...');
    final faceReq = await client.postUrl(Uri.parse('http://127.0.0.1:$testPort/api/face/register/'));
    faceReq.headers.contentType = ContentType.json;
    final sampleVector = List.generate(128, (i) => 0.01 * i);
    faceReq.write(jsonEncode({
      'email': 'sonarseang@gmail.com',
      'id': 'local_uid_ceo_1',
      'employee_id': 'EMP-001',
      'name': 'Sonar Seang',
      'templates': [sampleVector],
      'reference_image': 'data:image/jpeg;base64,sample_ceo_face',
    }));
    final faceRes = await faceReq.close();
    final faceBody = await utf8.decoder.bind(faceRes).join();
    assert(faceRes.statusCode == HttpStatus.created, 'Face register should return 201');
    assert(faceBody.contains('success'), 'Face register response should indicate success');

    // Verify face status
    final statusReq = await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/api/face/status/?email=sonarseang@gmail.com'));
    final statusRes = await statusReq.close();
    final statusBody = await utf8.decoder.bind(statusRes).join();
    final statusData = jsonDecode(statusBody) as Map<String, dynamic>;
    assert(statusData['registered'] == true, 'Face status should show registered=true');
    print('Face registration test - PASSED');

    // 4. Update Profile Picture
    print('[Test 4] Testing PATCH /api/employees/me...');
    final patchReq = await client.patchUrl(Uri.parse('http://127.0.0.1:$testPort/api/employees/me/?email=sonarseang@gmail.com'));
    patchReq.headers.contentType = ContentType.json;
    patchReq.write(jsonEncode({
      'email': 'sonarseang@gmail.com',
      'profile_picture': 'data:image/jpeg;base64,new_compressed_avatar',
    }));
    final patchRes = await patchReq.close();
    assert(patchRes.statusCode == HttpStatus.ok, 'Patch should return 200');

    // Verify it updated in database
    final vault = server.db.getUserVault('sonarseang@gmail.com');
    assert(vault != null, 'Vault must exist');
    assert(vault!['profile_picture'] == 'data:image/jpeg;base64,new_compressed_avatar', 'Avatar must be persisted');
    print('Profile picture update test - PASSED');

    // 5. Attendance Check-in
    print('[Test 5] Testing POST /api/attendance/check-in...');
    final attReq = await client.postUrl(Uri.parse('http://127.0.0.1:$testPort/api/attendance/check-in/'));
    attReq.headers.contentType = ContentType.json;
    attReq.write(jsonEncode({
      'employee_id': 'EMP-001',
      'employee_name': 'Sonar Seang',
      'time': '08:05:00',
      'date': '2026-09-23',
      'check_in_type': 'face',
    }));
    final attRes = await attReq.close();
    assert(attRes.statusCode == HttpStatus.created, 'Attendance check-in should return 201');
    final attList = server.db.getAttendanceRecords(employeeId: 'EMP-001', date: '2026-09-23');
    assert(attList.isNotEmpty, 'Attendance record must be saved');
    print('Attendance check-in test - PASSED');

  } finally {
    client.close();
    await server.stop();

    if (File(testDbFile).existsSync()) {
      File(testDbFile).deleteSync();
    }
  }

  print('=== ALL SQLITE BACKEND SERVER INTEGRATION TESTS PASSED! ===');
}
