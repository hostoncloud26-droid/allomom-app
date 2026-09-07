import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/allobot/allobot_retriever.dart';

import 'allobot_knowledge_base_test.dart' show buildFromRealSeeds;

/// Questions the seed corpus genuinely covers.
const inDomainQuestions = [
  'can I eat mangoes',
  'can I eat spinach during pregnancy',
  'how much water should I drink',
  'why does baby kick more at night',
  'I feel very tired all the time',
  'what should I pack for the hospital',
  'my back hurts a lot these days',
  'can I have coffee in the morning',
  'am I sleeping in the right position',
  'when will I feel my baby move',
  'how do I know labour has started',
  'is exercise ok during pregnancy',
  'can I fast during pregnancy',
  'my feet are swollen in the evening',
  'is papaya safe to eat',
  'how do I use the kick tracker',
  'is it safe to travel by bus',
  'i am having trouble sleeping at night',
];

/// Questions that have nothing to do with maternal health. Every one of these
/// must be refused rather than answered from a coincidental word match.
const offDomainQuestions = [
  'how do I fix my car engine',
  'what is the capital of france',
  'who won the cricket match yesterday',
  'can you write me a python script',
  'what is the price of gold today',
  'book me a flight to delhi',
  'how do I reset my wifi router',
  'what is the weather tomorrow',
  'tell me a joke about computers',
  'how much does an iphone cost',
  'explain quantum physics to me',
  'what is my bank balance',
  'recommend a movie to watch tonight',
  'how do I change a flat tyre',
];

void main() {
  late AlloBotRetriever retriever;

  setUpAll(() => retriever = AlloBotRetriever(buildFromRealSeeds()));

  group('in-domain questions', () {
    test('all are answerable', () {
      final refused = inDomainQuestions
          .where((question) => !retriever.search(question).isAnswerable)
          .toList();
      expect(refused, isEmpty);
    });

    test('an exact seed question scores very high', () {
      final result = retriever.search('How much water should I drink?');
      expect(result.best!.entry.question, 'How much water should I drink?');
      expect(result.best!.confidence, greaterThan(strongConfidenceThreshold));
    });

    test('finds the right row despite different wording', () {
      // The sheet says "legs swelling"; she says "feet are swollen".
      final result = retriever.search('my feet are swollen in the evening');
      expect(result.best!.entry.question, contains('swelling'));
      expect(result.isAnswerable, isTrue);
    });
  });

  group('off-domain questions', () {
    test('none are answerable', () {
      final answered = offDomainQuestions
          .where((question) => retriever.search(question).isAnswerable)
          .toList();
      expect(answered, isEmpty);
    });

    test('are refused on vocabulary overlap, not confidence alone', () {
      // The gate that matters: this scores a *higher* confidence than the
      // correct swollen-legs answer does, and is only caught because the corpus
      // does not know most of its words.
      final result = retriever.search('what is my bank balance');
      expect(result.vocabularyOverlap, lessThan(minVocabularyOverlap));
      expect(result.isAnswerable, isFalse);
    });

    test('an unknown but plausible topic is refused rather than guessed', () {
      // There is no jackfruit row. Answering with the nearest fruit would be
      // worse than admitting it.
      final result = retriever.search('is jackfruit safe during pregnancy');
      expect(result.isAnswerable, isFalse);
    });
  });

  group('multilingual retrieval', () {
    test('a Tamil question reaches the row English would find', () {
      final result = retriever.search('நான் மாம்பழம் சாப்பிடலாமா');
      expect(result.isAnswerable, isTrue);
      expect(result.best!.entry.slug, 'mango_eating');
    });

    test('separates near-identical translated questions', () {
      // The Tamil mango and pineapple questions differ by one word and score
      // within a percent of each other, so this is the tie the confidence
      // rerank exists for.
      final mango = retriever.search('நான் மாம்பழம் சாப்பிடலாமா');
      final pineapple = retriever.search('நான் அன்னாசி சாப்பிடலாமா');
      expect(mango.best!.entry.slug, 'mango_eating');
      expect(pineapple.best!.entry.slug, isNot('mango_eating'));
    });

    test('a Hindi question is answerable', () {
      final result = retriever.search('क्या मैं आम खा सकती हूँ');
      expect(result.isAnswerable, isTrue);
    });

    test('serves the answer in the language asked, falling back when absent', () {
      final entry = retriever.search('can I eat mangoes').best!.entry;
      expect(entry.localeFor('ta').answer, isNot(entry.english.answer));
      // Kannada has no columns in the sheets.
      expect(entry.localeFor('kn').answer, entry.english.answer);
    });
  });

  group('safety bias', () {
    test('an alarmed question lands on a row about the symptom', () {
      // Retrieval only has to find the right topic here. Escalating an actual
      // danger sign is the intent layer's job (`detectRedFlag`), which runs
      // before retrieval — so this deliberately does not assert the row comes
      // from a warning sheet: a question about bleeding landing on
      // "I am having mild/light bleeding, is this normal" is a good answer.
      final result = retriever.search('I am bleeding and very worried');
      expect(result.isAnswerable, isTrue);
      expect(result.best!.entry.question.toLowerCase(), contains('bleeding'));
      expect(result.best!.entry.isSafetyTopic, isTrue);
    });

    test('a calm question is not dragged into the danger-signs sheet', () {
      // "swelling" is ordinary in pregnancy, so it must not be treated as a
      // worry word.
      final result = retriever.search('is mild swelling in feet normal');
      expect(result.best!.entry.isSafetyTopic, isFalse);
    });
  });

  test('an empty query returns nothing', () {
    final result = retriever.search('   ');
    expect(result.isEmpty, isTrue);
    expect(result.isAnswerable, isFalse);
  });
}
