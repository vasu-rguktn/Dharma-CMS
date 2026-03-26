/// API service for Petitions and sub-resources:
///   Assignments, Attachments, Updates, UpdateAttachments, Saves.
///
/// URLs are flat (no account nesting) — the backend resolves the owner
/// from the Firebase token automatically.
library;

import 'package:dio/dio.dart';
import 'package:dharma/core/api_service.dart';

class PetitionsApi {
  PetitionsApi._();
  static Dio get _dio => ApiService.dio;

  // ── Petitions CRUD ──
  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/petitions', data: data);
    return res.data;
  }

  static Future<List<dynamic>> list({int limit = 100, String? statusFilter}) async {
    final params = <String, dynamic>{'limit': limit};
    if (statusFilter != null) params['status_filter'] = statusFilter;
    final res = await _dio.get('/petitions', queryParameters: params);
    return res.data;
  }

  static Future<Map<String, dynamic>> get(String petitionId) async {
    final res = await _dio.get('/petitions/$petitionId');
    return res.data;
  }

  static Future<Map<String, dynamic>> update(String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/petitions/$petitionId', data: data);
    return res.data;
  }

  static Future<void> delete(String petitionId) async {
    await _dio.delete('/petitions/$petitionId');
  }

  /// Admin/Police: list ALL petitions across accounts.
  static Future<List<dynamic>> listAll({int limit = 100, String? statusFilter}) async {
    final params = <String, dynamic>{'limit': limit};
    if (statusFilter != null) params['status_filter'] = statusFilter;
    final res = await _dio.get('/petitions/all', queryParameters: params);
    return res.data;
  }

  /// Get petition count stats for the current user.
  static Future<Map<String, dynamic>> stats() async {
    final res = await _dio.get('/petitions/stats');
    return res.data;
  }

  // ── Assignments ──
  static Future<Map<String, dynamic>> createAssignment(String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.post('/petitions/$petitionId/assignments', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listAssignments(String petitionId) async {
    final res = await _dio.get('/petitions/$petitionId/assignments');
    return res.data;
  }

  // ── Attachments ──
  static Future<Map<String, dynamic>> createAttachment(String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.post('/petitions/$petitionId/attachments', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listAttachments(String petitionId) async {
    final res = await _dio.get('/petitions/$petitionId/attachments');
    return res.data;
  }

  // ── Updates (timeline) ──
  static Future<Map<String, dynamic>> createUpdate(String petitionId, Map<String, dynamic> data) async {
    final res = await _dio.post('/petitions/$petitionId/updates', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listUpdates(String petitionId) async {
    final res = await _dio.get('/petitions/$petitionId/updates');
    return res.data;
  }

  // ── Petition Saves (bookmarks) ──
  static Future<Map<String, dynamic>> savePetition(Map<String, dynamic> data) async {
    final res = await _dio.post('/petition-saves', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listSavedPetitions() async {
    final res = await _dio.get('/petition-saves');
    return res.data;
  }

  static Future<void> unsavePetition(String saveId) async {
    await _dio.delete('/petition-saves/$saveId');
  }
}
