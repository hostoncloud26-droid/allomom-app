import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/baby_care_scheduler.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// Adding a baby is never a single write: it creates the birth record, mints
/// the baby's own `health_data_table` row so their vitals and reports have
/// somewhere to live, seeds the immunisation and milestone schedule, and
/// re-derives the mother's kid count.
///
/// This repository is the one place that sequence lives, so the registration
/// flow, the complete-pregnancy modal and the Babies screen all produce
/// identical data.
class BabyRepository {
  static final BabyRepository instance = BabyRepository._internal();
  BabyRepository._internal();

  final _db = BabyDbService.instance;

  /// Creates a baby.
  ///
  /// [pregnancyId] links the baby back to the pregnancy that produced them.
  /// It stays null for a previous child added during registration — there is
  /// no pregnancy row for a birth that predates the app.
  Future<String> addBaby({
    required DateTime dob,
    String? pregnancyId,
    String? babyName,
    String? gender,
    String? deliveryType,
    double? weight,
    String? bloodGroup,
    String? photo,
    String? video,
    List<String> complications = const [],
    bool seedSchedule = true,
  }) async {
    final birthRecordId = await _db.createBirthRecord(
      BirthRecordsCompanion(
        pregnancyId: Value(pregnancyId),
        babyName: Value(_orNull(babyName)),
        dob: Value(dob),
        gender: Value(_orNull(gender)),
        deliveryType: Value(_orNull(deliveryType)),
        weight: Value(weight),
        bloodGroup: Value(_orNull(bloodGroup)),
        photo: Value(_orNull(photo)),
        video: Value(_orNull(video)),
        complications: Value(
          complications.isEmpty ? null : jsonEncode(complications),
        ),
      ),
    );

    if (seedSchedule) {
      await BabyCareScheduler.instance.scheduleFor(
        birthRecordId: birthRecordId,
        dob: dob,
      );
    }

    await UserSessionManager.instance.refreshKidsFromBirthRecords();
    return birthRecordId;
  }

  /// Records the birth(s) from a completed pregnancy.
  ///
  /// [babyCount] is 2 for twins; each baby gets its own record because each
  /// needs its own immunisation schedule and milestone checklist.
  ///
  /// [weight] only applies to a single birth — the delivery form collects one
  /// number, and applying it to both twins would record a figure that is
  /// simply wrong for at least one of them. [photo] is copied to every baby:
  /// a picture taken at delivery is genuinely of all of them, and the parent
  /// can replace it per baby later.
  Future<List<String>> recordBirthsForPregnancy({
    required String pregnancyId,
    required DateTime deliveryDate,
    String? gender,
    String? deliveryType,
    double? weight,
    String? photo,
    int babyCount = 1,
  }) async {
    final ids = <String>[];
    for (var i = 0; i < babyCount; i++) {
      ids.add(
        await addBaby(
          pregnancyId: pregnancyId,
          dob: deliveryDate,
          gender: gender,
          deliveryType: deliveryType,
          weight: babyCount == 1 ? weight : null,
          photo: photo,
        ),
      );
    }
    debugPrint(
      'BabyRepository: created ${ids.length} birth record(s) for '
      'pregnancy $pregnancyId',
    );
    return ids;
  }

  Future<List<BirthRecord>> getBabies() => _db.getBirthRecords();

  Future<BirthRecord?> getBaby(String id) => _db.getBirthRecordById(id);

  Future<List<BirthRecord>> babiesForPregnancy(String pregnancyId) =>
      _db.getBirthRecordsForPregnancy(pregnancyId);

  /// Updates a baby's details.
  ///
  /// Changing the date of birth re-anchors the whole schedule, so the
  /// immunisation and milestone rows are rebuilt — any doses already marked
  /// given are lost, which is why this only happens when the DOB really moved.
  Future<void> updateBaby(
    BirthRecordsCompanion record, {
    DateTime? rescheduleFrom,
  }) async {
    await _db.updateBirthRecord(record);
    if (rescheduleFrom != null) {
      await BabyCareScheduler.instance.scheduleFor(
        birthRecordId: record.id.value,
        dob: rescheduleFrom,
      );
    }
  }

  Future<void> deleteBaby(String id) async {
    await _db.deleteBirthRecord(id);
    await UserSessionManager.instance.refreshKidsFromBirthRecords();
  }

  static String? _orNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
