import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/features/cycle_tracker/cycle_tracker_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late AppDriftDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
    print('SETUP: signing in');
    await UserSessionManager.instance.setAuthenticatedSession(
      userId: 'usr-1', jwt: 'test', healthDataId: 'hd-1',
      pregnancyStatus: 'notpregnant',
    );
    print('SETUP: done');
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });

  testWidgets('probe', (tester) async {
    print('PUMP');
    await tester.pumpWidget(const MaterialApp(home: CycleTrackerPage()));
    print('PUMPED once');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    print('after pumps; empty state? ${find.text('Nothing tracked yet').evaluate().length}');
  });
}
