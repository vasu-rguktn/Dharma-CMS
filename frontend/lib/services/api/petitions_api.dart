/// API service for PETITIONS and all sub‑collections:
///   PETITION_ASSIGNMENTS, PETITION_ATTACHMENTS, PETITION_UPDATES,
///   PETITION_UPDATE_ATTACHMENTS, PETITION_SAVES.
library;

import 'package:dio/dio.dart';
import 'package:Dharma/services/api_service.dart';

class PetitionsApi {
  PetitionsApi._();
  static Dio get _dio => ApiService.dio;

  // ═══════════════════════════════════════════════════════════════════
  //  PETITIONS
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> create(
      String accountId, Map<String, dynamic> data) async {
    final res =
        await _dio.post('/accounts/$accountId/petitions', data: data);
    return res.data;
  }

  static Future<List<dynamic>> list(String accountId,
      {int limit = 100}) async {
    final res = await _dio.get('/accounts/$accountId/petitions',
        queryParameters: {'limit': limit});
    return res.data;
  }

  static Future<Map<String, dynamic>> get(
      String accountId, String petitionId) async {
    final res =
        await _dio.get('/accounts/$accountId/petitions/$petitionId');
    return res.data;
  }

  static Future<Map<String, dynamic>> update(
      String accountId, String petitionId, Map<String, dynamic> data) async {
    final res = await _dio
        .patch('/accounts/$accountId/petitions/$petitionId', data: data);
    return res.data;
  }

  static Future<void> delete(String accountId, String petitionId) async {
    await _dio.delete('/accounts/$accountId/petitions/$petitionId');
  }

  /// Police‑only: list ALL petitions across all accounts.
  static Future<List<dynamic>> listAll(
      {int limit = 100, String? statusFilter}) async {
    final params = <String, dynamic>{'limit': limit};
    if (statusFilter != null) params['status_filter'] = statusFilter;
    final res =
        await _dio.get('/petitions/all', queryParameters: params);
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PETITION ASSIGNMENTS
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createAssignment(
      String accountId, String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.post(
        '/accounts/$accountId/petitions/$petitionId/assignments',
        data: data);
    return res.data;
  }

  static Future<List<dynamic>> listAssignments(
      String accountId, String petitionId) async {
    final res = await _dio
        .get('/accounts/$accountId/petitions/$petitionId/assignments');
    return res.data;
  }

  static Future<void> deleteAssignment(
      String accountId, String petitionId, String assignmentId) async {
    await _dio.delete(
        '/accounts/$accountId/petitions/$petitionId/assignments/$assignmentId');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PETITION ATTACHMENTS
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createAttachment(
      String accountId, String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.post(
        '/accounts/$accountId/petitions/$petitionId/attachments',
        data: data);
    return res.data;
  }

  static Future<List<dynamic>> listAttachments(
      String accountId, String petitionId) async {
    final res = await _dio
        .get('/accounts/$accountId/petitions/$petitionId/attachments');
    return res.data;
  }

  static Future<void> deleteAttachment(
      String accountId, String petitionId, String attachmentId) async {
    await _dio.delete(
        '/accounts/$accountId/petitions/$petitionId/attachments/$attachmentId');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PETITION UPDATES
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createUpdate(
      String accountId, String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.post(
        '/accounts/$accountId/petitions/$petitionId/updates',
        data: data);
    return res.data;
  }

  static Future<List<dynamic>> listUpdates(
      String accountId, String petitionId) async {
    final res = await _dio
        .get('/accounts/$accountId/petitions/$petitionId/updates');
    return res.data;
  }

  static Future<Map<String, dynamic>> getUpdate(
      String accountId, String petitionId, String updateId) async {
    final res = await _dio
        .get('/accounts/$accountId/petitions/$petitionId/updates/$updateId');
    return res.data;
  }

  // ── PETITION UPDATE ATTACHMENTS ───────────────────────────────────

  static Future<Map<String, dynamic>> createUpdateAttachment(
    String accountId,
    String petitionId,
    String updateId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post(
        '/accounts/$accountId/petitions/$petitionId/updates/$updateId/attachments',
        data: data);
    return res.data;
  }

  static Future<List<dynamic>> listUpdateAttachments(
    String accountId,
    String petitionId,
    String updateId,
  ) async {
    final res = await _dio.get(
        '/accounts/$accountId/petitions/$petitionId/updates/$updateId/attachments');
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PETITION SAVES (bookmarks)
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> savePetition(
      String accountId, Map<String, dynamic> data) async {
    final res =
        await _dio.post('/accounts/$accountId/petition-saves', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listSavedPetitions(String accountId) async {
    final res = await _dio.get('/accounts/$accountId/petition-saves');
    return res.data;
  }

  static Future<void> unsavePetition(String accountId, String saveId) async {
    await _dio.delete('/accounts/$accountId/petition-saves/$saveId');
  }
}
