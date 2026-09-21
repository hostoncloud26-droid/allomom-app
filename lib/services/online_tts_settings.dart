/// Where the online voice lives, and whether it is used at all.
///
/// AlloBot speaks with whatever is nearest to a real recording: the clip an
/// intent already carries, then — if a mother has pointed the app at an
/// OmniVoice server and switched it on — a clip synthesised there, and only
/// then the phone's own engine. This holds the two answers that choice needs,
/// so the setting survives a restart and every speaker reads the same one.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineTtsSettings extends GetxController {
  static const String _kEnabled = 'allomom_online_tts_enabled';
  static const String _kBaseUrl = 'allomom_online_tts_base_url';

  /// What the field is pre-filled with the first time it is opened — the
  /// emulator's route to a server running on the development machine.
  // static const String defaultBaseUrl = 'http://10.0.2.2:7860';
  static const String defaultBaseUrl = "http://47.29.133.221:30834";

  static OnlineTtsSettings get instance => Get.isRegistered<OnlineTtsSettings>()
      ? Get.find<OnlineTtsSettings>()
      : Get.put(OnlineTtsSettings(), permanent: true);

  final RxBool isEnabled = false.obs;
  final RxString baseUrl = ''.obs;

  /// The read in flight, shared by every caller.
  ///
  /// A plain `bool _loaded` set before the await handed the second caller an
  /// empty URL while the first was still reading it — and the settings screen
  /// then saved that empty field back over the stored one, so the online
  /// voice was switched on and pointed nowhere.
  Future<void>? _loading;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// The URL with any trailing slash removed, or empty when nothing usable is
  /// stored. Callers treat empty as "no server", never as "try the default".
  String get resolvedBaseUrl {
    final url = baseUrl.value.trim();
    if (url.isEmpty) return '';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Whether a clip should be asked for at all: switched on *and* pointed
  /// somewhere. A toggle with an empty field would otherwise cost every reply
  /// a timeout before the phone's own voice took over.
  bool get isUsable => isEnabled.value && resolvedBaseUrl.isNotEmpty;

  /// Reads the stored settings, or waits for the read already running.
  Future<void> load() => _loading ??= _read();

  Future<void> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isEnabled.value = prefs.getBool(_kEnabled) ?? false;
      // A blank stored URL is treated as never set, which also repairs the
      // installs where an empty field was saved over the real address.
      final stored = prefs.getString(_kBaseUrl)?.trim() ?? '';
      baseUrl.value = stored.isEmpty ? defaultBaseUrl : stored;
    } catch (e) {
      debugPrint('OnlineTtsSettings: could not read settings: $e');
      baseUrl.value = defaultBaseUrl;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    isEnabled.value = enabled;
    await _write((prefs) => prefs.setBool(_kEnabled, enabled));
  }

  Future<void> setBaseUrl(String url) async {
    final clean = url.trim();
    if (clean == baseUrl.value) return;
    baseUrl.value = clean;
    await _write((prefs) => prefs.setString(_kBaseUrl, clean));
  }

  Future<void> _write(Future<void> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('OnlineTtsSettings: could not save settings: $e');
    }
  }
}
