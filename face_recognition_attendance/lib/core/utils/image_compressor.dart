import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Cross-platform lightweight image compressor.
/// Prevents base64 image strings from exceeding the browser 5MB localStorage quota on Flutter Web.
class ImageCompressor {
  /// Compresses raw image bytes to a high-quality, lightweight JPEG thumbnail.
  static Uint8List compressImageBytes(
    Uint8List rawBytes, {
    int maxDimension = 200,
    int quality = 80,
  }) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      img.Image processed = decoded;
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        processed = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
          interpolation: img.Interpolation.linear,
        );
      }

      final jpgBytes = img.encodeJpg(processed, quality: quality);
      return Uint8List.fromList(jpgBytes);
    } catch (_) {
      return rawBytes;
    }
  }

  /// Compresses a data URI or base64 string down to a compact data URI.
  static String compressBase64(
    String dataUriOrBase64, {
    int maxDimension = 200,
    int quality = 80,
  }) {
    if (dataUriOrBase64.isEmpty) return dataUriOrBase64;
    try {
      String cleanBase64 = dataUriOrBase64;
      if (dataUriOrBase64.contains(',')) {
        cleanBase64 = dataUriOrBase64.split(',')[1];
      }
      final raw = base64Decode(cleanBase64.trim());
      // If already small (< 25KB), no compression needed
      if (raw.lengthInBytes <= 25 * 1024) {
        return dataUriOrBase64.startsWith('data:')
            ? dataUriOrBase64
            : 'data:image/jpeg;base64,$cleanBase64';
      }

      final compressed = compressImageBytes(
        raw,
        maxDimension: maxDimension,
        quality: quality,
      );
      final newBase64 = base64Encode(compressed);
      return 'data:image/jpeg;base64,$newBase64';
    } catch (_) {
      return dataUriOrBase64;
    }
  }

  /// Specifically optimizes profile pictures for crisp retina avatars (~10-15KB).
  static String compressProfilePicture(String dataUriOrBase64) {
    return compressBase64(dataUriOrBase64, maxDimension: 200, quality: 82);
  }

  /// Specifically optimizes face reference snapshots for biometric storage (~5-10KB).
  static Uint8List compressFaceReference(Uint8List rawBytes) {
    return compressImageBytes(rawBytes, maxDimension: 160, quality: 75);
  }
}
