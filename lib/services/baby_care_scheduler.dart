import 'package:flutter/foundation.dart';

import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// What a baby's care plan contains.
class BabyCarePlanResult {
  const BabyCarePlanResult({
    required this.immunizations,
    required this.milestones,
  });

  final int immunizations;
  final int milestones;

  int get total => immunizations + milestones;
}

/// Reports on the immunisation and milestone schedule for a baby.
///
/// It used to generate both into local SQLite. It no longer does:
/// allomom-api-new seeds the National Immunization Schedule and the milestone
/// checklist when a baby is created, anchored on the same date of birth, and
/// [SyncService] pulls them down. Generating a second set locally would have
/// duplicated every dose, so this now counts what the server created.
class BabyCareScheduler {
  static final BabyCareScheduler instance = BabyCareScheduler._internal();
  BabyCareScheduler._internal();

  final _db = BabyDbService.instance;

  /// Counts the schedule the server seeded for [babyId].
  Future<BabyCarePlanResult> scheduleFor({
    required String babyId,
    DateTime? dob,
    bool includeOptional = true,
  }) async {
    final immunizations = await _db.getImmunizations(babyId);
    final milestones = await _db.getMilestones(babyId);

    debugPrint(
      'BabyCareScheduler: server seeded ${immunizations.length} immunisations '
      'and ${milestones.length} milestones for baby $babyId',
    );

    return BabyCarePlanResult(
      immunizations: immunizations.length,
      milestones: milestones.length,
    );
  }
}
