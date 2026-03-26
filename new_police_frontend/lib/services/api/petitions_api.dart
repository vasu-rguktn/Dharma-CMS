import 'package:dharma_police/core/api_service.dart';

/// Backend API calls for petitions (police view).
class PetitionsApi {
  static final _dio = ApiService.dio;

  static Future<List<dynamic>> listPetitions({int limit = 50, int offset = 0, String? status}) async {
    final params = <String, dynamic>{'limit': limit, 'offset': offset};
    if (status != null) params['status_filter'] = status;
    final r = await _dio.get('/petitions', queryParameters: params);
    return r.data;
  }

  static Future<Map<String, dynamic>> getPetition(String id) async {
    final r = await _dio.get('/petitions/$id');
    return r.data;
  }

  static Future<Map<String, dynamic>> updatePetition(String id, Map<String, dynamic> data) async {
    final r = await _dio.patch('/petitions/$id', data: data);
    return r.data;
  }

  // ── Assignments ──
  static Future<Map<String, dynamic>> assignPetition(String petitionId, Map<String, dynamic> data) async {
    final r = await _dio.post('/petitions/$petitionId/assignments', data: data);
    return r.data;
  }

  static Future<List<dynamic>> listAssignments(String petitionId) async {
    final r = await _dio.get('/petitions/$petitionId/assignments');
    return r.data;
  }

  // ── Updates ──
  static Future<Map<String, dynamic>> addUpdate(String petitionId, Map<String, dynamic> data) async {
    final r = await _dio.post('/petitions/$petitionId/updates', data: data);
    return r.data;
  }

  static Future<List<dynamic>> listUpdates(String petitionId) async {
    final r = await _dio.get('/petitions/$petitionId/updates');
    return r.data;
  }
}
