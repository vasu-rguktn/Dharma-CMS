/// AI Gateway API — all AI model calls are routed through the backend.
///
/// The Flutter app should NEVER call AI models directly.
/// Instead, it calls these endpoints which proxy to the AI service.
library;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Dharma/services/api_service.dart';

class AiGatewayApi {
  AiGatewayApi._();
  static Dio get _dio => ApiService.dio;

  // ═══════════════════════════════════════════════════════════════════
  //  COMPLAINT CHATBOT  (dynamic chat → formal summary)
  // ═══════════════════════════════════════════════════════════════════

  /// Send a chat‑step to the complaint chatbot.
  /// Returns the next question or the final summary.
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
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(file.bytes!, filename: file.name),
          ));
        }
      }
    }

    final res = await _dio.post('/ai/complaint/chat-step', data: formData);
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LEGAL CHAT
  // ═══════════════════════════════════════════════════════════════════

  /// Send a message to the legal‑chat AI and get a reply.
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
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(bytes, filename: name),
          ));
        }
      }
    }

    final res = await _dio.post('/ai/legal-chat', data: formData);
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LEGAL SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════

  /// Get IPC / BNS section suggestions for an incident.
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

  // ═══════════════════════════════════════════════════════════════════
  //  OCR  (document text extraction)
  // ═══════════════════════════════════════════════════════════════════

  /// Extract text from an uploaded document image.
  static Future<Map<String, dynamic>> ocrExtract(PlatformFile file) async {
    final formData = FormData();
    if (file.bytes != null) {
      formData.files.add(MapEntry(
        'file',
        MultipartFile.fromBytes(file.bytes!, filename: file.name),
      ));
    }

    final res = await _dio.post('/ai/ocr/extract', data: formData);
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PDF GENERATION  (chatbot summary → PDF)
  // ═══════════════════════════════════════════════════════════════════

  /// Generate a PDF summary from chatbot answers.
  /// Returns `{ "pdf_url": "/static/reports/..." }`.
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

  // ═══════════════════════════════════════════════════════════════════
  //  WITNESS PREPARATION
  // ═══════════════════════════════════════════════════════════════════

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
}
