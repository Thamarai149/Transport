import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Production backend URL — update this after deploying to Render.
  /// Format: https://transponet-backend.onrender.com/api
  static const String productionBaseUrl =
      'https://transponet-backend.onrender.com/api';

  /// Returns the correct base URL depending on build mode and platform.
  static String get baseUrl {
    // Always use production URL in release builds
    if (!kDebugMode) return productionBaseUrl;

    // Debug mode: use local server
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 maps to host machine from Android emulator
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  /// WebSocket base (for Socket.io)
  static String get socketUrl {
    if (!kDebugMode) return 'https://transponet-backend.onrender.com';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
}
