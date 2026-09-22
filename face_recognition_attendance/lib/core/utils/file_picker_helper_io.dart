import 'package:file_picker/file_picker.dart';
import 'app_picked_file.dart';

Future<AppPickedFile?> pickFileImpl({
  List<String>? allowedExtensions,
  bool isImageOnly = false,
}) async {
  FileType type = FileType.any;
  if (isImageOnly) {
    type = FileType.image;
  } else if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
    type = FileType.custom;
  }

  final picked = await FilePicker.pickFile(
    type: type,
    allowedExtensions: type == FileType.custom ? allowedExtensions : null,
  );

  if (picked == null) {
    return null;
  }

  final bytes = await picked.readAsBytes();
  final size = await picked.length() ?? bytes.lengthInBytes;

  return AppPickedFile(
    name: picked.name,
    bytes: bytes,
    size: size,
    extension: picked.extension,
    path: picked.path,
  );
}
