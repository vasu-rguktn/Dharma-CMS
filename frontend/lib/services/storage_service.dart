import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadFile({
    required PlatformFile file,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      UploadTask uploadTask;

      if (kIsWeb) {
        if (file.bytes == null) return null;
        uploadTask = ref.putData(file.bytes!);
      } else {
        if (file.path == null) return null;
        uploadTask = ref.putFile(File(file.path!));
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  static Future<List<String>> uploadMultipleFiles({
    required List<PlatformFile> files,
    required String folderPath,
  }) async {
    List<String> downloadUrls = [];

    for (var file in files) {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final String path = '$folderPath/$fileName';

      final String? url = await uploadFile(file: file, path: path);
      if (url != null) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }
}
