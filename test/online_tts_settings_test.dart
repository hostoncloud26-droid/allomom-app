import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/services/online_tts_settings.dart';

void main() {
  group('Online voice settings', () {
    tearDown(Get.reset);

    test('two loads racing both see the stored address', () async {
      SharedPreferences.setMockInitialValues({
        'allomom_online_tts_enabled': true,
        'allomom_online_tts_base_url': 'http://192.168.0.141:7860/',
      });
      final settings = OnlineTtsSettings();

      // What the settings screen and the speaker do: ask at the same moment.
      await Future.wait([settings.load(), settings.load()]);

      expect(settings.resolvedBaseUrl, 'http://192.168.0.141:7860');
      expect(settings.isUsable, isTrue);
    });

    test('a blank stored address falls back to the default', () async {
      SharedPreferences.setMockInitialValues({
        'allomom_online_tts_enabled': true,
        'allomom_online_tts_base_url': '   ',
      });
      final settings = OnlineTtsSettings();
      await settings.load();

      expect(settings.resolvedBaseUrl, OnlineTtsSettings.defaultBaseUrl);
    });

    test('switched off, or pointed nowhere, is not usable', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = OnlineTtsSettings();
      await settings.load();

      expect(settings.isEnabled.value, isFalse);
      expect(settings.isUsable, isFalse);

      await settings.setEnabled(true);
      expect(settings.isUsable, isTrue);

      await settings.setBaseUrl('');
      expect(settings.isUsable, isFalse);
    });
  });
}
