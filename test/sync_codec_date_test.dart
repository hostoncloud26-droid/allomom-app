import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/sync/sync_codec.dart';

void main() {
  group('SyncCodec.date', () {
    test('an offset-less server timestamp is UTC', () {
      // What the server returns for vitals_stream.createdAt: the UTC value
      // the app sent, with the offset dropped.
      final parsed = SyncCodec.date('2026-09-29T18:30:00')!;
      expect(parsed.toUtc(), DateTime.utc(2026, 9, 29, 18, 30));
      expect(parsed.isUtc, isFalse);
    });

    test('round-trips what isoUtc sends, once the server drops the Z', () {
      final local = DateTime(2026, 9, 30, 12, 29);
      final sent = SyncCodec.isoUtc(local)!;
      final stored = sent.replaceAll('Z', ''); // server's naive column
      expect(SyncCodec.date(stored), local);
    });

    test('an explicit offset is honoured', () {
      expect(
        SyncCodec.date('2026-09-29T18:30:00+00:00')!.toUtc(),
        DateTime.utc(2026, 9, 29, 18, 30),
      );
      expect(
        SyncCodec.date('2026-09-30T00:00:00+05:30')!.toUtc(),
        DateTime.utc(2026, 9, 29, 18, 30),
      );
      expect(
        SyncCodec.date('2026-09-29T18:30:00.123Z')!.toUtc(),
        DateTime.utc(2026, 9, 29, 18, 30, 0, 123),
      );
    });

    test('a bare day stays a local calendar day', () {
      expect(SyncCodec.date('2026-09-30'), DateTime(2026, 9, 30));
    });

    test('garbage is null', () {
      expect(SyncCodec.date('not a date'), isNull);
      expect(SyncCodec.date(null), isNull);
    });
  });
}
