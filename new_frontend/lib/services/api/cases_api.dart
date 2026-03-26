/// API service for Cases and sub-resources:
///   CasePeople, CaseOfficers, CaseCrimeDetails,
///   CaseJournalEntries, CaseDocuments.
library;

import 'package:dio/dio.dart';
import 'package:dharma/core/api_service.dart';

class CasesApi {
  CasesApi._();
  static Dio get _dio => ApiService.dio;

  // ── Cases CRUD ──
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/cases', data: data);
    return res.data;
  }

  static Future<List<dynamic>> list({int limit = 50, int offset = 0, String? statusFilter}) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (statusFilter != null) params['status_filter'] = statusFilter;
    final res = await _dio.get('/cases', queryParameters: params);
    return res.data;
  }

  static Future<Map<String, dynamic>> get(String caseId) async {
    final res = await _dio.get('/cases/$caseId');
    return res.data;
  }

  static Future<Map<String, dynamic>> update(String caseId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/cases/$caseId', data: data);
    return res.data;
  }

  static Future<void> delete(String caseId) async {
    await _dio.delete('/cases/$caseId');
  }

  // ── Case People ──
  static Future<Map<String, dynamic>> addPerson(String caseId, Map<String, dynamic> data) async {
    final res = await _dio.post('/cases/$caseId/people', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listPeople(String caseId) async {
    final res = await _dio.get('/cases/$caseId/people');
    return res.data;
  }

  static Future<Map<String, dynamic>> updatePerson(String caseId, String personId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/cases/$caseId/people/$personId', data: data);
    return res.data;
  }

  static Future<void> deletePerson(String caseId, String personId) async {
    await _dio.delete('/cases/$caseId/people/$personId');
  }

  // ── Case Officers ──
  static Future<Map<String, dynamic>> addOfficer(String caseId, Map<String, dynamic> data) async {
    final res = await _dio.post('/cases/$caseId/officers', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listOfficers(String caseId) async {
    final res = await _dio.get('/cases/$caseId/officers');
    return res.data;
  }

  static Future<void> deleteOfficer(String caseId, String officerId) async {
    await _dio.delete('/cases/$caseId/officers/$officerId');
  }

  // ── Case Crime Details ──
  static Future<Map<String, dynamic>> addCrimeDetail(String caseId, Map<String, dynamic> data) async {
    final res = await _dio.post('/cases/$caseId/crime-details', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listCrimeDetails(String caseId) async {
    final res = await _dio.get('/cases/$caseId/crime-details');
    return res.data;
  }

  static Future<void> deleteCrimeDetail(String caseId, String detailId) async {
    await _dio.delete('/cases/$caseId/crime-details/$detailId');
  }

  // ── Case Journal Entries ──
  static Future<Map<String, dynamic>> addJournalEntry(String caseId, Map<String, dynamic> data) async {
    final res = await _dio.post('/cases/$caseId/journal-entries', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listJournalEntries(String caseId) async {
    final res = await _dio.get('/cases/$caseId/journal-entries');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateJournalEntry(String caseId, String entryId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/cases/$caseId/journal-entries/$entryId', data: data);
    return res.data;
  }

  static Future<void> deleteJournalEntry(String caseId, String entryId) async {
    await _dio.delete('/cases/$caseId/journal-entries/$entryId');
  }

  // ── Case Documents ──
  static Future<Map<String, dynamic>> addDocument(String caseId, Map<String, dynamic> data) async {
    final res = await _dio.post('/cases/$caseId/documents', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listDocuments(String caseId) async {
    final res = await _dio.get('/cases/$caseId/documents');
    return res.data;
  }

  static Future<void> deleteDocument(String caseId, String docId) async {
    await _dio.delete('/cases/$caseId/documents/$docId');
  }
}
