import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static const String _uploadsFolderName = 'uploaded_Document';

  static Future<Directory> _ensureUploadsRoot() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory uploadsRoot = Directory('${appDocDir.path}/$_uploadsFolderName');
    if (!await uploadsRoot.exists()) {
      await uploadsRoot.create(recursive: true);
    }
    return uploadsRoot;
  }

  static Future<Directory> ensureUploadsSubfolder(String subfolderName) async {
    final Directory root = await _ensureUploadsRoot();
    final Directory sub = Directory('${root.path}/$subfolderName');
    if (!await sub.exists()) {
      await sub.create(recursive: true);
    }
    return sub;
  }

  static Future<List<String>> savePickedFiles({
    required List<PlatformFile> files,
    String? subfolderName,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Local file saving is not supported on web');
    }

    final Directory targetDir = subfolderName == null
        ? await _ensureUploadsRoot()
        : await ensureUploadsSubfolder(_sanitize(subfolderName));

    final List<String> savedPaths = <String>[];

    for (final PlatformFile file in files) {
      final String safeName = _uniqueSafeFileName(targetDir, file.name);
      final File dest = File('${targetDir.path}/$safeName');

      if (file.bytes != null) {
        await dest.writeAsBytes(file.bytes!);
      } else if (file.path != null) {
        final File src = File(file.path!);
        await src.copy(dest.path);
      } else {
        continue;
      }

      savedPaths.add(dest.path);
    }

    return savedPaths;
  }

  static String _uniqueSafeFileName(Directory dir, String originalName) {
    final String base = _sanitize(originalName);
    String candidate = base;
    int counter = 1;
    while (File('${dir.path}/$candidate').existsSync()) {
      final int dot = base.lastIndexOf('.');
      if (dot > 0) {
        final String name = base.substring(0, dot);
        final String ext = base.substring(dot);
        candidate = '${name}_$counter$ext';
      } else {
        candidate = '${base}_$counter';
      }
      counter += 1;
    }
    return candidate;
  }

  static String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}


