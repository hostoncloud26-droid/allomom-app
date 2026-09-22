import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';

/// What a flow step speaks when it names an `audio_key` rather than a URL.
///
/// A key is how the weekly journey content is authored — one key per week, the
/// recordings uploaded separately and per language — so a step carrying one and
/// resolving to nothing is a silent conversation, which nothing else catches.
void main() {
  BotStep step({String? audioUrl, String? audioKey}) =>
      BotStep(ref: 's1', type: 'text', question: 'hi', audioUrl: audioUrl, audioKey: audioKey);

  OfflineChatbotEngine engine({
    String? langCode,
    List<BotAudio> audios = const [],
  }) =>
      OfflineChatbotEngine(
        bundle: BotBundle(langCode: langCode, audios: audios),
        langCode: langCode,
      );

  test('a step with neither a URL nor a key stays silent', () {
    expect(engine(langCode: 'en').stepAudio(step()), isNull);
  });

  test('a key resolves to the library URL for the conversation language', () {
    expect(
      engine(langCode: 'en').stepAudio(step(audioKey: 'pregnant_week10_english')),
      'https://audio.savemom.app/allomom/en/pregnant_week10_english.mp3',
    );
    expect(
      engine(langCode: 'ta').stepAudio(step(audioKey: 'pregnant_week10_tamil')),
      'https://audio.savemom.app/allomom/ta/pregnant_week10_tamil.mp3',
    );
  });

  test('a catalogue downloaded for every language resolves keys in English', () {
    expect(
      engine(langCode: 'all').stepAudio(step(audioKey: 'week10')),
      'https://audio.savemom.app/allomom/en/week10.mp3',
    );
    expect(
      engine().stepAudio(step(audioKey: 'week10')),
      'https://audio.savemom.app/allomom/en/week10.mp3',
    );
  });

  test('an explicit URL wins over the key', () {
    expect(
      engine(langCode: 'ta').stepAudio(
        step(audioUrl: 'https://cdn.example.com/one-off.mp3', audioKey: 'week10'),
      ),
      'https://cdn.example.com/one-off.mp3',
    );
  });

  test('a clip the catalogue carries wins over the conventional URL', () {
    final bot = engine(
      langCode: 'ta',
      audios: const [
        BotAudio(
          key: 'week10',
          langCode: 'ta',
          filename: 'week10.mp3',
          url: 'https://firebasestorage.example.com/week10-ta.mp3',
        ),
      ],
    );
    expect(
      bot.stepAudio(step(audioKey: 'week10')),
      'https://firebasestorage.example.com/week10-ta.mp3',
    );
  });

  test('a key with no recording in this language falls back to English', () {
    final bot = engine(
      langCode: 'ta',
      audios: const [
        BotAudio(
          key: 'week10',
          langCode: 'en',
          filename: 'week10.mp3',
          url: 'https://firebasestorage.example.com/week10-en.mp3',
        ),
      ],
    );
    expect(
      bot.stepAudio(step(audioKey: 'week10')),
      'https://firebasestorage.example.com/week10-en.mp3',
    );
  });

  test('a step carries its key through a round trip of the cached bundle', () {
    final parsed = BotStep.fromJson(
      BotStep(ref: 's1', audioKey: 'week10').toJson(),
    );
    expect(parsed.audioKey, 'week10');
  });
}
