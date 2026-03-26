/// Central configuration for all backend API URLs.
///
/// Change [baseUrl] to switch between local dev and production.
/// Every API service reads from here — no hardcoded URLs anywhere else.
class ApiConfig {
  ApiConfig._();

  // ─── Toggle this single line to switch environments ───────────────
  // Local development:
  static const String baseUrl = 'http://localhost:8000';
  // Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';
  // Production:
  // static const String baseUrl = 'https://fastapi-app-335340524683.asia-south1.run.app';

  // ─── API path prefixes (for documentation only — API classes use full paths) ──
  static const String accounts = '/accounts';
  static const String aiGateway = '/ai';
  static const String health = '/api/health';
}
