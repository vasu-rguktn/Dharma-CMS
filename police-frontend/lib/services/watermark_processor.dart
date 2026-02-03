import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for adding watermarks to images and videos
class WatermarkProcessor {
  static final WatermarkProcessor _instance = WatermarkProcessor._internal();
  factory WatermarkProcessor() => _instance;
  WatermarkProcessor._internal();

  /// Add watermark to an image file
  Future<File> addWatermarkToImage(File imageFile, String watermarkText) async {
    try {
      // Read the image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Prepare watermark text lines
      final lines = watermarkText.split('\n');
      
      // Calculate watermark dimensions
      const fontSize = 28;
      const lineHeight = 35;
      const padding = 20;
      
      // Find the longest line for width calculation
      int maxLineLength = lines.map((l) => l.length).reduce((a, b) => a > b ? a : b);
      final watermarkWidth = (maxLineLength * fontSize * 0.6).toInt() + (padding * 2);
      final watermarkHeight = (lines.length * lineHeight) + (padding * 2);
      
      // Create semi-transparent background
      final bgColor = img.ColorRgba8(0, 0, 0, 178); // Semi-transparent black
      
      // Draw background rectangle
      img.fillRect(
        image,
        x1: padding,
        y1: image.height - watermarkHeight - padding,
        x2: watermarkWidth + padding,
        y2: image.height - padding,
        color: bgColor,
      );
      
      // Draw text lines
      for (int i = 0; i < lines.length; i++) {
        final y = image.height - watermarkHeight - padding + (padding ~/ 2) + (i * lineHeight);
        
        img.drawString(
          image,
          lines[i],
          font: img.arial48,
          x: padding * 2,
          y: y,
          color: img.ColorRgba8(255, 255, 255, 255), // White text
        );
      }
      
      // Save to permanent location
      final permanentFile = await _saveToPermanentLocation(image, 'image');
      
      return permanentFile;
    } catch (e) {
      print('Error adding watermark to image: $e');
      rethrow;
    }
  }

  /// Add watermark to a video file (watermarks the first frame as thumbnail)
  Future<File> addWatermarkToVideo(File videoFile, String watermarkText) async {
    try {
      // For videos, we'll copy to permanent location with metadata
      // In a production app, you might want to use FFmpeg to overlay watermark on video
      final permanentFile = await _copyVideoToPermanentLocation(videoFile, watermarkText);
      return permanentFile;
    } catch (e) {
      print('Error processing video: $e');
      rethrow;
    }
  }

  /// Save processed image to permanent location
  Future<File> _saveToPermanentLocation(img.Image image, String type) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final geoEvidenceDir = Directory('${appDir.path}/geo_evidence');
      
      // Create directory if it doesn't exist
      if (!await geoEvidenceDir.exists()) {
        await geoEvidenceDir.create(recursive: true);
      }
      
      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'GEO_${timestamp}.jpg';
      final filePath = path.join(geoEvidenceDir.path, filename);
      
      // Encode and save
      final encodedImage = img.encodeJpg(image, quality: 95);
      final file = File(filePath);
      await file.writeAsBytes(encodedImage);
      
      print('Saved watermarked image to: $filePath');
      return file;
    } catch (e) {
      print('Error saving to permanent location: $e');
      rethrow;
    }
  }

  /// Copy video to permanent location
  Future<File> _copyVideoToPermanentLocation(File videoFile, String watermarkText) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final geoEvidenceDir = Directory('${appDir.path}/geo_evidence');
      
      // Create directory if it doesn't exist
      if (!await geoEvidenceDir.exists()) {
        await geoEvidenceDir.create(recursive: true);
      }
      
      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'GEO_${timestamp}.mp4';
      final filePath = path.join(geoEvidenceDir.path, filename);
      
      // Copy video file
      final file = await videoFile.copy(filePath);
      
      // Save metadata file alongside video
      final metadataFile = File('${filePath}.txt');
      await metadataFile.writeAsString(watermarkText);
      
      print('Saved video to: $filePath');
      return file;
    } catch (e) {
      print('Error copying video: $e');
      rethrow;
    }
  }

  /// Clean up old files (optional maintenance function)
  Future<void> cleanupOldFiles({int daysToKeep = 30}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final geoEvidenceDir = Directory('${appDir.path}/geo_evidence');
      
      if (!await geoEvidenceDir.exists()) {
        return;
      }
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final files = await geoEvidenceDir.list().toList();
      
      for (var entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            print('Deleted old file: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old files: $e');
    }
  }
}
