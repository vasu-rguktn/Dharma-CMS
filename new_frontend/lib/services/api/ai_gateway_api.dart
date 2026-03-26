/// AI Gateway API — all AI model calls are routed through the backend.
///
library;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dharma/core/api_service.dart';

class AiGatewayApi {
  AiGatewayApi._();
  static Dio get _dio => ApiService.dio;

  // ── Complaint Chatbot ──
  static Future<Map<String, dynamic>> complaintChatStep({
    required String fullName,
    required String address,
    required String phone,
    required String complaintType,
    required String initialDetails,
    required String language,
    required String chatHistory,
    bool isAnonymous = false,
    List<PlatformFile>? files,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('full_name', fullName),
      MapEntry('address', address),
      MapEntry('phone', phone),
      MapEntry('complaint_type', complaintType),
      MapEntry('initial_details', initialDetails),
      MapEntry('language', language),
      MapEntry('is_anonymous', isAnonymous.toString()),
      MapEntry('chat_history', chatHistory),
    ]);
    if (files != null) {
      for (final file in files) {
        if (file.bytes != null) {
          formData.files.add(MapEntry('files', MultipartFile.fromBytes(file.bytes!, filename: file.name)));
        }
      }
    }
    final res = await _dio.post('/ai/complaint/chat-step', data: formData);
    return res.data;
  }

  // ── Legal Chat ──
  static Future<Map<String, dynamic>> legalChat({
    required String sessionId,
    required String message,
    String language = 'en',
    List<Map<String, dynamic>>? attachments,
  }) async {
    final formData = FormData.fromMap({
      'sessionId': sessionId,
      'message': message,
      'language': language,
    });
    if (attachments != null) {
      for (final file in attachments) {
        final bytes = file['bytes'];
        final name = file['name'] as String;
        if (bytes != null) {
          formData.files.add(MapEntry('files', MultipartFile.fromBytes(bytes, filename: name)));
        }
      }
    }
    final res = await _dio.post('/ai/legal-chat', data: formData);
    return res.data;
  }

  // ── Legal Suggestions (IPC/BNS) ──
  static Future<Map<String, dynamic>> legalSuggestions({
    required String incidentDescription,
    String language = 'en',
  }) async {
    final res = await _dio.post('/ai/legal-suggestions', data: {
      'incident_description': incidentDescription,
      'language': language,
    });
    return res.data;
  }

  // ── OCR ──
  static Future<Map<String, dynamic>> ocrExtract(PlatformFile file) async {
    final formData = FormData();
    if (file.bytes != null) {
      formData.files.add(MapEntry('file', MultipartFile.fromBytes(file.bytes!, filename: file.name)));
    }
    final res = await _dio.post('/ai/ocr/extract', data: formData);
    return res.data;
  }

  // ── PDF Generation ──
  static Future<Map<String, dynamic>> generateSummaryPdf({
    required Map<String, dynamic> answers,
    required String summary,
    required String classification,
  }) async {
    final res = await _dio.post('/ai/generate-chatbot-summary-pdf', data: {
      'answers': answers,
      'summary': summary,
      'classification': classification,
    });
    return res.data;
  }

  // ── Witness Preparation ──
  static Future<Map<String, dynamic>> witnessPreparation({
    required String caseDetails,
    required String witnessStatement,
    required String witnessName,
  }) async {
    final res = await _dio.post('/ai/witness-preparation', data: {
      'caseDetails': caseDetails,
      'witnessStatement': witnessStatement,
      'witnessName': witnessName,
    });
    return res.data;
  }

  // ── FCM Token Registration ──
  static Future<void> registerFcmToken(String token) async {
    await _dio.post('/ai/fcm/register', data: {'token': token});
  }

  static Future<void> unregisterFcmToken(String token) async {
    await _dio.post('/ai/fcm/unregister', data: {'token': token});
  }

  // ══════════════════════════════════════════════════════════════════
  //  POLICE-ONLY AI ENDPOINTS
  // ══════════════════════════════════════════════════════════════════

  // ── Chargesheet Generation ──
  static Future<Map<String, dynamic>> generateChargesheet({
    String incidentText = '',
    String additionalInstructions = '',
    String stationName = '',
    String caseId = '',
    PlatformFile? firFile,
    PlatformFile? incidentFile,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('incident_text', incidentText),
      MapEntry('additional_instructions', additionalInstructions),
      MapEntry('station_name', stationName),
      MapEntry('case_id', caseId),
    ]);
    if (firFile?.bytes != null) {
      formData.files.add(MapEntry('fir_file', MultipartFile.fromBytes(firFile!.bytes!, filename: firFile.name)));
    }
    if (incidentFile?.bytes != null) {
      formData.files.add(MapEntry('incident_file', MultipartFile.fromBytes(incidentFile!.bytes!, filename: incidentFile.name)));
    }
    final res = await _dio.post('/ai/chargesheet-generation', data: formData);
    return res.data;
  }

  static Future<Map<String, dynamic>> downloadChargesheetDocx(Map<String, dynamic> data) async {
    final res = await _dio.post('/ai/chargesheet-generation/download-docx', data: data);
    return res.data;
  }

  // ── Chargesheet Vetting ──
  static Future<Map<String, dynamic>> vetChargesheet({
    String chargesheetText = '',
    String additionalInstructions = '',
    PlatformFile? chargesheetFile,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('chargesheet_text', chargesheetText),
      MapEntry('additional_instructions', additionalInstructions),
    ]);
    if (chargesheetFile?.bytes != null) {
      formData.files.add(MapEntry('chargesheet_file', MultipartFile.fromBytes(chargesheetFile!.bytes!, filename: chargesheetFile.name)));
    }
    final res = await _dio.post('/ai/chargesheet-vetting', data: formData);
    return res.data;
  }

  static Future<Map<String, dynamic>> downloadVettingDocx(Map<String, dynamic> data) async {
    final res = await _dio.post('/ai/chargesheet-vetting/download-docx', data: data);
    return res.data;
  }

  // ── Document Drafting ──
  static Future<Map<String, dynamic>> draftDocument({
    required String caseData,
    required String recipientType,
    String additionalInstructions = '',
    PlatformFile? file,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('case_data', caseData),
      MapEntry('recipient_type', recipientType),
      MapEntry('additional_instructions', additionalInstructions),
    ]);
    if (file?.bytes != null) {
      formData.files.add(MapEntry('file', MultipartFile.fromBytes(file!.bytes!, filename: file.name)));
    }
    final res = await _dio.post('/ai/document-drafting', data: formData);
    return res.data;
  }

  static Future<Map<String, dynamic>> downloadDraftDocx(Map<String, dynamic> data) async {
    final res = await _dio.post('/ai/document-drafting/download-docx', data: data);
    return res.data;
  }

  // ── AI Investigation Guidelines ──
  static Future<Map<String, dynamic>> aiInvestigation(Map<String, dynamic> data) async {
    final res = await _dio.post('/ai/ai-investigation', data: data);
    return res.data;
  }

  // ── Investigation Report ──
  static Future<Map<String, dynamic>> generateInvestigationReport(Map<String, dynamic> data) async {
    final res = await _dio.post('/ai/investigation-report', data: data);
    return res.data;
  }

  // ── Media Analysis ──
  static Future<Map<String, dynamic>> mediaAnalysis({
    required PlatformFile file,
    String analysisType = 'general',
    String additionalInstructions = '',
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('analysis_type', analysisType),
      MapEntry('additional_instructions', additionalInstructions),
    ]);
    if (file.bytes != null) {
      formData.files.add(MapEntry('file', MultipartFile.fromBytes(file.bytes!, filename: file.name)));
    }
    final res = await _dio.post('/ai/media-analysis', data: formData);
    return res.data;
  }

  // ── Document Relevance ──
  static Future<Map<String, dynamic>> documentRelevance({
    required PlatformFile file,
    String caseContext = '',
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('case_context', caseContext));
    if (file.bytes != null) {
      formData.files.add(MapEntry('file', MultipartFile.fromBytes(file.bytes!, filename: file.name)));
    }
    final res = await _dio.post('/ai/document-relevance', data: formData);
    return res.data;
  }

  // ── AI Translation ──
  static Future<Map<String, dynamic>> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    final res = await _dio.post('/ai/translate', data: {
      'text': text,
      'target_language': targetLanguage,
      'source_language': sourceLanguage,
    });
    return res.data;
  }
}
