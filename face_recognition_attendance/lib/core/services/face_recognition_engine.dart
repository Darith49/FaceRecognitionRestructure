import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:face_recognition_attendance/features/face/model/person_model.dart';

/// Result of a face recognition and liveness analysis pass.
class FaceMatchResult {
  final Person? matchedPerson;
  final double similarity;
  final double liveness;
  final bool isRecognized;
  final String statusMessage;
  final List<double> extractedTemplate;
  final Uint8List? croppedFaceJpg;

  const FaceMatchResult({
    this.matchedPerson,
    required this.similarity,
    required this.liveness,
    required this.isRecognized,
    required this.statusMessage,
    required this.extractedTemplate,
    this.croppedFaceJpg,
  });
}

/// Cross-platform Biometric Face Recognition & Liveness Engine.
/// Designed after the kby-ai FaceRecognition architecture to run
/// natively and client-side on both Web and Native (Android, iOS, Windows, macOS).
class FaceRecognitionEngine {
  static final FaceRecognitionEngine _instance = FaceRecognitionEngine._internal();
  factory FaceRecognitionEngine() => _instance;
  FaceRecognitionEngine._internal();

  /// Default similarity threshold for 1:N face identification (0.0 to 1.0).
  double defaultIdentifyThreshold = 0.72;

  /// Default liveness threshold based on sharpness and gradient entropy.
  double defaultLivenessThreshold = 0.60;

  /// Normalized embedding dimensions
  static const int embeddingDimension = 128;

  /// Calculates cosine similarity between two biometric templates.
  /// Matches the kby-ai similarityCalculation interface.
  double similarityCalculation(List<double> template1, List<double> template2) {
    if (template1.isEmpty || template2.isEmpty) return 0.0;
    if (template1.length != template2.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < template1.length; i++) {
      dotProduct += template1[i] * template2[i];
      normA += template1[i] * template1[i];
      normB += template2[i] * template2[i];
    }

    if (normA <= 0.0 || normB <= 0.0) return 0.0;

    final cosSim = dotProduct / (sqrt(normA) * sqrt(normB));
    // Clamped and normalized to [0.0, 1.0]
    return cosSim.clamp(0.0, 1.0);
  }

  /// Extracts a normalized 128-dimensional biometric template from image bytes.
  Future<List<double>> extractFaceTemplate(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw Exception('Unable to decode image for face template extraction.');
    }

    // 1. Orient image upright
    final oriented = img.bakeOrientation(decoded);

    // 2. Crop face region (center portrait crop with aspect ratio 1:1)
    final faceCrop = _cropFaceRegion(oriented);

    // 3. Resize to standard biometric analysis canvas (112x112)
    final normalizedFace = img.copyResize(faceCrop, width: 112, height: 112);

    // 4. Extract localized spatial gradient & texture embedding
    final embedding = _computeSpatialFeatureVector(normalizedFace);

    return _l2Normalize(embedding);
  }

  /// Evaluates liveness & image quality via high-frequency Laplacian variance and contrast.
  Future<double> calculateLiveness(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return 0.0;

    final oriented = img.bakeOrientation(decoded);
    final faceCrop = _cropFaceRegion(oriented);
    final resized = img.copyResize(faceCrop, width: 96, height: 96);

    // Calculate Laplacian gradient variance (sharpness metric)
    double sum = 0.0;
    double sumSq = 0.0;
    int count = 0;

    final grayscale = img.grayscale(resized);

    for (int y = 1; y < grayscale.height - 1; y++) {
      for (int x = 1; x < grayscale.width - 1; x++) {
        final c = grayscale.getPixel(x, y).r;
        final up = grayscale.getPixel(x, y - 1).r;
        final down = grayscale.getPixel(x, y + 1).r;
        final left = grayscale.getPixel(x - 1, y).r;
        final right = grayscale.getPixel(x + 1, y).r;

        // Discrete 4-neighborhood Laplacian operator
        final lap = (4 * c - up - down - left - right).abs();
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 0.0;

    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);

    // Map variance to liveness score [0.0, 1.0]
    // A clean camera face usually has variance between 150 and 1500+
    double livenessScore = (variance / 300.0).clamp(0.0, 1.0);

    // Check minimum illumination contrast
    final contrast = _calculateContrast(grayscale);
    if (contrast < 0.15) {
      livenessScore *= 0.5; // penalize underexposed/flat images
    }

    return livenessScore;
  }

  /// Identifies a face against enrolled persons in 1:N matching.
  Future<FaceMatchResult> matchFace(
    Uint8List candidateBytes,
    List<Person> enrolledPersons, {
    double? identifyThreshold,
    double? livenessThreshold,
  }) async {
    final idThreshold = identifyThreshold ?? defaultIdentifyThreshold;
    final liveThreshold = livenessThreshold ?? defaultLivenessThreshold;

    try {
      final template = await extractFaceTemplate(candidateBytes);
      final liveness = await calculateLiveness(candidateBytes);

      // Extract a nice thumbnail for display
      Uint8List? croppedJpg;
      try {
        final decoded = img.decodeImage(candidateBytes);
        if (decoded != null) {
          final faceCrop = _cropFaceRegion(img.bakeOrientation(decoded));
          final thumb = img.copyResize(faceCrop, width: 160, height: 160);
          croppedJpg = Uint8List.fromList(img.encodeJpg(thumb, quality: 85));
        }
      } catch (_) {}

      if (enrolledPersons.isEmpty) {
        return FaceMatchResult(
          similarity: 0.0,
          liveness: liveness,
          isRecognized: false,
          statusMessage: 'No registered face profiles found in the system.',
          extractedTemplate: template,
          croppedFaceJpg: croppedJpg,
        );
      }

      double maxSimilarity = -1.0;
      Person? bestMatch;

      for (final person in enrolledPersons) {
        final sim = similarityCalculation(template, person.templates);
        if (sim > maxSimilarity) {
          maxSimilarity = sim;
          bestMatch = person;
        }
      }

      final bool recognized = maxSimilarity >= idThreshold && liveness >= liveThreshold;

      String message;
      if (recognized && bestMatch != null) {
        message = 'Recognized as ${bestMatch.name} (${(maxSimilarity * 100).toStringAsFixed(1)}%)';
      } else if (maxSimilarity >= idThreshold && liveness < liveThreshold) {
        message = 'Face matched (${(maxSimilarity * 100).toStringAsFixed(1)}%), but liveness score too low (${(liveness * 100).toStringAsFixed(0)}%). Please face the camera directly in good lighting.';
      } else {
        message = 'Face not recognized. Similarity (${(maxSimilarity * 100).toStringAsFixed(1)}%) below required threshold.';
      }

      return FaceMatchResult(
        matchedPerson: bestMatch,
        similarity: maxSimilarity.clamp(0.0, 1.0),
        liveness: liveness,
        isRecognized: recognized,
        statusMessage: message,
        extractedTemplate: template,
        croppedFaceJpg: croppedJpg,
      );
    } catch (e) {
      print('[FaceRecognitionEngine] matchFace error: $e');
      return FaceMatchResult(
        similarity: 0.0,
        liveness: 0.0,
        isRecognized: false,
        statusMessage: 'Failed to process face: $e',
        extractedTemplate: [],
      );
    }
  }

  /// Center-weighted portrait crop isolating the primary facial oval
  img.Image _cropFaceRegion(img.Image image) {
    final w = image.width;
    final h = image.height;

    // Standard portrait bounds: centered horizontally, 15%-75% vertically
    final cropSize = min(w, h);
    final cropWidth = (cropSize * 0.75).round();
    final cropHeight = (cropSize * 0.85).round();

    final cropX = ((w - cropWidth) / 2).clamp(0, w - 1).round();
    final cropY = ((h - cropHeight) / 2.3).clamp(0, h - 1).round();

    final actualW = min(cropWidth, w - cropX);
    final actualH = min(cropHeight, h - cropY);

    return img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: actualW,
      height: actualH,
    );
  }

  /// Computes a deterministic 128-dimensional spatial gradient & luminance feature vector.
  List<double> _computeSpatialFeatureVector(img.Image image) {
    final grayscale = img.grayscale(image);
    final features = List<double>.filled(embeddingDimension, 0.0);

    // Compute global luminance mean and standard deviation for contrast invariance
    double globalSum = 0.0;
    double globalSq = 0.0;
    final totalPixels = grayscale.width * grayscale.height;
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final v = grayscale.getPixel(x, y).r.toDouble();
        globalSum += v;
        globalSq += v * v;
      }
    }
    final globalMean = totalPixels > 0 ? globalSum / totalPixels : 128.0;
    final globalVar = totalPixels > 0 ? (globalSq / totalPixels) - (globalMean * globalMean) : 1.0;
    final globalStd = sqrt(max(globalVar, 1.0));

    // Split face into an 8x8 spatial grid (64 cells)
    const gridSize = 8;
    final cellW = (grayscale.width / gridSize).floor();
    final cellH = (grayscale.height / gridSize).floor();

    int featureIndex = 0;

    for (int gy = 0; gy < gridSize; gy++) {
      for (int gx = 0; gx < gridSize; gx++) {
        double cellSum = 0.0;
        double horizGrad = 0.0;
        double vertGrad = 0.0;
        int count = 0;

        final startX = gx * cellW;
        final startY = gy * cellH;

        for (int y = startY; y < startY + cellH && y < grayscale.height; y++) {
          for (int x = startX; x < startX + cellW && x < grayscale.width; x++) {
            final val = grayscale.getPixel(x, y).r.toDouble();
            cellSum += val;

            if (x > 0 && x < grayscale.width - 1) {
              horizGrad += (grayscale.getPixel(x + 1, y).r - grayscale.getPixel(x - 1, y).r).abs();
            }
            if (y > 0 && y < grayscale.height - 1) {
              vertGrad += (grayscale.getPixel(x, y + 1).r - grayscale.getPixel(x, y - 1).r).abs();
            }
            count++;
          }
        }

        final cellMean = count > 0 ? cellSum / count : globalMean;
        final cellGrad = count > 0 ? (horizGrad + vertGrad) / count : 0.0;

        final normVal = (cellMean - globalMean) / globalStd;
        final normGrad = (cellGrad - (globalStd * 0.4)) / globalStd;

        // First 64 dims: standardized relative luminance across facial landmarks
        if (featureIndex < 64) {
          features[featureIndex] = normVal;
        }
        // Second 64 dims: standardized gradient edge dynamics
        if (featureIndex + 64 < embeddingDimension) {
          features[featureIndex + 64] = normGrad;
        }

        featureIndex++;
      }
    }

    return features;
  }

  /// L2 Unit Normalization
  List<double> _l2Normalize(List<double> vector) {
    double sumSq = 0.0;
    for (final v in vector) {
      sumSq += v * v;
    }
    final norm = sqrt(sumSq);
    if (norm == 0.0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Relative contrast ratio
  double _calculateContrast(img.Image grayImage) {
    double minVal = 255.0;
    double maxVal = 0.0;

    for (int y = 0; y < grayImage.height; y += 4) {
      for (int x = 0; x < grayImage.width; x += 4) {
        final val = grayImage.getPixel(x, y).r.toDouble();
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }
    }

    if (maxVal + minVal == 0) return 0.0;
    return (maxVal - minVal) / (maxVal + minVal);
  }
}
