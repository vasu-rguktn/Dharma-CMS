/// API service for Legal Query Threads and Legal Query Messages.
///
/// URLs are flat — the backend resolves the owner from the Firebase token.
library;

import 'package:dio/dio.dart';
import 'package:dharma/core/api_service.dart';

class LegalQueriesApi {
  LegalQueriesApi._();
  static Dio get _dio => ApiService.dio;

  // ── Threads ──
  static Future<Map<String, dynamic>> createThread(Map<String, dynamic> data) async {
    final res = await _dio.post('/legal-threads', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listThreads() async {
    final res = await _dio.get('/legal-threads');
    return res.data;
  }

  static Future<Map<String, dynamic>> getThread(String threadId) async {
    final res = await _dio.get('/legal-threads/$threadId');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateThread(String threadId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/legal-threads/$threadId', data: data);
    return res.data;
  }

  static Future<void> deleteThread(String threadId) async {
    await _dio.delete('/legal-threads/$threadId');
  }

  // ── Messages ──
  static Future<Map<String, dynamic>> addMessage(String threadId, Map<String, dynamic> data) async {
    final res = await _dio.post('/legal-threads/$threadId/messages', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listMessages(String threadId) async {
    final res = await _dio.get('/legal-threads/$threadId/messages');
    return res.data;
  }
}
