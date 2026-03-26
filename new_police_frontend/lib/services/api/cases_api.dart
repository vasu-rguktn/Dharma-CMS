import 'package:dharma_police/core/api_service.dart';

/// Backend API calls for cases and sub-resources.
class CasesApi {
  static final _dio = ApiService.dio;

  static Future<List<dynamic>> listCases({int limit = 50, int offset = 0, String? status}) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (status != null) params['status_filter'] = status;
    final r = await _dio.get('/cases', queryParameters: params);
    return r.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getCase(String id) async {
    final r = await _dio.get('/cases/$id');
    return r.data;
  }

  static Future<Map<String, dynamic>> createCase(Map<String, dynamic> data) async {
    final r = await _dio.post('/cases', data: data);
    return r.data;
  }

  static Future<Map<String, dynamic>> updateCase(String id, Map<String, dynamic> data) async {
    final r = await _dio.patch('/cases/$id', data: data);
    return r.data;
  }

  static Future<void> deleteCase(String id) async {
    await _dio.delete('/cases/$id');
  }

  // ── Case People ──
  static Future<List<dynamic>> listCasePeople(String caseId) async {
    final r = await _dio.get('/cases/$caseId/people');
    return r.data;
  }

  static Future<Map<String, dynamic>> addCasePerson(String caseId, Map<String, dynamic> data) async {
    final r = await _dio.post('/cases/$caseId/people', data: data);
    return r.data;
  }

  // ── Case Journal ──
  static Future<List<dynamic>> listJournalEntries(String caseId) async {
    final r = await _dio.get('/cases/$caseId/journal');
    return r.data;
  }

  static Future<Map<String, dynamic>> addJournalEntry(String caseId, Map<String, dynamic> data) async {
    final r = await _dio.post('/cases/$caseId/journal', data: data);
    return r.data;
  }

  // ── Case Documents ──
  static Future<List<dynamic>> listDocuments(String caseId) async {
    final r = await _dio.get('/cases/$caseId/documents');
    return r.data;
  }

  static Future<Map<String, dynamic>> addDocument(String caseId, Map<String, dynamic> data) async {
    final r = await _dio.post('/cases/$caseId/documents', data: data);
    return r.data;
  }
}
