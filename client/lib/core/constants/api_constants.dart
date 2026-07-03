import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Production backend URL — update this after deploying to Render.
  /// Format: https://transponet-backend.onrender.com/api
  static const String productionBaseUrl =
      'https://transponet-backend.onrender.com/api';

  /// Returns the correct base URL depending on build mode and platform.
  static String get baseUrl {
    // Return local machine IP for all for now, to fix connection from physical devices
    return 'http://10.173.155.13:5000/api';
  }

  /// WebSocket base (for Socket.io)
  static String get socketUrl {
    return 'http://10.173.155.13:5000';
  }

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
}
