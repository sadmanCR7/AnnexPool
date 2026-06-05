import 'package:flutter/foundation.dart';

class AppConfig {
  /// Resolves API host for web, Android emulator, and iOS/desktop.
  static String get apiHost {
    if (kIsWeb) return 'http://localhost:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://localhost:8000';
    }
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
