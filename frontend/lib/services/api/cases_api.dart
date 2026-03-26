/// API service for CASES and all sub‑collections:
///   CASE_PEOPLE, CASE_OFFICERS, CASE_CRIME_DETAILS,
///   CASE_JOURNAL_ENTRIES, CASE_JOURNAL_ATTACHMENTS, CASE_DOCUMENTS.
library;

import 'package:dio/dio.dart';
import 'package:Dharma/services/api_service.dart';

class CasesApi {
  CasesApi._();
  static Dio get _dio => ApiService.dio;

  static String _base(String accountId, String petitionId) =>
      '/accounts/$accountId/petitions/$petitionId/cases';

  // ═══════════════════════════════════════════════════════════════════
  //  CASES
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> create(
      String accountId, String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.post(_base(accountId, petitionId), data: data);
    return res.data;
  }

  static Future<List<dynamic>> list(String accountId, String petitionId,
      {int limit = 100}) async {
    final res = await _dio.get(_base(accountId, petitionId),
        queryParameters: {'limit': limit});
    return res.data;
  }

  static Future<Map<String, dynamic>> get(
      String accountId, String petitionId, String caseId) async {
    final res = await _dio.get('${_base(accountId, petitionId)}/$caseId');
    return res.data;
  }

  static Future<Map<String, dynamic>> update(String accountId,
      String petitionId, String caseId, Map<String, dynamic> data) async {
    final res = await _dio
        .patch('${_base(accountId, petitionId)}/$caseId', data: data);
    return res.data;
  }

  static Future<void> delete(
      String accountId, String petitionId, String caseId) async {
    await _dio.delete('${_base(accountId, petitionId)}/$caseId');
  }

  /// Police‑only: list ALL cases across all accounts.
  static Future<List<dynamic>> listAll(
      {int limit = 100, String? statusFilter}) async {
    final params = <String, dynamic>{'limit': limit};
    if (statusFilter != null) params['status_filter'] = statusFilter;
    final res = await _dio.get('/cases/all', queryParameters: params);
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CASE PEOPLE
  // ═══════════════════════════════════════════════════════════════════

  static String _peoplePath(String a, String p, String c) =>
      '${_base(a, p)}/$c/people';

  static Future<Map<String, dynamic>> addPerson(String accountId,
      String petitionId, String caseId, Map<String, dynamic> data) async {
    final res =
        await _dio.post(_peoplePath(accountId, petitionId, caseId), data: data);
    return res.data;
  }

  static Future<List<dynamic>> listPeople(
      String accountId, String petitionId, String caseId) async {
    final res =
        await _dio.get(_peoplePath(accountId, petitionId, caseId));
    return res.data;
  }

  static Future<Map<String, dynamic>> getPerson(String accountId,
      String petitionId, String caseId, String personId) async {
    final res = await _dio
        .get('${_peoplePath(accountId, petitionId, caseId)}/$personId');
    return res.data;
  }

  static Future<Map<String, dynamic>> updatePerson(
      String accountId,
      String petitionId,
      String caseId,
      String personId,
      Map<String, dynamic> data) async {
    final res = await _dio.patch(
        '${_peoplePath(accountId, petitionId, caseId)}/$personId',
        data: data);
    return res.data;
  }

  static Future<void> deletePerson(String accountId, String petitionId,
      String caseId, String personId) async {
    await _dio
        .delete('${_peoplePath(accountId, petitionId, caseId)}/$personId');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CASE OFFICERS
  // ═══════════════════════════════════════════════════════════════════

  static String _officersPath(String a, String p, String c) =>
      '${_base(a, p)}/$c/officers';

  static Future<Map<String, dynamic>> addOfficer(String accountId,
      String petitionId, String caseId, Map<String, dynamic> data) async {
    final res = await _dio
        .post(_officersPath(accountId, petitionId, caseId), data: data);
    return res.data;
  }

  static Future<List<dynamic>> listOfficers(
      String accountId, String petitionId, String caseId) async {
    final res =
        await _dio.get(_officersPath(accountId, petitionId, caseId));
    return res.data;
  }

  static Future<void> deleteOfficer(String accountId, String petitionId,
      String caseId, String officerId) async {
    await _dio.delete(
        '${_officersPath(accountId, petitionId, caseId)}/$officerId');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CASE CRIME DETAILS
  // ═══════════════════════════════════════════════════════════════════

  static String _crimePath(String a, String p, String c) =>
      '${_base(a, p)}/$c/crime-details';

  static Future<Map<String, dynamic>> addCrimeDetail(String accountId,
      String petitionId, String caseId, Map<String, dynamic> data) async {
    final res =
        await _dio.post(_crimePath(accountId, petitionId, caseId), data: data);
    return res.data;
  }

  static Future<List<dynamic>> listCrimeDetails(
      String accountId, String petitionId, String caseId) async {
    final res =
        await _dio.get(_crimePath(accountId, petitionId, caseId));
    return res.data;
  }

  static Future<void> deleteCrimeDetail(String accountId, String petitionId,
      String caseId, String detailId) async {
    await _dio
        .delete('${_crimePath(accountId, petitionId, caseId)}/$detailId');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CASE JOURNAL ENTRIES  +  JOURNAL ATTACHMENTS
  // ═══════════════════════════════════════════════════════════════════

  static String _journalPath(String a, String p, String c) =>
      '${_base(a, p)}/$c/journal';

  static Future<Map<String, dynamic>> addJournalEntry(String accountId,
      String petitionId, String caseId, Map<String, dynamic> data) async {
    final res = await _dio
        .post(_journalPath(accountId, petitionId, caseId), data: data);
    return res.data;
  }

  static Future<List<dynamic>> listJournalEntries(
      String accountId, String petitionId, String caseId) async {
    final res =
        await _dio.get(_journalPath(accountId, petitionId, caseId));
    return res.data;
  }

  static Future<Map<String, dynamic>> getJournalEntry(String accountId,
      String petitionId, String caseId, String entryId) async {
    final res = await _dio
        .get('${_journalPath(accountId, petitionId, caseId)}/$entryId');
    return res.data;
  }

  static Future<void> deleteJournalEntry(String accountId, String petitionId,
      String caseId, String entryId) async {
    await _dio
        .delete('${_journalPath(accountId, petitionId, caseId)}/$entryId');
  }

  // Journal Attachments
  static Future<Map<String, dynamic>> addJournalAttachment(
      String accountId,
      String petitionId,
      String caseId,
      String entryId,
      Map<String, dynamic> data) async {
    final res = await _dio.post(
        '${_journalPath(accountId, petitionId, caseId)}/$entryId/attachments',
        data: data);
    return res.data;
  }

  static Future<List<dynamic>> listJournalAttachments(String accountId,
      String petitionId, String caseId, String entryId) async {
    final res = await _dio.get(
        '${_journalPath(accountId, petitionId, caseId)}/$entryId/attachments');
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CASE DOCUMENTS
  // ═══════════════════════════════════════════════════════════════════

  static String _docsPath(String a, String p, String c) =>
      '${_base(a, p)}/$c/documents';

  static Future<Map<String, dynamic>> addDocument(String accountId,
      String petitionId, String caseId, Map<String, dynamic> data) async {
    final res =
        await _dio.post(_docsPath(accountId, petitionId, caseId), data: data);
    return res.data;
  }

  static Future<List<dynamic>> listDocuments(
      String accountId, String petitionId, String caseId) async {
    final res =
        await _dio.get(_docsPath(accountId, petitionId, caseId));
    return res.data;
  }

  static Future<Map<String, dynamic>> getDocument(String accountId,
      String petitionId, String caseId, String documentId) async {
    final res = await _dio
        .get('${_docsPath(accountId, petitionId, caseId)}/$documentId');
    return res.data;
  }

  static Future<void> deleteDocument(String accountId, String petitionId,
      String caseId, String documentId) async {
    await _dio
        .delete('${_docsPath(accountId, petitionId, caseId)}/$documentId');
  }
}
