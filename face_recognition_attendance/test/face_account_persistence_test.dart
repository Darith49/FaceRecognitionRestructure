import 'dart:convert';
import 'dart:typed_data';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/employee/model/employee_model.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';

void main() {
  print('=== STARTING FACE ACCOUNT PERSISTENCE TESTS ===');

  // Test 1: UserModel face serialization
  print('\n[Test 1] Testing UserModel face recognition serialization...');
  final testTemplates = List.generate(128, (i) => i * 0.01);
  final user = UserModel(
    uid: 'local_uid_emp_5',
    employeeId: 'EMP-005',
    email: 'employee@gmail.com',
    fullname: 'Alex Developer',
    role: UserRole.employee,
    branchId: '1',
    departmentId: '1',
    hasFaceRegistered: true,
    faceTemplates: testTemplates,
    faceJpg: 'base64_test_photo',
    createdBy: 'system',
    createdAt: DateTime.now(),
  );

  final userMap = user.toMap();
  assert(userMap['hasFaceRegistered'] == true);
  assert(userMap['faceTemplates'] != null);
  assert((userMap['faceTemplates'] as List).length == 128);

  final userFromJson = UserModel.fromJson(user.toJson());
  assert(userFromJson.hasFaceRegistered == true);
  assert(userFromJson.faceTemplates != null && userFromJson.faceTemplates!.length == 128);
  assert(userFromJson.faceJpg == 'base64_test_photo');

  final userCopied = userFromJson.copyWith(hasFaceRegistered: false);
  assert(userCopied.hasFaceRegistered == false);
  assert(userCopied.uid == 'local_uid_emp_5');
  print('UserModel serialization & copyWith passed.');

  // Test 2: EmployeeModel face serialization
  print('\n[Test 2] Testing EmployeeModel face recognition serialization...');
  final empModel = EmployeeModel(
    id: 5,
    firebaseUid: 'local_uid_emp_5',
    employeeId: 'EMP-005',
    fullname: 'Alex Developer',
    email: 'employee@gmail.com',
    role: UserRole.employee,
    hasFaceRegistered: true,
  );

  final empJson = empModel.toJson();
  assert(empJson['has_face_registered'] == true);

  final empFromJson = EmployeeModel.fromJson(empJson);
  assert(empFromJson.hasFaceRegistered == true);
  print('EmployeeModel serialization passed.');

  // Test 3: Person serialization and biometrics storage representation
  print('\n[Test 3] Testing Person model and account link representation...');
  final sampleJpg = Uint8List.fromList([1, 2, 3, 4, 5]);
  final samplePerson = Person(
    id: 'local_uid_emp_5',
    name: 'Alex Developer',
    employeeId: 'EMP-005',
    faceJpg: sampleJpg,
    templates: testTemplates,
    enrolledAt: DateTime.now(),
  );

  final personMap = samplePerson.toMap();
  assert(personMap['id'] == 'local_uid_emp_5');
  assert(personMap['employeeId'] == 'EMP-005');
  assert(personMap['faceJpg'] == base64Encode(sampleJpg));
  assert((personMap['templates'] as List).length == 128);

  final reconstructedPerson = Person.fromMap(personMap);
  assert(reconstructedPerson.employeeId == 'EMP-005');
  assert(reconstructedPerson.templates.length == 128);
  assert(reconstructedPerson.faceJpg.length == 5);
  print('Person serialization and biometric format verified.');

  // Test 4: Account-to-Person data recovery simulation
  print('\n[Test 4] Testing reconstruction of Person from account data...');
  final accountData = {
    'id': 5,
    'employee_id': 'EMP-005',
    'firebase_uid': 'local_uid_emp_5',
    'fullname': 'Alex Developer',
    'has_face_registered': true,
    'face_templates': testTemplates,
    'face_jpg': base64Encode(sampleJpg),
    'face_registered_at': DateTime.now().toIso8601String(),
  };

  final recoveredPerson = Person.fromMap({
    'id': accountData['firebase_uid'],
    'name': accountData['fullname'],
    'employeeId': accountData['employee_id'],
    'faceJpg': accountData['face_jpg'],
    'templates': accountData['face_templates'],
    'enrolledAt': accountData['face_registered_at'],
  });

  assert(recoveredPerson.id == 'local_uid_emp_5');
  assert(recoveredPerson.employeeId == 'EMP-005');
  assert(recoveredPerson.templates.length == 128);
  assert(recoveredPerson.faceJpg.length == 5);
  print('Account-to-Person self-healing recovery verified.');

  print('\n=== ALL FACE ACCOUNT PERSISTENCE TESTS PASSED SUCCESSFULLY! ===');
}
