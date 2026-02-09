import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:http_parser/http_parser.dart';

class OcrService {
  final Dio _dio = Dio();
  String _endpoint = '';
  final List<String> _fallbackEndpoints = [];

  bool isExtracting = false;
  Map<String, dynamic>? result;

  Future<void> init() async {
    // 1. Prioritize Production URL immediately to avoid timeouts
    const productionUrl =
        'https://fastapi-app-335340524683.asia-south1.run.app';

    if (kIsWeb) {
      // On Web (Release), just use the production URL directly to avoid "Connection refused" logs
      // from probing localhost.
      if (const bool.fromEnvironment('dart.vm.product')) {
        _endpoint = '$productionUrl/api/ocr/extract';
        _fallbackEndpoints.clear();
        _fallbackEndpoints.add('$productionUrl/extract-case/');
        return;
      }
    }

    final candidates = <String>[];

    // Add production URL first
    candidates.add(productionUrl);

    if (kIsWeb) {
      // Only check localhost in debug mode
      if (!const bool.fromEnvironment('dart.vm.product')) {
        final uri = Uri.base;
        final host = uri.host.isNotEmpty ? uri.host : 'localhost';
        candidates.add('http://$host:8000');
        candidates.add('http://$host:8080');
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator
      candidates.add('http://10.0.2.2:8000');
    }

    // Default localhost fallbacks
    candidates.add('http://localhost:8000');
    candidates.add('http://localhost:8080');

    String? resolved;
    for (final base in candidates) {
      if (await _isHealthy(base)) {
        resolved = base;
        break;
      }
    }
    resolved ??= candidates.first;

    _endpoint = '$resolved/api/ocr/extract';
    _fallbackEndpoints.clear();
    _fallbackEndpoints.addAll([
      '$resolved/api/ocr/extract-case/',
      '$resolved/extract-case/',
    ]);
  }

  Future<bool> _isHealthy(String base) async {
    final paths = [
      '/api/ocr/health',
      '/api/health',
      '/ocr/health',
      '/',
      '/Root'
    ];
    for (final p in paths) {
      try {
        final resp = await _dio.get('$base$p',
            options: Options(
              receiveTimeout: const Duration(seconds: 2), // Short timeout
              sendTimeout: const Duration(seconds: 2),
            ));
        if (resp.statusCode! >= 200 && resp.statusCode! < 400) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<void> runOcr(PlatformFile file) async {
    if (isExtracting) return;
    isExtracting = true;
    result = null;

    try {
      if (_endpoint.isEmpty) await init();
      if (file.size <= 0) throw Exception('Empty file');
      if (file.size > 5 * 1024 * 1024) throw Exception('File > 5MB');

      // Detect MIME type (default to application/octet-stream if unknown)
      // This prevents "Method not found: 'au'" errors on Web if contentType is null/ambiguous
      MediaType mediaType = MediaType('application', 'octet-stream');

      final ext = file.extension?.toLowerCase() ??
          (file.name.contains('.')
              ? file.name.split('.').last.toLowerCase()
              : '');

      if (ext == 'pdf') {
        mediaType = MediaType('application', 'pdf');
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      }

      final mFile = file.bytes != null
          ? MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
              contentType: mediaType,
            )
          : await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
              contentType: mediaType,
            );

      final formData = FormData.fromMap({'file': mFile});

      Response? resp;
      final endpoints = [_endpoint, ..._fallbackEndpoints];
      DioException? lastErr;

      for (final url in endpoints) {
        try {
          debugPrint('OCR attempting: $url');
          resp = await _dio.post(url,
              data: formData,
              options: Options(
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 60),
              ));
          if (resp.statusCode != null &&
              resp.statusCode! >= 200 &&
              resp.statusCode! < 400) {
            break;
          }
        } on DioException catch (e) {
          debugPrint('OCR failed for $url: ${e.message}');
          lastErr = e;
        }
      }

      if (resp == null)
        throw lastErr ?? Exception('OCR failed on all endpoints');

      final data = Map<String, dynamic>.from(resp.data);
      final text = (data['text'] as String?)?.trim() ?? '';

      result = text.isNotEmpty ? {'text': text} : null;
    } catch (e) {
      debugPrint('OCR Critical Error: $e');
      result = null;
      rethrow;
    } finally {
      isExtracting = false;
    }
  }

  void clearResult() => result = null;
}
