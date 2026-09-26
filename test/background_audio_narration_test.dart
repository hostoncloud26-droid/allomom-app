import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/background_audio/data/narration_catalog.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';

/// The baby's background voice: the keyword catalogue behind it, and the card
/// that shows what it is saying.
///
/// The failure this guards is a silent one. A keyword with no clip, or a clip
/// with no catalogue line, does not crash or log — the screen simply never
/// speaks, which nobody notices until a mother with the sound on gets nothing.
/// So the whole catalogue is checked against what is actually bundled.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Every key declared on [NarrationKeys], read off the source rather than
  /// listed again here — a key added there but forgotten everywhere else is
  /// exactly what these tests are for.
  final declaredKeys = _declaredNarrationKeys();

  final onboardingKeys = declaredKeys
      .where((k) => NarrationCatalog.groupFor(k) == NarrationGroup.onboarding)
      .toSet();
  final screenKeys = declaredKeys
      .where((k) => NarrationCatalog.groupFor(k) == NarrationGroup.screens)
      .toSet();

  group('the narration catalogue', () {
    test('declares the whole onboarding script', () {
      expect(onboardingKeys, hasLength(82));
    });

    test('declares a line for every in-app screen', () {
      expect(screenKeys, hasLength(79));
    });

    test('has a line for every key', () {
      final missing = declaredKeys
          .where((key) => (NarrationCatalog.textFor(key) ?? '').isEmpty)
          .toList();
      expect(missing, isEmpty, reason: 'keys with no text: $missing');
    });

    test('has no line that belongs to no key', () {
      expect(NarrationCatalog.keys.toSet(), declaredKeys.toSet());
    });

    test('has a bundled clip for every key', () {
      // `pg_settings_open` has a line but no recording yet. A key in this list
      // still shows its text on the card and simply stays silent; the list is
      // here so a *new* gap fails the build rather than going unnoticed.
      const awaitingRecording = {
        NarrationKeys.pgSettingsOpen,
        // Welcome-your-baby steps: read aloud by TTS until recorded.
        NarrationKeys.pgBirthDate,
        NarrationKeys.pgBirthDetails,
        NarrationKeys.pgBirthPhoto,
      };

      final missing = declaredKeys
          .where((key) => !awaitingRecording.contains(key))
          .where(
            (key) => !File(
              NarrationCatalog.assetPath(
                NarrationCatalog.fallbackLanguage,
                key,
              ),
            ).existsSync(),
          )
          .toList();
      expect(missing, isEmpty, reason: 'keys with no mp3: $missing');
    });

    test('ships every clip folder in pubspec, or none of them load', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final group in NarrationGroup.values) {
        expect(
          pubspec,
          contains(
            '- assets/audio/${NarrationCatalog.fallbackLanguage}/'
            '${group.folder}/',
          ),
          reason: '${group.name} clips are not bundled',
        );
      }
    });

    test('names each batch of files the way it was delivered', () {
      expect(
        NarrationCatalog.assetPath('en', NarrationKeys.onbLang),
        'assets/audio/en/onboard/onb_lang.mp3',
      );
      expect(
        NarrationCatalog.assetPath('en', NarrationKeys.pgHomeOpen),
        'assets/audio/en/screens/pg_home_open_en.mp3',
      );
    });
  });

  group('every key is reachable', () {
    /// A key with a clip, a line and no call site is the quietest possible
    /// bug: nothing logs, nothing fails, the screen simply never speaks. The
    /// only way to catch it is to look for the constant in the app's source.
    test('each key is referenced by a screen', () {
      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          // The keys file declares them and the catalogue gives them text;
          // neither counts as a screen playing one. `narration_flow.dart` does
          // count — its getters are what the shared screens call.
          .where(
            (f) =>
                !f.path.endsWith('narration_keys.dart') &&
                !f.path.endsWith('narration_catalog.dart'),
          )
          .map((f) => f.readAsStringSync())
          .join('\n');

      final referenced = RegExp(r'NarrationKeys\.(\w+)')
          .allMatches(sources)
          .map((m) => m.group(1)!)
          .toSet();

      final declared = RegExp(r'static const (\w+) =')
          .allMatches(
            File(
              'lib/features/background_audio/data/narration_keys.dart',
            ).readAsStringSync(),
          )
          .map((m) => m.group(1)!)
          .toSet();

      final orphans = declared.difference(referenced).toList()..sort();
      expect(orphans, isEmpty, reason: 'keys nothing plays: $orphans');
    });
  });

  group('picking a line for the journey', () {
    test('reads the registration status labels', () {
      expect(NarrationFlowKeys.of('Pregnant'), NarrationFlow.pregnant);
      expect(NarrationFlowKeys.of('New Mom'), NarrationFlow.newMom);
      expect(
        NarrationFlowKeys.of('Pre Pregnancy'),
        NarrationFlow.prePregnancy,
      );
    });

    test('"Pre Pregnancy" is not read as pregnant', () {
      // It contains "pregnan", so a naive match sends a mother who is planning
      // down the pregnancy script.
      expect(
        NarrationFlowKeys.of('Pre Pregnancy').partner,
        NarrationKeys.prePartner,
      );
    });

    test('each journey gets its own home welcome', () {
      final welcomes = NarrationFlow.values.map((f) => f.homeWelcome).toSet();
      expect(welcomes, hasLength(NarrationFlow.values.length));
    });
  });

  group('choosing the line from the dates', () {
    test('trimester follows the weeks since the LMP', () {
      final now = DateTime(2026, 9, 19);
      DateTime weeksAgo(int weeks) => now.subtract(Duration(days: weeks * 7));

      String at(int weeks) =>
          trimesterNarrationKey(weeksAgo(weeks), now: now);

      expect(at(0), NarrationKeys.pregLmpStageT1);
      expect(at(13), NarrationKeys.pregLmpStageT1);
      expect(at(14), NarrationKeys.pregLmpStageT2);
      expect(at(27), NarrationKeys.pregLmpStageT2);
      expect(at(28), NarrationKeys.pregLmpStageT3);
      expect(at(39), NarrationKeys.pregLmpStageT3);
    });

    test('the countdown bands run from the whole journey down to any day', () {
      String at(int days) => countdownNarrationKey(days);

      expect(at(250), NarrationKeys.pregEddCountdownFar);
      expect(at(141), NarrationKeys.pregEddCountdownFar);
      expect(at(140), NarrationKeys.pregEddCountdownHalf);
      expect(at(61), NarrationKeys.pregEddCountdownHalf);
      expect(at(60), NarrationKeys.pregEddCountdownNear);
      expect(at(15), NarrationKeys.pregEddCountdownNear);
      expect(at(14), NarrationKeys.pregEddCountdownSoon);
      expect(at(0), NarrationKeys.pregEddCountdownSoon);
    });
  });

  group('the baby head card', () {
    /// With no controller registered — a widget test, or a screen pumped
    /// before `main()` has run — the card must still show the line rather than
    /// falling back to a blank bubble.
    Future<void> pumpCard(WidgetTester tester, Widget card) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: card)),
      );
      await tester.pump();
    }

    testWidgets('shows the line for its key', (tester) async {
      await pumpCard(
        tester,
        const BabyHeroBanner(
          narrationKey: NarrationKeys.onbRole,
          speechText: 'the screen copy',
        ),
      );

      expect(find.text('Yay! Are you my Mommy, or my Daddy?'), findsOneWidget);
      expect(find.text('the screen copy'), findsNothing);
    });

    testWidgets('keeps the screen copy when the line is only for playback', (
      tester,
    ) async {
      // `bindNarrationText: false` is how a feature screen borrows the voice
      // without giving up a card that says something the script cannot.
      await pumpCard(
        tester,
        const BabyHeroBanner(
          narrationKey: NarrationKeys.newFeedingIntro,
          bindNarrationText: false,
          speechText: "Time for baby's feed!",
        ),
      );

      expect(find.text("Time for baby's feed!"), findsOneWidget);
    });

    testWidgets('an unbound card is unchanged', (tester) async {
      await pumpCard(tester, const BabyHeroBanner(speechText: 'just copy'));

      expect(find.text('just copy'), findsOneWidget);
    });

    testWidgets('the slim bar shows its line too', (tester) async {
      await pumpCard(
        tester,
        const BabyPromptBar(narrationKey: NarrationKeys.newBabyName),
      );

      expect(find.text('What name did you give me?'), findsOneWidget);
    });
  });
}

/// Parses the constants off `narration_keys.dart`.
Set<String> _declaredNarrationKeys() {
  final source = File(
    'lib/features/background_audio/data/narration_keys.dart',
  ).readAsStringSync();
  return RegExp(r"static const \w+ = '([a-z0-9_]+)';")
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
}
