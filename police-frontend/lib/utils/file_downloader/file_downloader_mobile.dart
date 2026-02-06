import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Downloads a file to the Downloads folder (visible in file manager)
/// Returns the file path if successful, null otherwise
/// Now uses platform channel for proper MediaStore integration on Android
Future<String?> downloadFile(List<int> bytes, String fileName) async {
  try {
    developer.log('=== Dart: Starting file download ===',
        name: 'DharmaDownload');
    developer.log('File: $fileName, Size: ${bytes.length} bytes',
        name: 'DharmaDownload');

    if (Platform.isAndroid) {
      developer.log('Platform: Android - Using native channel',
          name: 'DharmaDownload');

      const platform = MethodChannel('com.dharma.file_download');

      try {
        developer.log('Invoking saveToDownloads method',
            name: 'DharmaDownload');
        final String? result = await platform.invokeMethod('saveToDownloads', {
          'bytes': Uint8List.fromList(bytes),
          'fileName': fileName,
        });

        if (result != null) {
          developer.log('SUCCESS: File saved to: $result',
              name: 'DharmaDownload');
          developer.log('=== Dart: Download complete ===',
              name: 'DharmaDownload');
          return result;
        } else {
          developer.log('ERROR: Platform returned null',
              name: 'DharmaDownload');
          return null;
        }
      } on PlatformException catch (e) {
        developer.log(
            'ERROR: PlatformException - Code: ${e.code}, Message: ${e.message}',
            name: 'DharmaDownload');
        developer.log('Details: ${e.details}', name: 'DharmaDownload');
        return null;
      } catch (e) {
        developer.log('ERROR: Unexpected error: $e', name: 'DharmaDownload');
        return null;
      }
    } else {
      // iOS or other platforms - keep original implementation
      developer.log('Platform: iOS/Other - Not implemented',
          name: 'DharmaDownload');
      return null;
    }
  } catch (e) {
    developer.log('ERROR: Top-level exception: $e', name: 'DharmaDownload');
    return null;
  }
}
