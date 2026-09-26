import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';

void main() {
  test('each action runs after the line it follows, not after the segment', () {
    final reply = BotReply()
      ..say('Let me look at your breakfast, Mommy.')
      ..endStep()
      ..addAction({'name': 'open_breakfast_sheet'})
      ..say('You have not had water for a while, Mommy.')
      ..endStep()
      ..addAction({'name': 'open_water_sheet'});

    // No delay between the steps, so they share one segment.
    expect(reply.segments, hasLength(1));
    final segment = reply.segments.single;
    expect(segment.utterances, hasLength(2));

    expect(segment.actionsAt(0), isEmpty);
    expect(
      segment.actionsAt(1).map((a) => a['name']),
      ['open_breakfast_sheet'],
    );
    expect(
      segment.actionsAt(2).map((a) => a['name']),
      ['open_water_sheet'],
    );
  });

  test('a line said right after an action is not merged into the one before', () {
    final reply = BotReply()
      ..say('Let me look at your breakfast, Mommy.')
      ..addAction({'name': 'open_breakfast_sheet'})
      ..say('Now some water.');

    final segment = reply.segments.single;
    expect(segment.utterances.map((u) => u.text), [
      'Let me look at your breakfast, Mommy.',
      'Now some water.',
    ]);
    expect(segment.actionsAt(1).map((a) => a['name']), ['open_breakfast_sheet']);
  });
}
