import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/auth_api.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/auth/secure_token_store.dart';
import 'package:allomom/services/sync/sync_service.dart';

/// The result of a verify-OTP round trip, as the OTP screen needs it.
class SignInOutcome {
  const SignInOutcome({
    required this.success,
    required this.isRegistered,
    required this.isNewUser,
    this.message = '',
  });

  const SignInOutcome.failure(this.message)
    : success = false,
      isRegistered = false,
      isNewUser = false;

  final bool success;

  /// False sends the app into the registration flow, true to the main screen.
  final bool isRegistered;
  final bool isNewUser;
  final String message;
}

/// Phone + OTP sign-in, token lifetime, and sign-out.
class AuthController extends GetxController {
  static AuthController get instance => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController._(), permanent: true);

  AuthController._();

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  /// Set by the app shell so an expired session can route back to sign-in.
  void Function()? onSignedOut;

  /// Wires the transport's session-expired hook to this controller.
  void init() {
    ApiBase.onSessionExpired = () {
      debugPrint('ℹ️ [AuthController] session expired, signing out');
      _forgetSession();
    };
  }

  bool get isAuthenticated => SecureTokenStore.instance.hasSession;

  // ── OTP ────────────────────────────────────────────────────────────────────

  /// Requests a code. Returns null on success, or a message to show.
  Future<String?> sendOtp(String phone, {String countryCode = '+91'}) async {
    _setBusy(true);
    try {
      final response = await AuthApi.sendOtp(phone, countryCode: countryCode);
      if (response.success) return null;
      return response.detail.isNotEmpty
          ? response.detail
          : 'Could not send the code. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> resendOtp(String phone, {String countryCode = '+91'}) async {
    _setBusy(true);
    try {
      final response = await AuthApi.resendOtp(phone, countryCode: countryCode);
      if (response.success) return null;
      return response.detail.isNotEmpty
          ? response.detail
          : 'Could not resend the code. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  /// Verifies the code, stores the tokens, and seeds the local database.
  ///
  /// The seed is awaited rather than backgrounded: the screen that follows
  /// decides what to show from the local user row, so navigating before it
  /// lands would flash an empty state.
  Future<SignInOutcome> verifyOtp({
    required String phone,
    required String otp,
    String countryCode = '+91',
    String? fcmToken,
  }) async {
    _setBusy(true);
    try {
      final response = await AuthApi.verifyOtp(
        phone: phone,
        otp: otp,
        countryCode: countryCode,
        deviceType: _deviceType,
        fcmToken: fcmToken,
      );

      if (!response.success) {
        return SignInOutcome.failure(
          response.detail.isNotEmpty
              ? response.detail
              : 'Could not verify the code. Please try again.',
        );
      }

      final result = AuthResult.fromItem(response.item);
      if (result == null) {
        return const SignInOutcome.failure(
          'The server response was not understood. Please try again.',
        );
      }

      final main = MainController.instance;

      // A different person signing in on this device must not inherit the
      // previous account's local rows.
      final previousUserId = SecureTokenStore.instance.userId;
      if (previousUserId != null && previousUserId != result.userId) {
        await main.clearSession();
        await SyncService.instance.resetWatermarks();
      }

      await SecureTokenStore.instance.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userId: result.userId,
        loginId: result.loginId,
      );

      await SyncService.instance.seedFromServer();
      await main.loadFromLocal();
      SyncService.instance.start();

      return SignInOutcome(
        success: true,
        // Prefer the freshly seeded local row, falling back to the token
        // response if the seed could not complete offline.
        isRegistered: main.currentUser?.isRegistered ?? result.isRegistered,
        isNewUser: result.isNewUser,
        message: response.detail,
      );
    } finally {
      _setBusy(false);
    }
  }

  // ── Sign-out ───────────────────────────────────────────────────────────────

  /// Revokes the session server-side, then clears the device.
  ///
  /// The local wipe happens whether or not the network call lands — refusing to
  /// sign out because the server is unreachable would leave the account on a
  /// device the user is trying to hand over.
  Future<void> logout({bool allDevices = false}) async {
    _setBusy(true);
    try {
      try {
        await AuthApi.logout(allDevices: allDevices);
      } catch (e) {
        debugPrint('ℹ️ [AuthController] server sign-out did not complete: $e');
      }
      await _forgetSession();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _forgetSession() async {
    await SecureTokenStore.instance.clear();
    await MainController.instance.clearSession();
    await SyncService.instance.resetWatermarks();
    onSignedOut?.call();
    update();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    update();
  }

  static String get _deviceType {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
