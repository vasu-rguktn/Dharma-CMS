// lib/screens/petitions/services/ocr_service.dart
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class OcrService {
  final Dio _dio = Dio();
  String _endpoint = '';
  final List<String> _fallbacks = [];

  Future<void> init() async {
    final candidates = <String>[];
    if (kIsWeb) {
      final u = Uri.base;
      final scheme = u.scheme.isEmpty ? 'http' : u.scheme;
      final host = u.host.isEmpty ? 'localhost' : u.host;
      candidates.add('$scheme://$host:8000');
      candidates.add('$scheme://$host');
    }
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      candidates.add('http://10.0.2.2:8000');
      candidates.add('http://10.0.2.2');
    }
    candidates.addAll(['http://localhost:8000', 'http://localhost']);

    String? base;
    for (final c in candidates) {
      if (await _isHealthy(c)) { base = c; break; }
    }
    base ??= candidates.first;

    _endpoint = '$base/api/ocr/extract';
    _fallbacks.addAll(['$base/api/ocr/extract-case/', '$base/extract-case/']);
  }

  Future<bool> _isHealthy(String base) async {
    final paths = ['/api/ocr/health', '/api/health', '/ocr/health', '/', '/Root'];
    for (final p in paths) {
      try {
        final r = await _dio.get('$base$p', options: Options(receiveTimeout: const Duration(seconds: 3), sendTimeout: const Duration(seconds: 3), validateStatus: (_) => true));
        if (r.statusCode! >= 200 && r.statusCode! < 400) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<String?> extractText(PlatformFile file) async {
    if (_endpoint.isEmpty) await init();
    if (file.size == 0) throw Exception('File empty');
    if (file.size > 5 * 1024 * 1024) throw Exception('File too large');

    final mFile = file.bytes != null
        ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
        : await MultipartFile.fromFile(file.path!, filename: file.name);

    final form = FormData.fromMap({'file': mFile});
    final endpoints = [_endpoint, ..._fallbacks];
    DioException? lastErr;

    for (final e in endpoints) {
      try {
        final resp = await _dio.post(e, data: form, options: Options(receiveTimeout: const Duration(seconds: 60), sendTimeout: const Duration(seconds: 60), followRedirects: false, validateStatus: (c) => c! >= 200 && c < 400));
        final text = (resp.data['text'] as String?)?.trim();
        return text?.isNotEmpty == true ? text : null;
      } on DioException catch (e) {
        lastErr = e;
        if (e.response?.statusCode == null) await init();
      }
    }
    throw lastErr ?? Exception('OCR failed');
  }
}