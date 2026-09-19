import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// The write behind "what did you have for lunch?": the note goes onto the
/// meal's own row in the vitals stream, so nothing sums the meal twice and
/// the loader can read it back to know the question is answered.
void main() {
  late AppDriftDatabase db;

  /// Puts a health record in place.
  ///
  /// Readings hang off the health record now, not the user — that is the shape
  /// allomom-api-new uses — so a test that writes vitals needs one to exist.
  /// No controller is involved: the service resolves the scope from the
  /// database, which is what keeps it testable in isolation.
  Future<String> seedHealthRecord({String userId = 'usr-1'}) async {
    await db
        .into(db.users)
        .insertOnConflictUpdate(
          UsersCompanion.insert(id: userId, name: const Value('Meera')),
        );
    await db
        .into(db.healthDataTable)
        .insertOnConflictUpdate(
          HealthDataTableCompanion.insert(id: 'hd-$userId', userId: userId),
        );
    return 'hd-$userId';
  }

  setUp(() async {
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
    await seedHealthRecord();
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });


  Future<Map<String, dynamic>> dataOf(String id) async {
    final row = await (db.select(db.vitalsStreamTable)..where((t) => t.id.equals(id)))
        .getSingle();
    return jsonDecode(row.data!) as Map<String, dynamic>;
  }

  group('mergeDataIntoLatest', () {
    test('attaches the note to today\'s meal row, keeping the calories',
        () async {
      final id = await VitalsSqLiteService().saveVital(
        key: 'lunch',
        value: 600,
        unit: 'kcal',
        createdAt: DateTime.now(),
        userId: 'usr-1',
        additionalData: {'source': 'allobot_home'},
        synced: 1,
      );

      final merged = await VitalsSqLiteService().mergeDataIntoLatest(
        key: 'lunch',
        data: {'items': 'rice, dal and spinach', 'details': 'rice, dal and spinach'},
        userId: 'usr-1',
      );
      expect(merged, isTrue);

      final rows = await db.select(db.vitalsStreamTable).get();
      expect(rows, hasLength(1), reason: 'no second row to double-count');
      expect(rows.single.value, 600);
      expect(rows.single.synced, 0, reason: 'the note has to reach the server');

      final data = await dataOf(id);
      expect(data['items'], 'rice, dal and spinach');
      expect(data['source'], 'allobot_home', reason: 'existing keys survive');
    });

    test('picks the newest row of the day', () async {
      final today = DateTime.now();
      await VitalsSqLiteService().saveVital(
        key: 'lunch',
        value: 400,
        unit: 'kcal',
        createdAt: DateTime(today.year, today.month, today.day, 1),
        userId: 'usr-1',
      );
      final later = await VitalsSqLiteService().saveVital(
        key: 'lunch',
        value: 600,
        unit: 'kcal',
        createdAt: DateTime(today.year, today.month, today.day, 13),
        userId: 'usr-1',
      );

      await VitalsSqLiteService().mergeDataIntoLatest(
        key: 'lunch',
        data: {'items': 'rice and curd'},
        userId: 'usr-1',
      );

      expect((await dataOf(later))['items'], 'rice and curd');
    });

    test('reports false when the meal is not logged today', () async {
      await VitalsSqLiteService().saveVital(
        key: 'lunch',
        value: 600,
        unit: 'kcal',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        userId: 'usr-1',
      );

      final merged = await VitalsSqLiteService().mergeDataIntoLatest(
        key: 'lunch',
        data: {'items': 'rice and curd'},
        userId: 'usr-1',
      );
      expect(merged, isFalse, reason: 'yesterday is not today');
    });

    test("leaves another health record's row alone", () async {
      final mine = await VitalsSqLiteService().saveVital(
        key: 'lunch',
        value: 600,
        unit: 'kcal',
        createdAt: DateTime.now(),
      );
      // Written straight to drift under a different health record, which is
      // how the server scopes readings — the merge must not reach across.
      await db.into(db.vitalsStreamTable).insert(
            VitalsStreamTableCompanion.insert(
              id: 'other-row',
              key: 'lunch',
              healthId: const Value('hd-someone-else'),
              value: const Value(500),
              unit: const Value('kcal'),
              createdAt: Value(DateTime.now()),
            ),
          );

      await VitalsSqLiteService().mergeDataIntoLatest(
        key: 'lunch',
        data: {'items': 'rice and curd'},
      );

      expect((await dataOf(mine))['items'], 'rice and curd');
      final other = await (db.select(db.vitalsStreamTable)
            ..where((t) => t.id.equals('other-row')))
          .getSingle();
      expect(other.data, isNull);
    });
  });
}
