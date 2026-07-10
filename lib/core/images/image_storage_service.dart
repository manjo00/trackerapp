import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_filename.dart';

/// Copies picked images into `<appDocs>/note_images/` and resolves them back.
///
/// Only the filename is persisted (in `note_blocks.content`); the absolute path
/// is rebuilt at display time because the app-documents path can change between
/// installs. Reusable beyond notes (future task attachments, notebook logos).
class ImageStorageService {
  static const String _subdir = 'note_images';
  final ImagePicker _picker = ImagePicker();

  Future<Directory> _dir() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, _subdir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Picks one image and copies its bytes into storage.
  ///
  /// Returns the generated filename, or null if the user cancelled. Downscales
  /// very large captures (maxWidth) to keep on-device storage reasonable.
  Future<String?> pickAndStore(ImageSource source) async {
    final XFile? picked =
        await _picker.pickImage(source: source, maxWidth: 2000);
    if (picked == null) return null;
    final Directory dir = await _dir();
    final String rawExt = p.extension(picked.path).replaceFirst('.', '');
    final String filename = buildImageFilename(
      seed: DateTime.now().microsecondsSinceEpoch,
      extension: rawExt.isEmpty ? 'jpg' : rawExt,
    );
    await File(picked.path).copy(p.join(dir.path, filename));
    return filename;
  }

  /// Absolute path for a stored [filename] (for `Image.file`).
  Future<String> resolvePath(String filename) async {
    final Directory dir = await _dir();
    return p.join(dir.path, filename);
  }

  /// Whether the backing file still exists (drives the "unavailable" fallback).
  Future<bool> exists(String filename) async =>
      File(await resolvePath(filename)).exists();

  /// Best-effort delete; a missing file is not an error.
  Future<void> delete(String filename) async {
    final File f = File(await resolvePath(filename));
    if (await f.exists()) await f.delete();
  }
}
