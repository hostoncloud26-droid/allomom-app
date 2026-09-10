import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:allomom/services/baby_care_plan.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// What a baby scheduling run created.
class BabyCarePlanResult {
  const BabyCarePlanResult({
    required this.immunizations,
    required this.milestones,
  });

  final int immunizations;
  final int milestones;

  int get total => immunizations + milestones;
}

/// Builds the immunisation and milestone schedule for a baby and writes it to
/// local SQLite.
///
/// Every row is written with `synced = 0` — nothing is sent to allomom-api.
class BabyCareScheduler {
  static final BabyCareScheduler instance = BabyCareScheduler._internal();
  BabyCareScheduler._internal();

  final _db = BabyDbService.instance;

  /// Schedules the whole plan for [birthRecordId], anchored on [dob].
  ///
  /// Existing schedule rows for the baby are cleared first, so re-seeding
  /// after a corrected date of birth replaces the plan instead of duplicating
  /// it. Set [includeOptional] to false to skip doses outside the core NIS.
  ///
  /// Doses and milestones whose due date already passed are still written —
  /// a baby added months after birth needs the earlier rows so the parent can
  /// mark what was already done.
  Future<BabyCarePlanResult> scheduleFor({
    required String birthRecordId,
    required DateTime dob,
    bool includeOptional = true,
  }) async {
    await _db.deleteScheduleFor(birthRecordId);

    final immunizations = await _scheduleImmunizations(
      birthRecordId: birthRecordId,
      dob: dob,
      includeOptional: includeOptional,
    );
    final milestones = await _scheduleMilestones(
      birthRecordId: birthRecordId,
      dob: dob,
    );

    debugPrint(
      'BabyCareScheduler: scheduled $immunizations immunisations and '
      '$milestones milestones for birth record $birthRecordId',
    );

    return BabyCarePlanResult(
      immunizations: immunizations,
      milestones: milestones,
    );
  }

  Future<int> _scheduleImmunizations({
    required String birthRecordId,
    required DateTime dob,
    required bool includeOptional,
  }) async {
    var count = 0;
    for (final vaccine in babyVaccineSchedule) {
      if (!includeOptional && !vaccine.required) continue;
      await _db.createImmunization(
        BabyImmunizationRecordsCompanion(
          birthRecordId: Value(birthRecordId),
          vaccineName: Value(vaccine.name),
          expectedDate: Value(vaccine.dueDateFrom(dob)),
          required: Value(vaccine.required),
        ),
      );
      count++;
    }
    return count;
  }

  Future<int> _scheduleMilestones({
    required String birthRecordId,
    required DateTime dob,
  }) async {
    var count = 0;
    for (final milestone in babyMilestonePlan) {
      await _db.createMilestone(
        BabyMilestonesCompanion(
          birthRecordId: Value(birthRecordId),
          milestone: Value(milestone.milestone),
          description: Value(milestone.description),
          expectedDate: Value(milestone.dueDateFrom(dob)),
        ),
      );
      count++;
    }
    return count;
  }
}
