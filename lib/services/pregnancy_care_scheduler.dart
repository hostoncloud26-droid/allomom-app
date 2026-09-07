import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
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

/// Builds the ANC / vaccination / lab-report schedule for a pregnancy and
/// writes it to local SQLite.
///
/// Every row is written with `synced = 0` — nothing is sent to allomom-api.
class PregnancyCareScheduler {
  static final PregnancyCareScheduler instance =
      PregnancyCareScheduler._internal();
  PregnancyCareScheduler._internal();

  final _db = PregnancyCareDbService.instance;

  /// Schedules the whole plan for [pregnancyId], anchored on [lmpDate].
  ///
  /// [ancMonths] are the pregnancy months the mother said she will attend an
  /// ANC check-up in; vaccines and lab tests follow the fixed clinical
  /// schedule in `pregnancy_care_plan.dart` regardless of that choice, because
  /// they are due whether or not she books a routine visit that month.
  ///
  /// Existing schedule rows for the pregnancy are cleared first, so
  /// re-registering replaces the plan instead of duplicating it.
  Future<PregnancyCarePlanResult> scheduleFor({
    required String pregnancyId,
    required String userId,
    required DateTime lmpDate,
    required List<int> ancMonths,
    bool includeOptional = true,
  }) async {
    await _db.deleteAllForPregnancy(pregnancyId);

    final ancCount = await _scheduleAnc(
      pregnancyId: pregnancyId,
      lmpDate: lmpDate,
      months: ancMonths,
    );
    final vaccineCount = await _scheduleVaccines(
      pregnancyId: pregnancyId,
      userId: userId,
      lmpDate: lmpDate,
    );
    final reportCount = await _scheduleReports(
      pregnancyId: pregnancyId,
      userId: userId,
      lmpDate: lmpDate,
      includeOptional: includeOptional,
    );

    debugPrint(
      'PregnancyCareScheduler: scheduled $ancCount ANC visits, '
      '$vaccineCount vaccinations and $reportCount lab reports '
      'for pregnancy $pregnancyId',
    );

    return PregnancyCarePlanResult(
      ancVisits: ancCount,
      vaccinations: vaccineCount,
      reports: reportCount,
    );
  }

  Future<int> _scheduleAnc({
    required String pregnancyId,
    required DateTime lmpDate,
    required List<int> months,
  }) async {
    final ordered = months.toSet().toList()..sort();
    var visitNumber = 0;

    for (final month in ordered) {
      visitNumber++;
      await _db.createAncVisit(
        PregnancyAncScheduleCompanion(
          pregnancyId: Value(pregnancyId),
          visitNumber: Value(visitNumber),
          pregnancyMonth: Value(month),
          trimester: Value(trimesterForMonth(month)),
          scheduledDate: Value(addMonthsClamped(lmpDate, month)),
          status: const Value('pending'),
          notes: Value('ANC visit $visitNumber · ${monthLabel(month)}'),
        ),
      );
    }

    return visitNumber;
  }

  Future<int> _scheduleVaccines({
    required String pregnancyId,
    required String userId,
    required DateTime lmpDate,
  }) async {
    for (final vaccine in vaccineSchedule) {
      await _db.createVaccination(
        VaccinationsCompanion(
          userId: Value(userId),
          pregnancyId: Value(pregnancyId),
          vaccineName: Value(vaccine.name),
          doseNumber: Value(vaccine.doseNumber),
          pregnancyMonth: Value(vaccine.month),
          scheduledDate: Value(addMonthsClamped(lmpDate, vaccine.month)),
          status: const Value('pending'),
          notes: Value(vaccine.purpose),
        ),
      );
    }
    return vaccineSchedule.length;
  }

  Future<int> _scheduleReports({
    required String pregnancyId,
    required String userId,
    required DateTime lmpDate,
    required bool includeOptional,
  }) async {
    final due = includeOptional
        ? reportSchedule
        : reportSchedule.where((r) => r.isRequired).toList();

    for (final report in due) {
      await _db.createReportChecklist(
        ReportChecklistsCompanion(
          userId: Value(userId),
          pregnancyId: Value(pregnancyId),
          reportName: Value(report.name),
          category: Value(report.category),
          pregnancyMonth: Value(report.month),
          isRequired: Value(report.isRequired),
          dueDate: Value(addMonthsClamped(lmpDate, report.month)),
          status: const Value('pending'),
          notes: Value(report.purpose),
        ),
      );
    }

    return due.length;
  }

  /// Dates the plan would land on, without writing anything. Used by the
  /// review step so the mother sees the actual dates before confirming.
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
