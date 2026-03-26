/// API service for LEGAL_QUERY_THREADS and LEGAL_QUERY_MESSAGES.
library;

import 'package:dio/dio.dart';
import 'package:Dharma/services/api_service.dart';

class LegalQueriesApi {
  LegalQueriesApi._();
  static Dio get _dio => ApiService.dio;

  // ═══════════════════════════════════════════════════════════════════
  //  LEGAL QUERY THREADS
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createThread(
      String accountId, Map<String, dynamic> data) async {
    final res =
        await _dio.post('/accounts/$accountId/legal-threads', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listThreads(String accountId) async {
    final res = await _dio.get('/accounts/$accountId/legal-threads');
    return res.data;
  }

  static Future<Map<String, dynamic>> getThread(
      String accountId, String threadId) async {
    final res =
        await _dio.get('/accounts/$accountId/legal-threads/$threadId');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateThread(
      String accountId, String threadId, Map<String, dynamic> data) async {
    final res = await _dio
        .patch('/accounts/$accountId/legal-threads/$threadId', data: data);
    return res.data;
  }

  static Future<void> deleteThread(String accountId, String threadId) async {
    await _dio
        .delete('/accounts/$accountId/legal-threads/$threadId');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LEGAL QUERY MESSAGES
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> addMessage(
      String accountId, String threadId, Map<String, dynamic> data) async {
    final res = await _dio.post(
        '/accounts/$accountId/legal-threads/$threadId/messages',
        data: data);
    return res.data;
  }

  static Future<List<dynamic>> listMessages(
      String accountId, String threadId) async {
    final res = await _dio
        .get('/accounts/$accountId/legal-threads/$threadId/messages');
    return res.data;
  }

  static Future<void> deleteMessage(
      String accountId, String threadId, String messageId) async {
    await _dio.delete(
        '/accounts/$accountId/legal-threads/$threadId/messages/$messageId');
  }
}
