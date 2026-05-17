import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  Future<String> saveToPrivateStorage(String sourcePath) async {
    if (sourcePath.isEmpty) return '';
    final source = File(sourcePath);
    if (!await source.exists()) return '';
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'mistake_images'));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
    final ext =
        p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
    final target = File(p.join(imagesDir.path, '${const Uuid().v4()}$ext'));
    await source.copy(target.path);
    return target.path;
  }
}
