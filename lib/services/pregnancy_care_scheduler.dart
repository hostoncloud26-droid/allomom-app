import 'package:flutter/foundation.dart';

import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';

/// What a scheduling run created.
class PregnancyCarePlanResult {
  const PregnancyCarePlanResult({
    required this.ancVisits,
    required this.vaccinations,
    required this.reports,
  });

  final int ancVisits;
  final int vaccinations;
  final int reports;

  int get total => ancVisits + vaccinations + reports;
}

/// Reports on the ANC / vaccination / lab-report schedule for a pregnancy.
///
/// It used to generate that schedule into local SQLite. It no longer does:
/// allomom-api-new seeds all three the moment a pregnancy is created, derived
/// from the same LMP, and [SyncService] pulls them down. Two generators
/// producing their own rows against one pregnancy would have duplicated the
/// entire calendar, so this now counts what the server created and leaves
/// [preview] — a pure function over the clinical plan — as the only part that
/// still computes anything.
class PregnancyCareScheduler {
  static final PregnancyCareScheduler instance =
      PregnancyCareScheduler._internal();
  PregnancyCareScheduler._internal();

  final _db = PregnancyCareDbService.instance;

  /// Counts the schedule the server seeded for [pregnancyId].
  ///
  /// The parameters beyond [pregnancyId] are accepted and ignored: the server
  /// already anchored the plan on the LMP it was given, and re-deriving it here
  /// could only disagree with what it produced.
  Future<PregnancyCarePlanResult> scheduleFor({
    required String pregnancyId,
    String? userId,
    DateTime? lmpDate,
    List<int> ancMonths = const [],
    bool includeOptional = true,
  }) async {
    final anc = await _db.getAncVisits(pregnancyId);
    final vaccinations = await _db.getVaccinations(pregnancyId);
    final reports = await _db.getReportChecklists(pregnancyId);

    debugPrint(
      'PregnancyCareScheduler: server seeded ${anc.length} ANC visits, '
      '${vaccinations.length} vaccinations and ${reports.length} lab reports '
      'for pregnancy $pregnancyId',
    );

    return PregnancyCarePlanResult(
      ancVisits: anc.length,
      vaccinations: vaccinations.length,
      reports: reports.length,
    );
  }

  static PregnancyCarePlanPreview preview({
    required DateTime lmpDate,
    required List<int> ancMonths,
    bool includeOptional = true,
  }) {
    final ordered = ancMonths.toSet().toList()..sort();
    return PregnancyCarePlanPreview(
      ancDates: {
        for (final month in ordered) month: addMonthsClamped(lmpDate, month),
      },
      vaccineDates: {
        for (final v in vaccineSchedule)
          v.name: addMonthsClamped(lmpDate, v.month),
      },
      reportCount: includeOptional
          ? reportSchedule.length
          : reportSchedule.where((r) => r.isRequired).length,
      optionalReportCount: reportSchedule.where((r) => !r.isRequired).length,
    );
  }
}

/// Read-only view of what [PregnancyCareScheduler.scheduleFor] would create.
class PregnancyCarePlanPreview {
  const PregnancyCarePlanPreview({
    required this.ancDates,
    required this.vaccineDates,
    required this.reportCount,
    required this.optionalReportCount,
  });

  /// Pregnancy month -> ANC visit date.
  final Map<int, DateTime> ancDates;

  /// Vaccine name -> due date.
  final Map<String, DateTime> vaccineDates;

  final int reportCount;
  final int optionalReportCount;

  int get ancCount => ancDates.length;
  int get vaccineCount => vaccineDates.length;
  int get total => ancCount + vaccineCount + reportCount;
}
