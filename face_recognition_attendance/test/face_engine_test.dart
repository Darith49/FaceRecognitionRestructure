import 'dart:math';
import 'dart:typed_data';
import 'package:face_recognition_attendance/core/services/face_recognition_engine.dart';
import 'package:face_recognition_attendance/features/face/model/person_model.dart';
import 'package:image/image.dart' as img;

void main() async {
  print('=== STARTING BIOMETRIC FACE RECOGNITION ENGINE TESTS ===');

  final engine = FaceRecognitionEngine();

  // Test 1: Similarity Calculation
  print('\n[Test 1] Testing cosine similarity calculation...');
  final t1 = List<double>.generate(128, (i) => i / 128.0);
  final t2 = List<double>.generate(128, (i) => i / 128.0);

  final simExact = engine.similarityCalculation(t1, t2);
  print('Exact match similarity: ${(simExact * 100).toStringAsFixed(2)}%');
  assert((simExact - 1.0).abs() < 1e-5, 'Identical templates must yield similarity 1.0');

  // Orthogonal test
  final tA = List<double>.filled(128, 0.0);
  final tB = List<double>.filled(128, 0.0);
  for (int i = 0; i < 64; i++) {
    tA[i] = 1.0;
  }
  for (int i = 64; i < 128; i++) {
    tB[i] = 1.0;
  }
  final simOrtho = engine.similarityCalculation(tA, tB);
  print('Orthogonal templates similarity: ${(simOrtho * 100).toStringAsFixed(2)}%');
  assert(simOrtho == 0.0, 'Orthogonal vectors must yield similarity 0.0');

  // Test 2: Image Processing & Biometric Feature Extraction
  print('\n[Test 2] Generating synthetic portrait image and extracting biometric template...');
  final testImg = img.Image(width: 200, height: 200);
  // Fill background
  img.fill(testImg, color: img.ColorRgb8(230, 230, 230));
  // Draw face oval
  img.fillCircle(testImg, x: 100, y: 100, radius: 60, color: img.ColorRgb8(240, 200, 170));
  // Draw eyes
  img.fillCircle(testImg, x: 80, y: 85, radius: 8, color: img.ColorRgb8(40, 40, 40));
  img.fillCircle(testImg, x: 120, y: 85, radius: 8, color: img.ColorRgb8(40, 40, 40));
  // Draw mouth
  img.fillRect(testImg, x1: 85, y1: 125, x2: 115, y2: 135, color: img.ColorRgb8(180, 70, 70));

  final jpgBytes = Uint8List.fromList(img.encodeJpg(testImg));

  final template = await engine.extractFaceTemplate(jpgBytes);
  print('Extracted template dimension: ${template.length}');
  assert(template.length == 128, 'Template must be 128-dimensional');

  // Check L2 norm
  double normSq = 0.0;
  for (final v in template) {
    normSq += v * v;
  }
  final norm = sqrt(normSq);
  print('Template L2 norm: ${norm.toStringAsFixed(4)}');
  assert((norm - 1.0).abs() < 1e-3, 'Extracted template must be L2 normalized to unit length');

  // Test 3: Liveness calculation
  print('\n[Test 3] Testing liveness metric...');
  final liveness = await engine.calculateLiveness(jpgBytes);
  print('Calculated liveness score: ${(liveness * 100).toStringAsFixed(1)}%');
  assert(liveness > 0.0, 'Liveness score must be positive for valid image');

  // Test 4: 1:N Biometric Face Matching
  print('\n[Test 4] Testing 1:N biometric matching...');
  final enrolledPerson = Person(
    id: 'emp_001',
    name: 'Darith Admin',
    employeeId: 'EMP-001',
    faceJpg: jpgBytes,
    templates: template,
    enrolledAt: DateTime.now(),
  );

  final matchResult = await engine.matchFace(
    jpgBytes,
    [enrolledPerson],
    identifyThreshold: 0.70,
    livenessThreshold: 0.50,
  );

  print('Matched Person: ${matchResult.matchedPerson?.name}');
  print('Similarity: ${(matchResult.similarity * 100).toStringAsFixed(2)}%');
  print('Liveness: ${(matchResult.liveness * 100).toStringAsFixed(2)}%');
  print('Is Recognized: ${matchResult.isRecognized}');
  print('Status Message: ${matchResult.statusMessage}');

  assert(matchResult.matchedPerson?.id == 'emp_001', 'Must match enrolled person');
  assert(matchResult.similarity > 0.95, 'Same image must match with >95% similarity');
  assert(matchResult.isRecognized == true, 'Same image must be recognized');

  // Test 5: Distinct Face Discrimination (Rejection test)
  print('\n[Test 5] Testing distinct face discrimination...');
  final differentImg = img.Image(width: 200, height: 200);
  img.fill(differentImg, color: img.ColorRgb8(50, 50, 80));
  img.fillRect(differentImg, x1: 40, y1: 40, x2: 160, y2: 160, color: img.ColorRgb8(120, 180, 220));
  final diffBytes = Uint8List.fromList(img.encodeJpg(differentImg));

  final diffResult = await engine.matchFace(
    diffBytes,
    [enrolledPerson],
    identifyThreshold: 0.75,
    livenessThreshold: 0.50,
  );
  print('Different face similarity: ${(diffResult.similarity * 100).toStringAsFixed(2)}%');
  print('Different face recognized: ${diffResult.isRecognized}');
  assert(diffResult.isRecognized == false, 'Different face should not be recognized');
  assert(diffResult.similarity < 0.75, 'Similarity of different face should be below threshold');

  print('\n=== ALL BIOMETRIC FACE RECOGNITION TESTS PASSED SUCCESSFULLY! ===');
}
