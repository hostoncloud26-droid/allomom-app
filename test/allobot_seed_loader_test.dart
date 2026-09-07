import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/allobot/allobot_seed_loader.dart';

void main() {
  // A real binding with real timers. `testWidgets` runs inside fake async,
  // where the loader's manifest timeout is a Timer that never fires and an
  // asset read that does not resolve hangs the test outright.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('topicLabelFromPath', () {
    test('strips the long sheet-name prefix', () {
      expect(
        AlloBotSeedLoader.topicLabelFromPath(
          'lib/seeds/Allobaby - Q and A - Nutrition & Diet.csv',
        ),
        'Nutrition & Diet',
      );
    });

    test('keeps the label spelled as Topics.csv spells it', () {
      // These have to match the Category column exactly, or the sheet does not
      // inherit its canonical topic key.
      expect(
        AlloBotSeedLoader.topicLabelFromPath(
          'lib/seeds/Allobaby - Q and A - Risk & Warning Signs.csv',
        ),
        'Risk & Warning Signs',
      );
    });

    test('title-cases the snake_case sheets', () {
      expect(
        AlloBotSeedLoader.topicLabelFromPath(
          'lib/seeds/Allobaby - Q and A - fruit_questions.csv',
        ),
        'Fruit Questions',
      );
    });

    test('identifies the Topics sheet', () {
      expect(
        AlloBotSeedLoader.topicLabelFromPath(
          'lib/seeds/Allobaby - Q and A - Topics.csv',
        ),
        'Topics',
      );
    });
  });

  group('load', () {
    setUp(AlloBotSeedLoader.resetCache);

    test('finds and indexes the seeds through the asset bundle', () async {
      // Proves the pubspec registration works end to end. The filenames carry
      // spaces, ampersands and an en dash, so discovery going through
      // AssetManifest rather than a hardcoded list is what makes this hold.
      final knowledgeBase = await AlloBotSeedLoader.load();

      expect(knowledgeBase.isEmpty, isFalse);
      expect(knowledgeBase.size, greaterThan(180));
      expect(knowledgeBase.topics, isNotEmpty);
    });

    test('caches the corpus rather than reparsing it', () async {
      final first = await AlloBotSeedLoader.load();
      final second = await AlloBotSeedLoader.load();
      expect(identical(first, second), isTrue);
    });
  });
}
