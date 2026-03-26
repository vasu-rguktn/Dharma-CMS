/// API configuration — single source of truth for all backend URLs.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the FastAPI backend. Same backend serves both citizen & police.
  static const String baseUrl = 'http://localhost:8000';
}
