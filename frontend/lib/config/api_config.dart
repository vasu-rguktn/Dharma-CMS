/// Central configuration for all backend API URLs.
///
/// Change [baseUrl] to switch between local dev and production.
/// Every API service reads from here — no hardcoded URLs anywhere else.
class ApiConfig {
  ApiConfig._();

  // ─── Toggle this single line to switch environments ───────────────
  // Local development:
  // static const String baseUrl = 'http://localhost:8000';
  // Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';
  // Production:
  static const String baseUrl =
      'https://fastapi-app-335340524683.asia-south1.run.app';

  // ─── API path prefixes ────────────────────────────────────────────
  static const String accounts = '/accounts';
  static const String petitions = '/accounts'; // nested under accounts
  static const String cases = '/accounts'; // nested under accounts
  static const String complaintDrafts = '/accounts';
  static const String legalThreads = '/accounts';
  static const String promptTemplates = '/prompt-templates';

  // AI Gateway (routed through backend)
  static const String aiGateway = '/ai';

  // Health
  static const String health = '/api/health';
}
