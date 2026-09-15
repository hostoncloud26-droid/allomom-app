import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/repositories/pregnancy_state.dart';

/// The bugs being guarded:
///
/// * An LMP is collected from every mother so her next period can be
///   predicted, so treating it as evidence of pregnancy registered every
///   "Pre Pregnancy" and "New Mom" sign-up as pregnant.
/// * LMP / EDD survive a delivery, so trusting dates ahead of the status left
///   the app in pregnancy mode after a pregnancy was completed or deleted.
void main() {
  group('resolveIsPregnant', () {
    test('an explicit pregnant status wins even with no dates', () {
      expect(
        resolveIsPregnant(status: 'pregnant', hasPregnancyDates: false),
        isTrue,
      );
    });

    test('only "pregnant" is pregnant, whatever dates are stored', () {
      for (final status in [
        'notpregnant',
        'not_pregnant',
        'not pregnant',
        'notPregnant',
        'NOTPREGNANT',
        // Values a previous build may have left in the column.
        'new_mom',
        'newMom',
        'postpartum',
        'delivered',
        'completed',
        'withbaby',
      ]) {
        expect(
          resolveIsPregnant(status: status, hasPregnancyDates: true),
          isFalse,
          reason: '"$status" with dates should not read as pregnant',
        );
      }
    });

    test('an empty status is the only case that falls back to the dates', () {
      expect(resolveIsPregnant(status: '', hasPregnancyDates: true), isTrue);
      expect(resolveIsPregnant(status: '', hasPregnancyDates: false), isFalse);
      expect(resolveIsPregnant(status: '  ', hasPregnancyDates: true), isTrue);
    });
  });

  group('resolveIsNewMom', () {
    final now = DateTime(2026, 9, 15);

    test('a recent birth makes her a new mom', () {
      expect(
        resolveIsNewMom(
          isPregnant: false,
          lastBirthDate: now.subtract(const Duration(days: 30)),
          now: now,
        ),
        isTrue,
      );
    });

    test('an older child does not', () {
      // The reason postpartum is derived rather than stored: a "Pre
      // Pregnancy" mother who registered a five-year-old is not a new mom.
      expect(
        resolveIsNewMom(
          isPregnant: false,
          lastBirthDate: now.subtract(const Duration(days: 5 * 365)),
          now: now,
        ),
        isFalse,
      );
    });

    test('the window ends exactly a year after the birth', () {
      expect(
        resolveIsNewMom(
          isPregnant: false,
          lastBirthDate: now.subtract(const Duration(days: newMomWindowDays)),
          now: now,
        ),
        isTrue,
      );
      expect(
        resolveIsNewMom(
          isPregnant: false,
          lastBirthDate: now.subtract(
            const Duration(days: newMomWindowDays + 1),
          ),
          now: now,
        ),
        isFalse,
      );
    });

    test('never a new mom while pregnant, or with no birth on record', () {
      expect(
        resolveIsNewMom(
          isPregnant: true,
          lastBirthDate: now.subtract(const Duration(days: 30)),
          now: now,
        ),
        isFalse,
      );
      expect(
        resolveIsNewMom(isPregnant: false, lastBirthDate: null, now: now),
        isFalse,
      );
    });
  });

  group('normalizePregnancyStatus', () {
    test('strips spaces, dashes and underscores and lowercases', () {
      expect(normalizePregnancyStatus('Not Pregnant'), 'notpregnant');
      expect(normalizePregnancyStatus('not_pregnant'), 'notpregnant');
      expect(normalizePregnancyStatus('PREGNANT'), 'pregnant');
    });
  });

  group('pregnancyStatusForRegistration', () {
    test('only "Pregnant" stores a pregnant status', () {
      expect(pregnancyStatusForRegistration('Pregnant'), pregnantStatus);
      expect(isPregnantRegistrationLabel('Pregnant'), isTrue);
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
          notPregnantStatus,
          reason: label,
        );
        expect(isPregnantRegistrationLabel(label), isFalse, reason: label);
      }
    });

    test('"New Mom" stores notpregnant and routes her to her baby', () {
      expect(pregnancyStatusForRegistration('New Mom'), notPregnantStatus);
      expect(isPregnantRegistrationLabel('New Mom'), isFalse);
      // She is not pregnant; the baby she registers is what makes her a new
      // mom, so the label only decides where registration sends her.
      expect(isNewMomRegistrationLabel('New Mom'), isTrue);
      expect(isNewMomRegistrationLabel('Pre Pregnancy'), isFalse);
      expect(isNewMomRegistrationLabel('Pregnant'), isFalse);
    });

    test('a dad is pregnant only when registering for his partner', () {
      expect(
        pregnancyStatusForRegistration(
          'Pregnant',
          isDad: true,
          registeringForPartner: true,
        ),
        pregnantStatus,
      );
      expect(
        pregnancyStatusForRegistration(
          'Pregnant',
          isDad: true,
          registeringForPartner: false,
        ),
        notPregnantStatus,
      );
    });

    test('every label stores one of the two allowed statuses', () {
      for (final label in ['Pregnant', 'Pre Pregnancy', 'New Mom']) {
        final stored = pregnancyStatusForRegistration(label);
        expect(pregnancyStatuses, contains(stored), reason: label);
        expect(
          resolveIsPregnant(status: stored, hasPregnancyDates: true),
          isPregnantRegistrationLabel(label),
          reason: '$label stored as $stored',
        );
      }
    });
  });
}
