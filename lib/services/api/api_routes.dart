import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiRoutes {
  static final ApiRoutes instance = ApiRoutes._internal();
  ApiRoutes._internal();

  String? _customBaseUrl;

  String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return "http://localhost:8000";
    }
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8000";
    }
    return "http://localhost:8000";
  }

  void setBaseUrl(String url) {
    _customBaseUrl = url;
  }

  final String version = "1.0.0";
}
