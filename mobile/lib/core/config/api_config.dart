import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Default fallback
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      } else {
        return 'http://localhost:8080';
      }
    }
    return 'https://purescan-ai-backend.onrender.com';
  }
}
