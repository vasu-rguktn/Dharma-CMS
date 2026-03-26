/// API service for COMPLAINT_DRAFTS and COMPLAINT_DRAFT_MESSAGES.
library;

import 'package:dio/dio.dart';
import 'package:Dharma/services/api_service.dart';

class ComplaintDraftsApi {
  ComplaintDraftsApi._();
  static Dio get _dio => ApiService.dio;

  // ═══════════════════════════════════════════════════════════════════
  //  COMPLAINT DRAFTS
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> create(
      String accountId, Map<String, dynamic> data) async {
    final res = await _dio
        .post('/accounts/$accountId/complaint-drafts', data: data);
    return res.data;
  }

  static Future<List<dynamic>> list(String accountId) async {
    final res =
        await _dio.get('/accounts/$accountId/complaint-drafts');
    return res.data;
  }

  static Future<Map<String, dynamic>> get(
      String accountId, String draftId) async {
    final res = await _dio
        .get('/accounts/$accountId/complaint-drafts/$draftId');
    return res.data;
  }

  static Future<Map<String, dynamic>> update(
      String accountId, String draftId, Map<String, dynamic> data) async {
    final res = await _dio
        .patch('/accounts/$accountId/complaint-drafts/$draftId', data: data);
    return res.data;
  }

  static Future<void> delete(String accountId, String draftId) async {
    await _dio
        .delete('/accounts/$accountId/complaint-drafts/$draftId');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  COMPLAINT DRAFT MESSAGES
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> addMessage(
      String accountId, String draftId, Map<String, dynamic> data) async {
    final res = await _dio.post(
        '/accounts/$accountId/complaint-drafts/$draftId/messages',
        data: data);
    return res.data;
  }

  static Future<List<dynamic>> listMessages(
      String accountId, String draftId) async {
    final res = await _dio
        .get('/accounts/$accountId/complaint-drafts/$draftId/messages');
    return res.data;
  }

  static Future<void> deleteMessage(
      String accountId, String draftId, String messageId) async {
    await _dio.delete(
        '/accounts/$accountId/complaint-drafts/$draftId/messages/$messageId');
  }
}
