import 'dart:typed_data';

class AppPickedFile {
  final String name;
  final Uint8List bytes;
  final int size;
  final String? extension;
  final String? path;

  AppPickedFile({
    required this.name,
    required this.bytes,
    required this.size,
    this.extension,
    this.path,
  });
}
