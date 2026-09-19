import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:allomom/api/api_routes.dart';
import 'package:allomom/api/response.dart';
import 'package:allomom/services/auth/secure_token_store.dart';

/// The HTTP layer.
///
/// Two things it owns beyond issuing requests. Tokens come from
/// [SecureTokenStore], never SharedPreferences. And a 401 on an authenticated
/// call is transparently retried once after refreshing the token pair, so a
/// screen never has to think about an access token ageing out mid-session; if
/// the refresh itself fails the session is cleared and [onSessionExpired] fires,
/// which is what sends the app back to the sign-in screen.
class ApiBase {
  /// What an ordinary call is given. Enough for a round trip and a database
  /// query, and short enough that a screen on a dead connection says so rather
  /// than spinning.
  static const Duration _timeout = Duration(seconds: 20);

  /// A slow call passes its own instead — inference against a model, with a
  /// whole transcript folded into the prompt, routinely outlasts 20 seconds,
  /// and the app was giving up on answers the server had already produced.
  static Duration _timeoutFor(Duration? override) => override ?? _timeout;

  /// Called when the refresh token is rejected, i.e. the session is truly over.
  /// Set by the auth controller at startup.
  static void Function()? onSessionExpired;

  /// Guards against a burst of parallel 401s each kicking off its own refresh.
  /// The first caller performs the exchange and the rest await the same future.
  static Future<bool>? _refreshInFlight;

  static Future<void> init() => SecureTokenStore.instance.init();

  static Future<Map<String, String>> getHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'app-version': ApiRoutes.instance.version.toString(),
    };
    if (withAuth) {
      final token = SecureTokenStore.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── Verbs ──────────────────────────────────────────────────────────────────

  static Future<APIResponse> get(
    String endpoint, {
    Map<String, dynamic>? query,
    bool withAuth = true,
    Duration? timeout,
  }) => _send('GET', endpoint, query: query, withAuth: withAuth,
      timeout: timeout);

  static Future<APIResponse> post(
    String endpoint,
    dynamic body, {
    bool withAuth = true,
    Duration? timeout,
  }) => _send('POST', endpoint, body: body, withAuth: withAuth,
      timeout: timeout);

  static Future<APIResponse> patch(
    String endpoint,
    dynamic body, {
    bool withAuth = true,
  }) => _send('PATCH', endpoint, body: body, withAuth: withAuth);

  static Future<APIResponse> put(
    String endpoint,
    dynamic body, {
    bool withAuth = true,
  }) => _send('PUT', endpoint, body: body, withAuth: withAuth);

  static Future<APIResponse> delete(
    String endpoint, {
    dynamic body,
    bool withAuth = true,
  }) => _send('DELETE', endpoint, body: body, withAuth: withAuth);

  // Kept so existing call sites keep compiling while they migrate to the
  // shorter names above.
  static Future<APIResponse> newGetRequest(
    String endpoint, [
    Map<String, dynamic>? query,
  ]) => get(endpoint, query: query);
  static Future<APIResponse> newPostRequest(String endpoint, dynamic body) =>
      post(endpoint, body);
  static Future<APIResponse> newPatchRequest(String endpoint, dynamic body) =>
      patch(endpoint, body);
  static Future<APIResponse> newPutRequest(String endpoint, dynamic body) =>
      put(endpoint, body);
  static Future<APIResponse> newDeleteRequest(String endpoint, [dynamic body]) =>
      delete(endpoint, body: body);

  // ── Transport ──────────────────────────────────────────────────────────────

  static Future<APIResponse> _send(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? query,
    bool withAuth = true,
    bool isRetry = false,
    Duration? timeout,
  }) async {
    final deadline = _timeoutFor(timeout);
    try {
      var uri = Uri.parse('${ApiRoutes.instance.baseUrl}$endpoint');
      if (query != null && query.isNotEmpty) {
        uri = uri.replace(
          queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
        );
      }

      final headers = await getHeaders(withAuth: withAuth);
      final encoded = body == null ? null : jsonEncode(body);

      late http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(deadline);
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: encoded)
              .timeout(deadline);
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: encoded)
              .timeout(deadline);
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: encoded)
              .timeout(deadline);
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers, body: encoded)
              .timeout(deadline);
        default:
          throw UnsupportedError('Unsupported method $method');
      }

      // One retry, and only for a call that actually carried a token —
      // a 401 from an unauthenticated route means bad credentials, not a
      // stale session, and refreshing would loop.
      if (response.statusCode == 401 && withAuth && !isRetry) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return _send(
            method,
            endpoint,
            body: body,
            query: query,
            withAuth: withAuth,
            isRetry: true,
            // The retry is the same call, so it gets the same budget.
            timeout: timeout,
          );
        }
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ [$method $endpoint] $e');
      return APIResponse(
        success: false,
        map: {'detail': 'Network error or server unreachable'},
        networkError: true,
      );
    }
  }

  static Future<bool> _refreshToken() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static Future<bool> _performRefresh() async {
    final store = SecureTokenStore.instance;
    final refreshToken = store.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      onSessionExpired?.call();
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiRoutes.instance.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final item = jsonDecode(response.body)['item'];
        if (item is Map &&
            item['access_token'] != null &&
            item['refresh_token'] != null) {
          await store.updateTokens(
            accessToken: item['access_token'] as String,
            refreshToken: item['refresh_token'] as String,
          );
          return true;
        }
      }

      // A 4xx means the server has revoked or rotated past this token, so the
      // session is over. A 5xx or a timeout is transient and lands in the catch
      // below, where the session is left intact for the next attempt.
      if (response.statusCode >= 400 && response.statusCode < 500) {
        await store.clear();
        onSessionExpired?.call();
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ [ApiBase] token refresh failed: $e');
      return false;
    }
  }

  static APIResponse _handleResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return APIResponse(success: isSuccess, map: decoded);
      }
      return APIResponse(
        success: isSuccess,
        map: {'detail': response.body, 'item': decoded},
      );
    } catch (_) {
      return APIResponse(success: isSuccess, map: {'detail': response.body});
    }
  }
}
