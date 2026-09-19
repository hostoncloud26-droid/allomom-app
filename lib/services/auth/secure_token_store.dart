import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the access and refresh tokens live.
///
/// The Keychain on iOS and the EncryptedSharedPreferences-backed Keystore on
/// Android, rather than plain SharedPreferences: a refresh token is a
/// year-long bearer credential, and on a rooted or jailbroken device plain
/// preferences are readable by anything on the box.
///
/// Reads are cached in memory because [ApiBase] asks for the access token on
/// every request and a Keychain round trip per call is needless overhead.
class SecureTokenStore {
  SecureTokenStore._();

  static final SecureTokenStore instance = SecureTokenStore._();

  static const _accessKey = 'allomom_access_token';
  static const _refreshKey = 'allomom_refresh_token';
  static const _userIdKey = 'allomom_user_id';
  static const _loginIdKey = 'allomom_login_id';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _loginId;
  bool _loaded = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get loginId => _loginId;

  bool get hasSession => (_accessToken?.isNotEmpty ?? false);

  /// Loads the cached values once at startup.
  ///
  /// A failure here is not fatal — a device whose Keystore is temporarily
  /// unavailable should land on the sign-in screen, not crash on launch.
  Future<void> init() async {
    if (_loaded) return;
    try {
      final values = await _storage.readAll();
      _accessToken = values[_accessKey];
      _refreshToken = values[_refreshKey];
      _userId = values[_userIdKey];
      _loginId = values[_loginIdKey];
    } catch (e) {
      debugPrint('⚠️ [SecureTokenStore] could not read secure storage: $e');
    }
    _loaded = true;
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? loginId,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    if (userId != null) _userId = userId;
    if (loginId != null) _loginId = loginId;
    _loaded = true;

    try {
      await Future.wait([
        _storage.write(key: _accessKey, value: accessToken),
        _storage.write(key: _refreshKey, value: refreshToken),
        if (userId != null) _storage.write(key: _userIdKey, value: userId),
        if (loginId != null) _storage.write(key: _loginIdKey, value: loginId),
      ]);
    } catch (e) {
      debugPrint('⚠️ [SecureTokenStore] could not persist tokens: $e');
    }
  }

  /// Replaces just the token pair after a refresh, leaving the identity alone.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) => save(
    accessToken: accessToken,
    refreshToken: refreshToken,
    userId: _userId,
    loginId: _loginId,
  );

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _loginId = null;
    try {
      await Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _loginIdKey),
      ]);
    } catch (e) {
      debugPrint('⚠️ [SecureTokenStore] could not clear secure storage: $e');
    }
  }
}
