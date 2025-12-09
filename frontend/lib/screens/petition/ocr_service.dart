
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class OcrService {
  final Dio _dio = Dio();
  String _endpoint = '';
  final List<String> _fallbackEndpoints = [];

  bool isExtracting = false;
  Map<String, dynamic>? result;

  Future<void> init() async {
    final candidates = <String>[];

    if (kIsWeb) {
      final uri = Uri.base;
      final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'http';
      final host = uri.host.isNotEmpty ? uri.host : 'localhost';
      candidates.add('$scheme://$host:8000');
      candidates.add('$scheme://$host');
    }

    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      // candidates.add('http://10.0.2.2:8000');
      // candidates.add('http://10.0.2.2');
      candidates.add('https://dharma-backend-x1g4.onrender.com');

    }

    candidates.add('https://dharma-backend-x1g4.onrender.com');
    candidates.add('http://localhost');

    String? resolved;
    for (final base in candidates) {
      if (await _isHealthy(base)) {
        resolved = base;
        break;
      }
    }
    resolved ??= candidates.first;

    _endpoint = '$resolved/api/ocr/extract';
    _fallbackEndpoints.addAll([
      '$resolved/api/ocr/extract-case/',
      '$resolved/extract-case/',
    ]);
  }

  Future<bool> _isHealthy(String base) async {
    final paths = ['/api/ocr/health', '/api/health', '/ocr/health', '/', '/Root'];
    for (final p in paths) {
      try {
        final resp = await _dio.get('$base$p',
            options: Options(
              receiveTimeout: const Duration(seconds: 3),
              sendTimeout: const Duration(seconds: 3),
              validateStatus: (_) => true,
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

      final mFile = file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name);

      final formData = FormData.fromMap({'file': mFile});

      Response? resp;
      final endpoints = [_endpoint, ..._fallbackEndpoints];
      DioException? lastErr;

      for (final url in endpoints) {
        try {
          resp = await _dio.post(url,
              data: formData,
              options: Options(
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 60),
                followRedirects: false,
                validateStatus: (c) => c != null && c >= 200 && c < 400,
              ));
          break;
        } on DioException catch (e) {
          lastErr = e;
          if (e.response?.statusCode == null) await init();
        }
      }

      if (resp == null) throw lastErr ?? Exception('OCR failed');

      final data = Map<String, dynamic>.from(resp.data);
      final text = (data['text'] as String?)?.trim() ?? '';

      result = text.isNotEmpty ? {'text': text} : null;
    } catch (e) {
      result = null;
      throw e;
    } finally {
      isExtracting = false;
    }
  }

  void clearResult() => result = null;
}