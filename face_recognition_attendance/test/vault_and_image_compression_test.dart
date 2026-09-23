import 'dart:convert';
import 'dart:typed_data';
import 'package:face_recognition_attendance/core/utils/image_compressor.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_status.dart';
import 'package:face_recognition_attendance/features/auth/model/enum_user_role.dart';
import 'package:face_recognition_attendance/features/auth/model/user_model.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';
import 'package:image/image.dart' as img;

void main() {
  print('=== STARTING VAULT & IMAGE COMPRESSION PERSISTENCE TESTS ===');

  // Test 1: Image Compression Effectiveness
  print('\n[Test 1] Testing ImageCompressor with high-resolution image...');
  // Create a synthetic 800x800 image
  final syntheticImage = img.Image(width: 800, height: 800);
  for (int y = 0; y < 800; y++) {
    for (int x = 0; x < 800; x++) {
      syntheticImage.setPixelRgb(x, y, (x * 255) ~/ 800, (y * 255) ~/ 800, 128);
    }
  }
  final uncompressedBytes = Uint8List.fromList(img.encodeJpg(syntheticImage, quality: 95));
  print('Original synthetic image size: ${uncompressedBytes.lengthInBytes} bytes');

  final compressedProfile = ImageCompressor.compressProfilePicture(
    'data:image/jpeg;base64,${base64Encode(uncompressedBytes)}',
  );
  final compressedProfileRaw = base64Decode(compressedProfile.split(',')[1]);
  print('Compressed profile picture size: ${compressedProfileRaw.lengthInBytes} bytes');
  assert(compressedProfileRaw.lengthInBytes < 25 * 1024, 'Profile picture should be compressed under 25KB');
  assert(compressedProfileRaw.lengthInBytes < uncompressedBytes.lengthInBytes, 'Compression must significantly reduce size');

  final compressedFace = ImageCompressor.compressFaceReference(uncompressedBytes);
  print('Compressed face reference size: ${compressedFace.lengthInBytes} bytes');
  assert(compressedFace.lengthInBytes < 15 * 1024, 'Face reference should be compressed under 15KB');
  print('Image compression test PASSED.');

  // Test 2: User Model Serialization with Compressed Biometrics & Avatar
  print('\n[Test 2] Testing UserModel serialization with avatar & biometrics...');
  final user = UserModel(
    uid: 'local_uid_ceo_1',
    employeeId: 'EMP-001',
    email: 'sonarseang@gmail.com',
    fullname: 'Sonar Seang',
    role: UserRole.ceo,
    branchId: '1',
    departmentId: '1',
    status: UserStatus.active,
    createdBy: 'system',
    createdAt: DateTime.now(),
    profileUrl: compressedProfile,
    hasFaceRegistered: true,
    faceTemplates: List<double>.filled(128, 0.42),
    faceJpg: base64Encode(compressedFace),
  );

  final jsonMap = user.toJson();
  final deserialized = UserModel.fromJson(jsonMap);

  assert(deserialized.uid == user.uid, 'UID mismatch');
  assert(deserialized.hasFaceRegistered == true, 'hasFaceRegistered must be true');
  assert(deserialized.faceTemplates?.length == 128, 'Template count mismatch');
  assert(deserialized.profileUrl != null, 'Profile URL must be preserved');
  assert(deserialized.faceJpg != null, 'Face JPG must be preserved');
  print('UserModel serialization test PASSED.');

  // Test 3: Person Model Serialization
  print('\n[Test 3] Testing Person model representation...');
  final person = Person(
    id: user.uid,
    name: user.fullname,
    employeeId: user.employeeId,
    faceJpg: compressedFace,
    templates: user.faceTemplates!,
    enrolledAt: DateTime.now(),
  );

  final personMap = person.toMap();
  final restoredPerson = Person.fromMap(personMap);
  assert(restoredPerson.id == person.id, 'Person ID mismatch');
  assert(restoredPerson.templates.length == 128, 'Templates count mismatch');
  assert(restoredPerson.faceJpg.lengthInBytes == compressedFace.lengthInBytes, 'Face bytes size mismatch');
  print('Person model test PASSED.');

  print('\n=== ALL VAULT & IMAGE COMPRESSION TESTS PASSED SUCCESSFULLY! ===\n');
}
