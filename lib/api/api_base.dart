import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allomom/api/api_routes.dart';
import 'package:allomom/api/response.dart';

const String _kJwtTokenKey = 'allomom_jwt_token';
const String _kRefreshTokenKey = 'allomom_refresh_token';

class ApiBase {
  static String? _cachedJwt;
  static String? _cachedRefreshToken;

  /// Optional pre-initialization of cached tokens
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedJwt = prefs.getString(_kJwtTokenKey);
      _cachedRefreshToken = prefs.getString(_kRefreshTokenKey);
    } catch (e) {
      debugPrint("⚠️ [ApiBase.init] SharedPreferences warning: $e");
    }
  }

  static Future<String?> getJwt() async {
    if (_cachedJwt != null) return _cachedJwt;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedJwt = prefs.getString(_kJwtTokenKey);
      return _cachedJwt;
    } catch (e) {
      debugPrint("⚠️ [ApiBase.getJwt] SharedPreferences warning: $e");
      return _cachedJwt;
    }
  }

  static Future<void> setJwt(String token) async {
    _cachedJwt = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kJwtTokenKey, token);
    } catch (e) {
      debugPrint("⚠️ [ApiBase.setJwt] SharedPreferences warning: $e");
    }
  }

  static Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedRefreshToken = prefs.getString(_kRefreshTokenKey);
      return _cachedRefreshToken;
    } catch (e) {
      debugPrint("⚠️ [ApiBase.getRefreshToken] SharedPreferences warning: $e");
      return _cachedRefreshToken;
    }
  }

  static Future<void> setRefreshToken(String token) async {
    _cachedRefreshToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRefreshTokenKey, token);
    } catch (e) {
      debugPrint("⚠️ [ApiBase.setRefreshToken] SharedPreferences warning: $e");
    }
  }

  static Future<void> clearTokens() async {
    _cachedJwt = null;
    _cachedRefreshToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kJwtTokenKey);
      await prefs.remove(_kRefreshTokenKey);
    } catch (e) {
      debugPrint("⚠️ [ApiBase.clearTokens] SharedPreferences warning: $e");
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final headers = <String, String>{
      "Content-Type": "application/json",
      "app-version": ApiRoutes.instance.version.toString(),
    };
    try {
      final jwt = await getJwt();
      if (jwt != null && jwt.isNotEmpty) {
        headers["Authorization"] = "Bearer $jwt";
      }
    } catch (e) {
      debugPrint("⚠️ [ApiBase.getHeaders] Could not load auth header: $e");
    }
    return headers;
  }

  static Future<APIResponse> newGetRequest(
    String endpoint, [
    Map<String, dynamic>? queryParams,
  ]) async {
    try {
      final baseUrl = ApiRoutes.instance.baseUrl;
      Uri uri = Uri.parse("$baseUrl$endpoint");
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        uri = uri.replace(queryParameters: stringParams);
      }

      final headers = await getHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint("❌ [GET Request Error] $endpoint: $e");
      return APIResponse(
        success: false,
        map: {"detail": "Network error or server unreachable: $e"},
        networkError: true,
      );
    }
  }

  static Future<APIResponse> newPostRequest(
    String endpoint,
    dynamic body,
  ) async {
    try {
      final baseUrl = ApiRoutes.instance.baseUrl;
      final uri = Uri.parse("$baseUrl$endpoint");
      final headers = await getHeaders();

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint("❌ [POST Request Error] $endpoint: $e");
      return APIResponse(
        success: false,
        map: {"detail": "Network error or server unreachable: $e"},
        networkError: true,
      );
    }
  }

  static Future<APIResponse> newPutRequest(
    String endpoint,
    dynamic body,
  ) async {
    try {
      final baseUrl = ApiRoutes.instance.baseUrl;
      final uri = Uri.parse("$baseUrl$endpoint");
      final headers = await getHeaders();

      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint("❌ [PUT Request Error] $endpoint: $e");
      return APIResponse(
        success: false,
        map: {"detail": "Network error or server unreachable: $e"},
        networkError: true,
      );
    }
  }

  static Future<APIResponse> newPatchRequest(
    String endpoint,
    dynamic body,
  ) async {
    try {
      final baseUrl = ApiRoutes.instance.baseUrl;
      final uri = Uri.parse("$baseUrl$endpoint");
      final headers = await getHeaders();

      final response = await http
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint("❌ [PATCH Request Error] $endpoint: $e");
      return APIResponse(
        success: false,
        map: {"detail": "Network error or server unreachable: $e"},
        networkError: true,
      );
    }
  }

  static Future<APIResponse> newDeleteRequest(
    String endpoint, [
    dynamic body,
  ]) async {
    try {
      final baseUrl = ApiRoutes.instance.baseUrl;
      final uri = Uri.parse("$baseUrl$endpoint");
      final headers = await getHeaders();

      final response = await http
          .delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      debugPrint("❌ [DELETE Request Error] $endpoint: $e");
      return APIResponse(
        success: false,
        map: {"detail": "Network error or server unreachable: $e"},
        networkError: true,
      );
    }
  }

  static APIResponse _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      if (decoded is Map) {
        return APIResponse(success: isSuccess, map: decoded);
      }
      return APIResponse(
        success: isSuccess,
        map: {"detail": response.body, "item": decoded},
      );
    } catch (e) {
      return APIResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        map: {"detail": response.body},
      );
    }
  }
}
