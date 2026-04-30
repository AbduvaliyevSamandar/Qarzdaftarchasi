import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  static const _uuid = Uuid();
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndStore({required ImageSource source}) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (file == null) return null;
    final dir = await _photosDir();
    final ext = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final path = p.join(dir.path, '${_uuid.v4()}$ext');
    final saved = await File(file.path).copy(path);
    return saved.path;
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<Directory> _photosDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'customer_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
