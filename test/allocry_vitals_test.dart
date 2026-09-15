import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/allocry/data/cry_data.dart';
import 'package:allomom/features/allocry/data/cry_record.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// AlloCry keeps no store of its own: a reading is a row in the `cry` vitals
/// stream, and the recording is named from inside it. These cover that round
/// trip — what gets written, and that it reads back as the same cry.
void main() {
  late AppDriftDatabase db;

  setUp(() {
    db = AppDriftDatabase.forTesting(NativeDatabase.memory());
    SqLiteService.overrideDatabaseForTesting(db);
  });

  tearDown(() async {
    SqLiteService.overrideDatabaseForTesting(null);
    await db.close();
  });

  Map<String, dynamic> cryData({
    String cryType = 'Hunger Cry',
    double confidence = 0.91,
    String? audioFile = 'cry_0198.wav',
  }) {
    return CryRecord.toVitalData(
      cryType: cryType,
      confidence: confidence,
      cryDetected: true,
      audioFile: audioFile,
      soundLabels: const ['Baby cry, infant cry', 'Speech'],
      durationSeconds: 7,
    );
  }

  group('the cry vital', () {
    test('writes key "cry" with the type as its value and the clip in data',
        () async {
      final id = await VitalsSqLiteService().saveVital(
        key: CryRecord.vitalKey,
        value: CryRecord.codeFor('Hunger Cry').toDouble(),
        unit: CryRecord.vitalUnit,
        createdAt: DateTime.now(),
        userId: 'usr-1',
        additionalData: cryData(),
        synced: 0,
      );

      final row =
          await (db.select(db.vitals)..where((t) => t.id.equals(id))).getSingle();

      expect(row.vitalKey, 'cry');
      expect(row.unit, 'cry');
      expect(row.value, CryRecord.typeCodes['Hunger Cry']);
      expect(row.synced, 0, reason: 'queued for the server like every vital');

      final data = jsonDecode(row.data!) as Map<String, dynamic>;
      expect(data['cryType'], 'Hunger Cry');
      expect(data['heading'], 'Hunger Crying');
      expect(data['audioFile'], 'cry_0198.wav',
          reason: 'the recording is stored with the reading');
      expect(data['confidence'], 0.91);
      expect(data['source'], 'allocry_on_device');
    });

    test('every cry type the model can predict has a distinct code', () {
      final predictable = [
        'Pain Cry',
        'Burping Cry',
        'Discomfort Cry',
        'Hunger Cry',
        'Sleepy Cry',
      ];

      final codes = predictable.map(CryRecord.codeFor).toSet();
      expect(codes, hasLength(predictable.length));
      expect(codes.contains(0), isFalse, reason: '0 means "unrecognised"');

      for (final type in predictable) {
        expect(CryRecord.typeForCode(CryRecord.codeFor(type).toDouble()), type);
        expect(CryTypes.all.containsKey(type), isTrue,
            reason: '$type must have guidance to show');
      }
    });
  });

  group('reading a cry back', () {
    test('restores the type, confidence and recording', () {
      final recordedAt = DateTime(2026, 9, 11, 2, 15);
      final record = CryRecord.fromVital(
        VitalsStreamResponse(
          id: 'vital-1',
          key: 'cry',
          value: 4,
          unit: 'cry',
          createdAt: recordedAt,
          data: cryData(),
        ),
      );

      expect(record.cryType, 'Hunger Cry');
      expect(record.type.heading, 'Hunger Crying');
      expect(record.audioFile, 'cry_0198.wav');
      expect(record.recordedAt, recordedAt);
      expect(record.confidenceLabel, '91%');
      expect(record.confidenceBand, 'High');
      expect(record.soundLabels.first, 'Baby cry, infant cry');
      expect(record.type.recommendations, isNotEmpty);
    });

    test('falls back to the numeric value when data is missing', () {
      final record = CryRecord.fromVital(
        VitalsStreamResponse(
          id: 'vital-2',
          key: 'cry',
          value: 5,
          unit: 'cry',
          createdAt: DateTime(2026, 9, 11),
          data: null,
        ),
      );

      expect(record.cryType, 'Sleepy Cry',
          reason: 'the value alone still identifies the cry');
      expect(record.audioFile, isNull);
      expect(record.type.heading, 'Sleepy Crying');
    });

    test('an unknown type still renders rather than throwing', () {
      final record = CryRecord.fromVital(
        VitalsStreamResponse(
          id: 'vital-3',
          key: 'cry',
          value: 99,
          unit: 'cry',
          createdAt: DateTime(2026, 9, 11),
          data: const {'cryType': 'Teething Cry'},
        ),
      );

      expect(record.cryType, 'Teething Cry');
      expect(record.type.heading, isNotEmpty);
      expect(record.type.recommendations, isNotEmpty);
    });
  });

  test('history reads every cry back out of the stream, newest first',
      () async {
    final base = DateTime(2026, 9, 11, 1);
    for (int i = 0; i < 3; i++) {
      await VitalsSqLiteService().saveVital(
        key: CryRecord.vitalKey,
        value: CryRecord.codeFor('Sleepy Cry').toDouble(),
        unit: CryRecord.vitalUnit,
        createdAt: base.add(Duration(hours: i)),
        userId: 'usr-1',
        additionalData: cryData(cryType: 'Sleepy Cry', audioFile: 'cry_$i.wav'),
      );
    }
    // A different vital must not show up in cry history.
    await VitalsSqLiteService().saveVital(
      key: 'weight',
      value: 58,
      unit: 'kg',
      createdAt: base,
      userId: 'usr-1',
    );

    final rows = await VitalsSqLiteService()
        .getVitalsHistory('usr-1', CryRecord.vitalKey);

    expect(rows, hasLength(3));
    expect(
      rows.map((r) => jsonDecode(r['data'] as String)['audioFile']),
      ['cry_2.wav', 'cry_1.wav', 'cry_0.wav'],
      reason: 'newest first, each with its own recording',
    );
  });
}
