class AppConfig {
  /// Production backend URL (deployed on Render)
  static const String productionApiHost =
      'https://annexpool-backend.onrender.com';

  /// Local development backend
  static const String devApiHost = 'http://localhost:8000';

  /// Resolves API host - uses production by default
  static String get apiHost {
    // Use production backend (Render)
    return productionApiHost;

    // For local development, uncomment:
    // if (kDebugMode) return devApiHost;
    // return productionApiHost;
  }

  static String get apiBaseUrl => '$apiHost/api';
  static String get authBaseUrl => '$apiHost/api/auth';
  static String get socketUrl => apiHost;

  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$apiHost$path';
  }
}
