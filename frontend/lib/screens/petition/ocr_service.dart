import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:Dharma/services/api_service.dart';

class OcrService {
  Dio get _dio => ApiService.dio;
  String _endpoint = '';
  final List<String> _fallbackEndpoints = [];

  bool isExtracting = false;
  Map<String, dynamic>? result;

  Future<void> init() async {
    _endpoint = '/ai/ocr/extract';
    _fallbackEndpoints.clear();
    _fallbackEndpoints.addAll([
      '/api/ocr/extract',
      '/api/ocr/extract-case/',
      '/extract-case/',
    ]);
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
          // debugPrint('OCR attempting: $url');
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
          // debugPrint('OCR failed for $url: ${e.message}');
          lastErr = e;
        }
      }

      if (resp == null)
        throw lastErr ?? Exception('OCR failed on all endpoints');

      final data = Map<String, dynamic>.from(resp.data);
      final text = (data['text'] as String?)?.trim() ?? '';

      result = text.isNotEmpty ? {'text': text} : null;
    } catch (e) {
      // debugPrint('OCR Critical Error: $e');
      result = null;
      rethrow;
    } finally {
      isExtracting = false;
    }
  }

  void clearResult() => result = null;
}
