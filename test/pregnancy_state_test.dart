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

  group('pregnancyStatusForRegistration', () {
    test('only "Pregnant" stores a pregnant status', () {
      expect(pregnancyStatusForRegistration('Pregnant'), 'pregnant');
    });

    test('"Pre Pregnancy" is not pregnant, despite containing "pregnan"', () {
      for (final label in [
        'Pre Pregnancy',
        'pre pregnancy',
        'Pre-Pregnancy',
        'PrePregnancy',
      ]) {
        expect(
          pregnancyStatusForRegistration(label),
          'notpregnant',
          reason: label,
        );
        expect(isPregnantRegistrationLabel(label), isFalse, reason: label);
      }
    });

    test('"New Mom" stores new_mom, which still reads as not pregnant', () {
      expect(pregnancyStatusForRegistration('New Mom'), 'new_mom');
      expect(isPregnantRegistrationLabel('New Mom'), isFalse);

      // The whole point: postpartum is distinguishable, but not pregnant.
      expect(
        resolveIsPregnant(status: 'new_mom', hasPregnancyDates: true),
        isFalse,
      );
      expect(resolveIsNewMom('new_mom'), isTrue);
    });

    test('a dad is pregnant only when registering for his partner', () {
      expect(
        pregnancyStatusForRegistration(
          'Pregnant',
          isDad: true,
          registeringForPartner: true,
        ),
        'pregnant',
      );
      expect(
        pregnancyStatusForRegistration(
          'Pregnant',
          isDad: true,
          registeringForPartner: false,
        ),
        'notpregnant',
      );
    });

    test('every label maps to a status the resolvers understand', () {
      for (final label in ['Pregnant', 'Pre Pregnancy', 'New Mom']) {
        final stored = pregnancyStatusForRegistration(label);
        expect(
          resolveIsPregnant(status: stored, hasPregnancyDates: false),
          isPregnantRegistrationLabel(label),
          reason: label,
        );
      }
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
