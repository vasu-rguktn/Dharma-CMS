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

      // Try to preserve a reasonable content type and mark as inline so that
      // supported types (audio, video, PDF, images) can be streamed/viewed
      // instead of always being downloaded.
      String contentType = 'application/octet-stream';
      final ext = file.extension?.toLowerCase();
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
        case 'wav':
          contentType = 'audio/wav';
          break;
        case 'mp4':
          contentType = 'video/mp4';
          break;
        default:
          break;
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        contentDisposition: 'inline',
      );

      if (kIsWeb) {
        if (file.bytes == null) return null;
        uploadTask = ref.putData(file.bytes!, metadata);
      } else {
        if (file.path == null) return null;
        uploadTask = ref.putFile(File(file.path!), metadata);
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
      // Generate readable timestamp: 2025-12-13_14-05-08
      final timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      final String fileName = 'Proof_${timestamp}_${file.name}';
      final String path = '$folderPath/$fileName';

      final String? url = await uploadFile(file: file, path: path);
      if (url != null) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }
}
