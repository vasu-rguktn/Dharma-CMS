import 'package:dio/dio.dart';
import 'package:dharma_police/core/api_service.dart';

/// AI Gateway API — police-specific AI features via the backend proxy.
class AiGatewayApi {
  static final _dio = ApiService.dio;

  // ── Chargesheet Generation ──
  static Future<Map<String, dynamic>> generateChargesheet({
    String? incidentText,
    String? stationName,
    String? caseId,
    String? additionalInstructions,
  }) async {
    final formData = FormData.fromMap({
      'incident_text': incidentText ?? '',
      'station_name': stationName ?? '',
      'case_id': caseId ?? '',
      'additional_instructions': additionalInstructions ?? '',
    });
    final r = await _dio.post('/ai/chargesheet-generation', data: formData);
    return r.data;
  }

  // ── Chargesheet Vetting ──
  static Future<Map<String, dynamic>> vetChargesheet({
    String? chargesheetText,
    String? additionalInstructions,
  }) async {
    final formData = FormData.fromMap({
      'chargesheet_text': chargesheetText ?? '',
      'additional_instructions': additionalInstructions ?? '',
    });
    final r = await _dio.post('/ai/chargesheet-vetting', data: formData);
    return r.data;
  }

  // ── Document Drafting ──
  static Future<Map<String, dynamic>> draftDocument({
    String? caseData,
    String? recipientType,
    String? additionalInstructions,
  }) async {
    final formData = FormData.fromMap({
      'case_data': caseData ?? '',
      'recipient_type': recipientType ?? '',
      'additional_instructions': additionalInstructions ?? '',
    });
    final r = await _dio.post('/ai/document-drafting', data: formData);
    return r.data;
  }

  // ── AI Investigation Guidelines ──
  static Future<Map<String, dynamic>> getInvestigationGuidelines(Map<String, dynamic> body) async {
    final r = await _dio.post('/ai/ai-investigation', data: body);
    return r.data;
  }

  // ── Investigation Report ──
  static Future<Map<String, dynamic>> generateInvestigationReport(Map<String, dynamic> body) async {
    final r = await _dio.post('/ai/investigation-report', data: body);
    return r.data;
  }

  // ── Media Analysis ──
  static Future<Map<String, dynamic>> analyzeMedia({
    required List<int> fileBytes,
    required String fileName,
    String analysisType = 'general',
    String? additionalInstructions,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'analysis_type': analysisType,
      'additional_instructions': additionalInstructions ?? '',
    });
    final r = await _dio.post('/ai/media-analysis', data: formData);
    return r.data;
  }

  // ── Legal Chat (shared) ──
  static Future<Map<String, dynamic>> legalChat({
    String? sessionId,
    required String message,
    String language = 'en',
  }) async {
    final formData = FormData.fromMap({
      'sessionId': sessionId ?? '',
      'message': message,
      'language': language,
    });
    final r = await _dio.post('/ai/legal-chat', data: formData);
    return r.data;
  }

  // ── Translation ──
  static Future<Map<String, dynamic>> translate(Map<String, dynamic> body) async {
    final r = await _dio.post('/ai/translate', data: body);
    return r.data;
  }
}
