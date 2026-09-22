import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'app_picked_file.dart';

Future<AppPickedFile?> pickFileImpl({
  List<String>? allowedExtensions,
  bool isImageOnly = false,
}) async {
  final completer = Completer<AppPickedFile?>();
  final uploadInput = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = false
    ..style.display = 'none';

  if (isImageOnly) {
    uploadInput.accept = 'image/*';
  } else if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
    uploadInput.accept = allowedExtensions.map((e) => '.$e').join(',');
  }

  void cleanup() {
    uploadInput.remove();
  }

  uploadInput.addEventListener(
    'change',
    ((web.Event e) {
      final files = uploadInput.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        cleanup();
        return;
      }

      final file = files.item(0);
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        cleanup();
        return;
      }

      final reader = web.FileReader();
      reader.addEventListener(
        'loadend',
        ((web.Event _) {
          final byteBuffer = (reader.result as JSArrayBuffer?)?.toDart;
          final bytes = byteBuffer?.asUint8List() ?? Uint8List(0);
          final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : null;

          if (!completer.isCompleted) {
            completer.complete(AppPickedFile(
              name: file.name,
              bytes: bytes,
              size: file.size,
              extension: ext,
              path: null,
            ));
          }
          cleanup();
        }).toJS,
      );

      reader.addEventListener(
        'error',
        ((web.Event _) {
          if (!completer.isCompleted) completer.complete(null);
          cleanup();
        }).toJS,
      );

      reader.readAsArrayBuffer(file);
    }).toJS,
  );

  uploadInput.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
      cleanup();
    }).toJS,
  );

  web.document.body?.appendChild(uploadInput);
  uploadInput.click();

  return completer.future;
}
