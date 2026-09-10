import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/pregnancy_journey_page.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// Renders the pregnancy journey page for a mother who has delivered, to
/// check the postpartum view actually lays out — an overflow or a null
/// dereference here would only ever show up on a device otherwise.
void main() {
  late AppDriftDatabase db;

  setUpAll(() {
    // Tests have no network; without this google_fonts tries to fetch and
    // logs failures instead of quietly falling back to the bundled font.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });

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
    await BabyRepository.instance.addBaby(
      dob: DateTime.now().subtract(const Duration(days: 40)),
      babyName: 'Aarav',
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
    await BabyRepository.instance.addBaby(
      dob: DateTime.now().subtract(const Duration(days: 40)),
      babyName: 'Meera',
    );

    await pumpPage(tester);

    // Nothing has been given yet, so the first birth dose leads.
    expect(find.text('BCG'), findsOneWidget);
    expect(find.text('Lifts head briefly'), findsOneWidget);
  });

  testWidgets('two babies get a switcher', (tester) async {
    await BabyRepository.instance.addBaby(
      dob: DateTime.now().subtract(const Duration(days: 400)),
      babyName: 'Elder',
      seedSchedule: false,
    );
    await BabyRepository.instance.addBaby(
      dob: DateTime.now().subtract(const Duration(days: 20)),
      babyName: 'Newborn',
      seedSchedule: false,
    );

    await pumpPage(tester);

    // Both names appear as switcher chips; the newest is selected.
    expect(find.text('Elder'), findsWidgets);
    expect(find.text('Newborn'), findsWidgets);
  });
}
