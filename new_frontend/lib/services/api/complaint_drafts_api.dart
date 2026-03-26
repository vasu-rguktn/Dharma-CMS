/// API service for Complaint Drafts and Complaint Draft Messages.
///
/// URLs are flat — the backend resolves the owner from the Firebase token.
library;

import 'package:dio/dio.dart';
import 'package:dharma/core/api_service.dart';

class ComplaintDraftsApi {
  ComplaintDraftsApi._();
  static Dio get _dio => ApiService.dio;

  // ── Drafts ──
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/complaint-drafts', data: data);
    return res.data;
  }

  static Future<List<dynamic>> list() async {
    final res = await _dio.get('/complaint-drafts');
    return res.data;
  }

  static Future<Map<String, dynamic>> get(String draftId) async {
    final res = await _dio.get('/complaint-drafts/$draftId');
    return res.data;
  }

  static Future<Map<String, dynamic>> update(String draftId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/complaint-drafts/$draftId', data: data);
    return res.data;
  }

  static Future<void> delete(String draftId) async {
    await _dio.delete('/complaint-drafts/$draftId');
  }

  // ── Messages ──
  static Future<Map<String, dynamic>> addMessage(String draftId, Map<String, dynamic> data) async {
    final res = await _dio.post('/complaint-drafts/$draftId/messages', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listMessages(String draftId) async {
    final res = await _dio.get('/complaint-drafts/$draftId/messages');
    return res.data;
  }
}
