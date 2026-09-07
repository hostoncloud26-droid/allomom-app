import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';

/// The three schedule screens all colour their cards from this, so the
/// pending/overdue/due-soon boundaries are pinned down.
void main() {
  final now = DateTime(2026, 5, 12, 14, 30);

  CareStatus resolve(String status, DateTime? date) =>
      CareStatus.resolve(status: status, date: date, now: now);

  group('CareStatus.resolve', () {
    test('a stored done status wins over the date', () {
      expect(resolve('done', DateTime(2026, 1, 1)), CareStatus.completed);
      expect(resolve('done', DateTime(2027, 1, 1)), CareStatus.completed);
      expect(resolve('completed', DateTime(2026, 1, 1)), CareStatus.completed);
      expect(resolve('DONE', DateTime(2026, 1, 1)), CareStatus.completed);
    });

    test('a stored missed status wins too', () {
      expect(resolve('missed', DateTime(2026, 1, 1)), CareStatus.missed);
    });

    test('a pending row whose date has passed is overdue', () {
      expect(resolve('pending', DateTime(2026, 5, 11)), CareStatus.overdue);
      expect(resolve('pending', DateTime(2026, 4, 1)), CareStatus.overdue);
    });

    test('today counts as due soon, not overdue', () {
      // Same day, earlier clock time — must not read as overdue.
      expect(resolve('pending', DateTime(2026, 5, 12, 8)), CareStatus.dueSoon);
      expect(resolve('pending', DateTime(2026, 5, 12, 23)), CareStatus.dueSoon);
    });

    test('within the next 7 days is due soon', () {
      expect(resolve('pending', DateTime(2026, 5, 13)), CareStatus.dueSoon);
      expect(resolve('pending', DateTime(2026, 5, 19)), CareStatus.dueSoon);
    });

    test('more than 7 days out is just scheduled', () {
      expect(resolve('pending', DateTime(2026, 5, 20)), CareStatus.scheduled);
      expect(resolve('pending', DateTime(2026, 8, 1)), CareStatus.scheduled);
    });

    test('a missing date is scheduled, never overdue', () {
      expect(resolve('pending', null), CareStatus.scheduled);
    });

    test('isDone and needsAttention flag the right states', () {
      expect(CareStatus.completed.isDone, isTrue);
      expect(CareStatus.overdue.isDone, isFalse);

      expect(CareStatus.overdue.needsAttention, isTrue);
      expect(CareStatus.dueSoon.needsAttention, isTrue);
      expect(CareStatus.scheduled.needsAttention, isFalse);
      expect(CareStatus.completed.needsAttention, isFalse);
      expect(CareStatus.missed.needsAttention, isFalse);
    });

    test('every state has a label and distinct colours', () {
      for (final status in CareStatus.values) {
        expect(status.label, isNotEmpty);
      }
      final colors = CareStatus.values.map((s) => s.color).toSet();
      expect(colors, hasLength(CareStatus.values.length));
    });
  });
}
