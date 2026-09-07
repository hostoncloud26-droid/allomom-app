import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/allobot/allobot_knowledge_base.dart';
import 'package:allomom/services/allobot/allobot_seed_loader.dart';

/// Builds the corpus from the real sheets on disk.
///
/// The asset bundle is not available in a plain unit test, so the loader's file
/// discovery is replicated here — deliberately, because the point of these
/// tests is to run against the actual authored CSVs rather than a fixture that
/// would drift away from them.
AlloBotKnowledgeBase buildFromRealSeeds() {
  final sheets = <String, String>{};
  String? topicsCsv;

  for (final file in Directory('lib/seeds').listSync().whereType<File>()) {
    if (!file.path.endsWith('.csv')) continue;
    final label = AlloBotSeedLoader.topicLabelFromPath(file.path);
    final contents = file.readAsStringSync();
    if (label == 'Topics') {
      topicsCsv = contents;
      continue;
    }
    sheets[label] = contents;
  }

  return AlloBotKnowledgeBase.build(sheets: sheets, topicsCsv: topicsCsv);
}

void main() {
  group('normalizeSeedHeader', () {
    test('folds the two spellings of the voiceover columns together', () {
      expect(
        normalizeSeedHeader('Allobaby Response (English) Voice over'),
        'allobaby response english voiceover',
      );
      expect(
        normalizeSeedHeader('Allobaby Response (English Voiceover)'),
        'allobaby response english voiceover',
      );
    });

    test('strips curly apostrophes and underscores', () {
      expect(
        normalizeSeedHeader('Mother’s Question (Tamil – Natural)'),
        'mothers question tamil natural',
      );
      expect(
        normalizeSeedHeader('Allobababy_response- Voice(HINDI)'),
        'allobababy response voice hindi',
      );
    });
  });

  group('classifySeedHeader', () {
    test('classifies the Pregnancy Basics header', () {
      final columns = classifySeedHeader([
        'Key',
        'Mother’s Question (English)',
        'Allobaby Response (English)',
        'Allobaby Response (English) Voice over',
        'Next Trigger Question (Baby Voice) Eng',
        'Next Trigger Question (Baby Voice over)',
      ]);

      expect(columns[0].role, SeedRole.key);
      expect(columns[1].role, SeedRole.question);
      expect(columns[2].role, SeedRole.answer);
      expect(columns[3].role, SeedRole.voice);
      // "(Baby Voice)" is a tone note on real text, not an mp3 column.
      expect(columns[4].role, SeedRole.followUp);
      expect(columns[5].role, SeedRole.voice);
      expect(columns.skip(1).every((c) => c.language == 'en'), isTrue);
    });

    test('classifies the Risk sheet header, which names columns differently', () {
      final columns = classifySeedHeader([
        'Keywords',
        'Question (English) ',
        'Allobaby - English',
        'Allobaby - English voice over',
        'Next Question',
        'Trigger Question Voice Over',
      ]);

      expect(columns[0].role, SeedRole.key);
      expect(columns[1].role, SeedRole.question);
      // No "response" in the name at all — only "Allobaby".
      expect(columns[2].role, SeedRole.answer);
      expect(columns[3].role, SeedRole.voice);
      // No language and no "trigger" — inherits English from its block.
      expect(columns[4].role, SeedRole.followUp);
      expect(columns[4].language, 'en');
      expect(columns[5].role, SeedRole.voice);
    });

    test('a column with no language tag inherits its block', () {
      final columns = classifySeedHeader([
        'Keyword',
        'Mother’s Question (Tamil – Natural)',
        'Allobaby Response (Tamil – Casual & Friendly)',
        'Next Trigger Question-Tamil(Baby Voice)',
      ]);
      expect(columns[1].language, 'ta');
      expect(columns[3].language, 'ta');
    });

    test('a non-English tag beats English in the same header', () {
      // `Gujarathi-English` is a romanised Gujarati column. Reading it as
      // English would overwrite the real English answer.
      final columns = classifySeedHeader([
        'Keyword',
        'Allobaby Response (English)',
        'Allobaby Response (Gujarathi – Baby Tone)',
        'Gujarathi-English',
      ]);
      expect(columns[1].language, 'en');
      expect(columns[2].language, 'gu');
      expect(columns[3].language, 'gu');
    });
  });

  group('looksLikeAudioAsset', () {
    test('recognises mp3 cells', () {
      expect(looksLikeAudioAsset('1.mp3'), isTrue);
      expect(looksLikeAudioAsset('mango_eating_en.mp3'), isTrue);
      expect(looksLikeAudioAsset('eatspinach_eng - Copy.mp3'), isTrue);
    });

    test('does not mistake prose for a filename', () {
      expect(looksLikeAudioAsset('Yes mom, you can eat mangoes.'), isFalse);
      expect(looksLikeAudioAsset(''), isFalse);
    });
  });

  group('tokenizeForSearch', () {
    test('drops stop words', () {
      expect(tokenizeForSearch('Can I eat a mango?'), ['eat', 'mango']);
    });

    test('folds plurals and -ing forms onto one term', () {
      expect(tokenizeForSearch('kicking'), tokenizeForSearch('kicks'));
      expect(tokenizeForSearch('delivery'), tokenizeForSearch('deliveries'));
    });

    test('folds irregular forms the stemmer cannot reach', () {
      // Mothers write "swollen"; the sheets say "swelling".
      expect(tokenizeForSearch('swollen'), tokenizeForSearch('swelling'));
      expect(tokenizeForSearch('labour'), tokenizeForSearch('labor'));
      expect(tokenizeForSearch('anaemia'), tokenizeForSearch('anemia'));
    });

    test('keeps non-Latin scripts', () {
      expect(tokenizeForSearch('மாம்பழம் சாப்பிடலாமா'), hasLength(2));
      expect(tokenizeForSearch('क्या मैं आम खा सकती हूँ'), isNotEmpty);
    });
  });

  group('AlloBotKnowledgeBase.build with a hand-made sheet', () {
    test('takes the authored text and skips the mp3 column', () {
      const csv = 'Keyword,Mother\'s question (English),Allobaby Response (English),'
          'Allobaby Response (English Voiceover),Next Trigger Question (Baby Voice)\n'
          'mango_eating,"Can I eat mangoes?","Yes mom, in moderation.",'
          'mango_eating_en.mp3,"Want to know how much?"\n';

      final kb = AlloBotKnowledgeBase.build(sheets: {'Fruit Questions': csv});

      expect(kb.size, 1);
      final entry = kb.entries.single;
      expect(entry.slug, 'mango_eating');
      expect(entry.question, 'Can I eat mangoes?');
      expect(entry.answer, 'Yes mom, in moderation.');
      expect(entry.followUp, 'Want to know how much?');
      expect(entry.english.voiceAsset, 'mango_eating_en.mp3');
    });

    test('reads an answer column whose every cell is an mp3 as a voiceover', () {
      // `Allobababy_response- Voice(HINDI)` names neither "voiceover" nor
      // "voice over", so only the cell contents give it away.
      const csv = 'Key,Mother’s Question (Hindi – Natural),'
          'Allobaby Response (Hindi – Baby Tone),Allobababy_response- Voice(HINDI),'
          'Allobaby Response (English),Mother’s Question (English)\n'
          'x,"क्या मैं आम खा सकती हूँ?","हाँ मां।",1.mp3,"Yes mom.","Can I eat mango?"\n';

      final kb = AlloBotKnowledgeBase.build(sheets: {'Fruit Questions': csv});
      final entry = kb.entries.single;

      expect(entry.localeFor('hi').answer, 'हाँ मां।');
      expect(entry.localeFor('hi').voiceAsset, '1.mp3');
    });

    test('skips rows with no English answer', () {
      const csv = 'Key,Mother’s Question (English),Allobaby Response (English)\n'
          'a,"A question?","An answer."\n'
          'b,"Another question?",""\n';

      final kb = AlloBotKnowledgeBase.build(sheets: {'Pregnancy Basics': csv});
      expect(kb.size, 1);
    });

    test('falls back to English for a language the sheet lacks', () {
      const csv = 'Key,Mother’s Question (English),Allobaby Response (English)\n'
          'a,"A question?","An answer."\n';

      final kb = AlloBotKnowledgeBase.build(sheets: {'Pregnancy Basics': csv});
      // Kannada is on the app's picker but not in the sheets.
      expect(kb.entries.single.localeFor('kn').answer, 'An answer.');
    });
  });

  group('the real seed sheets', () {
    late AlloBotKnowledgeBase kb;

    setUpAll(() => kb = buildFromRealSeeds());

    test('every sheet contributes rows', () {
      final topics = kb.entries.map((e) => e.topicKey).toSet();
      // Thirteen Q&A sheets plus Topics.csv, which is metadata.
      expect(topics.length, 13);
      expect(kb.size, greaterThan(180));
    });

    test('lines up sheet names with the canonical keys in Topics.csv', () {
      final keys = kb.entries.map((e) => e.topicKey).toSet();
      expect(keys, contains('nutrition_diet'));
      expect(keys, contains('risk_warning_signs'));
      expect(keys, contains('pregnancy_basics'));
      // The two snake_case sheets have no Topics.csv row and get slugged.
      expect(keys, contains('fruit_questions'));
      expect(keys, contains('vegetable_questions'));
    });

    test('no answer is an mp3 filename', () {
      for (final entry in kb.entries) {
        for (final locale in entry.locales.values) {
          expect(
            looksLikeAudioAsset(locale.answer),
            isFalse,
            reason: 'audio leaked into ${entry.id}: ${locale.answer}',
          );
        }
      }
    });

    test('no answer keeps its wrapping quotes', () {
      for (final entry in kb.entries) {
        expect(entry.answer.startsWith('"'), isFalse, reason: entry.id);
        expect(entry.answer.endsWith('"'), isFalse, reason: entry.id);
      }
    });

    test('translations are carried, not just English', () {
      final translated = kb.entries
          .where((e) => e.availableLanguages.length > 1)
          .length;
      // The sheets are unevenly translated, but the bulk of rows have more
      // than English.
      expect(translated, greaterThan(kb.size ~/ 2));
    });

    test('most rows carry a follow-up question to chain on', () {
      final withFollowUp =
          kb.entries.where((e) => e.followUp.isNotEmpty).length;
      expect(withFollowUp, greaterThan(kb.size ~/ 2));
    });

    test('parses topic sample questions out of their single crammed cell', () {
      final basics = kb.topics.firstWhere((t) => t.key.trim() == 'pregnancy_basics');
      expect(basics.label, 'Pregnancy Basics');
      expect(basics.sampleQuestions, contains('Am I really pregnant?'));
      expect(basics.sampleQuestions.length, greaterThan(3));
    });
  });
}
