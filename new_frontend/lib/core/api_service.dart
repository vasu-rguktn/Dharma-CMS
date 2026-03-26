/// Centralized HTTP client with automatic Firebase Auth token injection.
///
/// Every API call MUST go through [ApiService.dio] so that:
///   1. The backend URL is consistent ([ApiConfig.baseUrl]).
///   2. The Firebase ID‑token is attached to every request.
///   3. Errors are handled in one place.
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dharma/config/api_config.dart';

class ApiService {
  ApiService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(_AuthInterceptor());

  /// The single Dio instance every API service should use.
  static Dio get dio => _dio;

  /// Convenience: get the current user's ID‑token (or null).
  static Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }
}

/// Interceptor that attaches `Authorization: Bearer <token>` to every request.
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await ApiService.getIdToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Let the request proceed without auth; backend returns 401.
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
