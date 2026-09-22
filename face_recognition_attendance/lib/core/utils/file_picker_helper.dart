import 'app_picked_file.dart';
import 'file_picker_helper_io.dart'
    if (dart.library.js_interop) 'file_picker_helper_web.dart' as impl;

export 'app_picked_file.dart';

class AppFilePicker {
  /// Picks a single file across Web and Native (Android/iOS/Desktop).
  ///
  /// For documents and general attachments:
  /// [allowedExtensions] e.g. `['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'webp']`
  ///
  /// For images only:
  /// Set [isImageOnly] to true.
  static Future<AppPickedFile?> pickFile({
    List<String>? allowedExtensions,
    bool isImageOnly = false,
  }) async {
    return await impl.pickFileImpl(
      allowedExtensions: allowedExtensions,
      isImageOnly: isImageOnly,
    );
  }
}
