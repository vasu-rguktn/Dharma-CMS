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

      // Ensure we have a valid name and extension for the rules to check
      String fileName = file.name.trim().isEmpty ? 'upload_${DateTime.now().millisecondsSinceEpoch}' : file.name;
      String ext = (file.extension ?? (fileName.contains('.') ? fileName.split('.').last : '')).toLowerCase();
      
      // Fallback for missing extension
      if (ext.isEmpty && file.bytes != null) {
        // If it's a large blob without extension, usually it's an image/video in this app
        ext = 'jpg'; 
        fileName += '.jpg';
      }

      String contentType = 'application/octet-stream';
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'heic':
          contentType = 'image/heic';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xls':
          contentType = 'application/vnd.ms-excel';
          break;
        case 'xlsx':
          contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'ppt':
          contentType = 'application/vnd.ms-powerpoint';
          break;
        case 'pptx':
          contentType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
          break;
        case 'csv':
          contentType = 'text/csv';
          break;
        case 'txt':
          contentType = 'text/plain';
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
        case 'mov':
          contentType = 'video/quicktime';
          break;
        case 'avi':
          contentType = 'video/x-msvideo';
          break;
        default:
          break;
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        contentDisposition: 'inline',
      );

      print('🚀 [UPLOAD] Starting upload for $fileName (Web: $kIsWeb)');
      if (kIsWeb) {
        if (file.bytes == null) {
          print('❌ [UPLOAD] Web upload failed: file.bytes is null');
          return null;
        }
        print('📦 [UPLOAD] Uploading ${file.bytes!.length} bytes');
        uploadTask = ref.putData(file.bytes!, metadata);
      } else {
        if (file.path == null) {
          print('❌ [UPLOAD] Mobile upload failed: file.path is null');
          return null;
        }
        print('📂 [UPLOAD] Uploading from path: ${file.path}');
        uploadTask = ref.putFile(File(file.path!), metadata);
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      print('✅ [UPLOAD] Success: $url');
      return url;
    } catch (e) {
      print('❌ [UPLOAD] Error uploading file: $e');
      if (kIsWeb) {
        print('⚠️ [UPLOAD] Hint: If this is a CORS error, you need to configure CORS for your Firebase Storage bucket.');
      }
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
