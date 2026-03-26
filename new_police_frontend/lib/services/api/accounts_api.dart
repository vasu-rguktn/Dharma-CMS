import 'package:dharma_police/core/api_service.dart';

/// Backend API calls for accounts + police profiles.
class AccountsApi {
  static final _dio = ApiService.dio;

  // ── Account ──
  static Future<Map<String, dynamic>> getMyAccount() async {
    final r = await _dio.get('/accounts/me');
    return r.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    final r = await _dio.post('/accounts', data: data);
    return r.data;
  }

  static Future<Map<String, dynamic>> updateMyAccount(Map<String, dynamic> data) async {
    final r = await _dio.patch('/accounts/me', data: data);
    return r.data;
  }

  // ── Police Profile ──
  static Future<Map<String, dynamic>> getMyPoliceProfile() async {
    final r = await _dio.get('/accounts/me/police-profile');
    return r.data;
  }

  static Future<Map<String, dynamic>> createPoliceProfile(Map<String, dynamic> data) async {
    final r = await _dio.post('/accounts/me/police-profile', data: data);
    return r.data;
  }

  static Future<Map<String, dynamic>> updateMyPoliceProfile(Map<String, dynamic> data) async {
    final r = await _dio.patch('/accounts/me/police-profile', data: data);
    return r.data;
  }
}
