import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/repositories/pregnancy_state.dart';

/// The bug being guarded: LMP / EDD survive a delivery, so if dates are
/// trusted ahead of the status the whole app stays in pregnancy mode after a
/// pregnancy is completed or deleted.
void main() {
  group('resolveIsPregnant', () {
    test('an explicit pregnant status wins even with no dates', () {
      expect(
        resolveIsPregnant(status: 'pregnant', hasPregnancyDates: false),
        isTrue,
      );
    });

    test(
      'a completed pregnancy is not pregnant, even with dates still stored',
      () {
        for (final status in [
          'new_mom',
          'newMom',
          'new mom',
          'postpartum',
          'delivered',
          'completed',
        ]) {
          expect(
            resolveIsPregnant(status: status, hasPregnancyDates: true),
            isFalse,
            reason: '"$status" with dates should not read as pregnant',
          );
        }
      },
    );

    test('a deleted pregnancy is not pregnant', () {
      for (final status in [
        'notpregnant',
        'not_pregnant',
        'not pregnant',
        'notPregnant',
        'NOTPREGNANT',
      ]) {
        expect(
          resolveIsPregnant(status: status, hasPregnancyDates: true),
          isFalse,
          reason: '"$status" should not read as pregnant',
        );
      }
    });

    test('an unknown or empty status falls back to whether dates exist', () {
      expect(resolveIsPregnant(status: '', hasPregnancyDates: true), isTrue);
      expect(resolveIsPregnant(status: '', hasPregnancyDates: false), isFalse);
      expect(
        resolveIsPregnant(status: 'something-else', hasPregnancyDates: true),
        isTrue,
      );
      expect(
        resolveIsPregnant(status: 'something-else', hasPregnancyDates: false),
        isFalse,
      );
    });
  });

  group('resolveIsNewMom', () {
    test('true only for the postpartum statuses', () {
      for (final status in ['new_mom', 'newMom', 'postpartum', 'delivered']) {
        expect(resolveIsNewMom(status), isTrue, reason: status);
      }
      for (final status in ['pregnant', 'notpregnant', 'completed', '']) {
        expect(resolveIsNewMom(status), isFalse, reason: status);
      }
    });
  });

  group('normalizePregnancyStatus', () {
    test('strips spaces, dashes and underscores and lowercases', () {
      expect(normalizePregnancyStatus('Not Pregnant'), 'notpregnant');
      expect(normalizePregnancyStatus('not_pregnant'), 'notpregnant');
      expect(normalizePregnancyStatus('NEW-MOM'), 'newmom');
    });
  });

  test('a completed pregnancy is never both pregnant and a new mom', () {
    for (final status in postpartumStatuses) {
      expect(
        resolveIsPregnant(status: status, hasPregnancyDates: true),
        isFalse,
      );
      expect(resolveIsNewMom(status), isTrue);
    }
  });
}
