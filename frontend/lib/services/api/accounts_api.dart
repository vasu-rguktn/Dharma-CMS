/// API service for ACCOUNTS, CITIZEN_PROFILES, POLICE_PROFILES, DEVICE_TOKENS.
///
/// All calls go through the centralized [ApiService.dio].
library;

import 'package:dio/dio.dart';
import 'package:Dharma/services/api_service.dart';

class AccountsApi {
  AccountsApi._();
  static Dio get _dio => ApiService.dio;

  // ═══════════════════════════════════════════════════════════════════
  //  ACCOUNT
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createAccount(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/accounts', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getMyAccount() async {
    final res = await _dio.get('/accounts/me');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateMyAccount(
      Map<String, dynamic> data) async {
    final res = await _dio.patch('/accounts/me', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getAccount(String accountId) async {
    final res = await _dio.get('/accounts/$accountId');
    return res.data;
  }

  static Future<List<dynamic>> listAccounts({int limit = 100}) async {
    final res = await _dio.get('/accounts', queryParameters: {'limit': limit});
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CITIZEN PROFILE
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createCitizenProfile(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/accounts/me/citizen-profile', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getMyCitizenProfile() async {
    final res = await _dio.get('/accounts/me/citizen-profile');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateMyCitizenProfile(
      Map<String, dynamic> data) async {
    final res = await _dio.patch('/accounts/me/citizen-profile', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getCitizenProfile(
      String accountId) async {
    final res = await _dio.get('/accounts/$accountId/citizen-profile');
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  POLICE PROFILE
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createPoliceProfile(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/accounts/me/police-profile', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getMyPoliceProfile() async {
    final res = await _dio.get('/accounts/me/police-profile');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateMyPoliceProfile(
      Map<String, dynamic> data) async {
    final res = await _dio.patch('/accounts/me/police-profile', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listAllPoliceProfiles(
      {int limit = 100}) async {
    final res = await _dio.get('/accounts/police-profiles/all',
        queryParameters: {'limit': limit});
    return res.data;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DEVICE TOKENS
  // ═══════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> registerDeviceToken(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/accounts/me/device-tokens', data: data);
    return res.data;
  }

  static Future<List<dynamic>> listMyDeviceTokens() async {
    final res = await _dio.get('/accounts/me/device-tokens');
    return res.data;
  }

  static Future<void> deleteDeviceToken(String tokenId) async {
    await _dio.delete('/accounts/me/device-tokens/$tokenId');
  }
}
