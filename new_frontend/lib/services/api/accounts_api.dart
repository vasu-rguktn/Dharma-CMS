/// API service for Accounts, Citizen Profiles, Police Profiles, Device Tokens.
library;

import 'package:dio/dio.dart';
import 'package:dharma/core/api_service.dart';

class AccountsApi {
  AccountsApi._();
  static Dio get _dio => ApiService.dio;

  // ── Account ──
  static Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    final res = await _dio.post('/accounts', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getMyAccount() async {
    final res = await _dio.get('/accounts/me');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateMyAccount(Map<String, dynamic> data) async {
    final res = await _dio.patch('/accounts/me', data: data);
    return res.data;
  }

  // ── Citizen Profile ──
  static Future<Map<String, dynamic>> createCitizenProfile(Map<String, dynamic> data) async {
    final res = await _dio.post('/accounts/me/citizen-profile', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getMyCitizenProfile() async {
    final res = await _dio.get('/accounts/me/citizen-profile');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateMyCitizenProfile(Map<String, dynamic> data) async {
    final res = await _dio.patch('/accounts/me/citizen-profile', data: data);
    return res.data;
  }

  // ── Police Profile ──
  static Future<Map<String, dynamic>> createPoliceProfile(Map<String, dynamic> data) async {
    final res = await _dio.post('/accounts/me/police-profile', data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> getMyPoliceProfile() async {
    final res = await _dio.get('/accounts/me/police-profile');
    return res.data;
  }

  static Future<Map<String, dynamic>> updateMyPoliceProfile(Map<String, dynamic> data) async {
    final res = await _dio.patch('/accounts/me/police-profile', data: data);
    return res.data;
  }

  // ── Device Tokens ──
  static Future<Map<String, dynamic>> registerDeviceToken(Map<String, dynamic> data) async {
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
