import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/pregnancy_journey_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:allomom/services/baby_care_plan.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Renders the pregnancy journey page for a mother who has delivered, to
/// check the postpartum view actually lays out — an overflow or a null
/// dereference here would only ever show up on a device otherwise.
void main() {
  late AppDriftDatabase db;

  /// Milestone ids are assigned by the server; the tests just need them unique.
  var _nextMilestoneId = 1;

  setUpAll(() {
    // Tests have no network; without this google_fonts tries to fetch and
    // logs failures instead of quietly falling back to the bundled font.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _nextMilestoneId = 1;
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });


  /// Puts a baby and its care plan straight into the local database.
  ///
  /// Not through `BabyRepository`: adding a baby goes via the server now, which
  /// is what generates the immunisation and milestone schedules. A widget test
  /// has no network, so it seeds the rows sync would have pulled down —
  /// which is also what the page actually reads.
  Future<String> seedBaby({
    required DateTime dob,
    required String name,
    String? gender,
    bool withSchedule = true,
  }) async {
    const uuid = Uuid();
    final pregnancyId = uuid.v4();
    final babyId = uuid.v4();

    await db.into(db.pregnancies).insertOnConflictUpdate(
          PregnanciesCompanion.insert(
            id: pregnancyId,
            healthId: const Value('hd-usr-1'),
            status: const Value('delivered'),
          ),
        );
    await db.into(db.babies).insertOnConflictUpdate(
          BabiesCompanion.insert(
            id: babyId,
            pregnancyId: Value(pregnancyId),
            name: name,
            deliveryDate: dob,
            typeOfDelivery: 'normal',
            gender: Value(gender),
            condition: const Value('live'),
          ),
        );

    if (withSchedule) {
      for (final dose in babyVaccineSchedule) {
        await db.into(db.babyImmunizationRecords).insertOnConflictUpdate(
              BabyImmunizationRecordsCompanion.insert(
                id: uuid.v4(),
                babyId: Value(babyId),
                vaccineName: dose.name,
                scheduledDate: Value(dose.dueDateFrom(dob)),
                required: Value(dose.required),
              ),
            );
      }
      for (final milestone in babyMilestonePlan) {
        await db.into(db.babyMilestones).insertOnConflictUpdate(
              BabyMilestonesCompanion.insert(
                id: Value(_nextMilestoneId++),
                babyId: Value(babyId),
                milestone: milestone.milestone,
                description: milestone.description,
                expectedDate: Value(milestone.dueDateFrom(dob)),
              ),
            );
      }
    }

    return babyId;
  }

  /// A phone-shaped surface — the default 800x600 is not a layout this page
  /// ever renders on, so overflows there would be false alarms.
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: PregnancyJourneyPage()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with no pregnancy and no baby, it still offers registration',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('My Pregnancy Journey'), findsOneWidget);
    expect(find.text('Register Pregnancy'), findsOneWidget);
  });

  testWidgets('after delivery it shows the baby, not a registration prompt',
      (tester) async {
    await seedBaby(
      dob: DateTime.now().subtract(const Duration(days: 40)),
      name: 'Aarav',
      gender: 'male',
    );

    await pumpPage(tester);

    // The page reframes itself around the baby.
    expect(find.text('My Baby Journey'), findsOneWidget);
    expect(find.text('Aarav'), findsWidgets);
    expect(find.text("BABY'S CARE PLAN"), findsOneWidget);

    // It leads with the same banner as the home screen and the pregnant view,
    // with the baby speaking its own age, and keeps the record in the card
    // below it.
    expect(find.byType(BabyHeroBanner), findsOneWidget);
    expect(find.textContaining('Am 1 month old'), findsOneWidget);
    expect(find.text('BABY INFO'), findsOneWidget);

    // Progress tiles are populated from the seeded schedule.
    expect(find.text('Vaccines given'), findsOneWidget);
    expect(find.text('Milestones hit'), findsOneWidget);

    // Registering the next pregnancy stays reachable, but demoted.
    expect(find.text('Expecting again?'), findsOneWidget);
    expect(find.text('Register Pregnancy'), findsNothing);
  });

  testWidgets('the care plan names the next due dose and milestone',
      (tester) async {
    await seedBaby(
      dob: DateTime.now().subtract(const Duration(days: 40)),
      name: 'Meera',
    );

    await pumpPage(tester);

    // Nothing has been given yet, so the first birth dose leads.
    expect(find.text('BCG'), findsOneWidget);
    expect(find.text('Lifts head briefly'), findsOneWidget);
  });

  testWidgets('two babies get a switcher', (tester) async {
    await seedBaby(
      dob: DateTime.now().subtract(const Duration(days: 400)),
      name: 'Elder',
      withSchedule: false,
    );
    await seedBaby(
      dob: DateTime.now().subtract(const Duration(days: 20)),
      name: 'Newborn',
      withSchedule: false,
    );

    await pumpPage(tester);

    // Both names appear as switcher chips; the newest is selected.
    expect(find.text('Elder'), findsWidgets);
    expect(find.text('Newborn'), findsWidgets);
  });
}
