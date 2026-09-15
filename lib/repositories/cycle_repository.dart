import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/cycle_predictor.dart' as predictor;
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';

/// Her menstrual cycle: the periods she has logged and the averages the
/// predictions run off.
///
/// Two things have to move together every time a period is logged — a row in
/// `cycle_histories` (the log she can scroll back through) and the LMP on her
/// health profile (what every prediction reads, including the pregnancy flow's
/// due-date maths). Keeping that pair in one place is the point of this
/// repository.
class CycleRepository {
  static final CycleRepository instance = CycleRepository._internal();
  CycleRepository._internal();

  final _db = HealthDbService.instance;

  /// Logged periods, most recent first.
  Future<List<CycleHistory>> history() async {
    final healthId = UserSessionManager.instance.healthDataId;
    if (healthId.isEmpty) return const [];
    return _db.getCycleHistories(healthId);
  }

  /// Records a period and, when it is the most recent one, makes it the LMP.
  ///
  /// [end] stays null while she is still bleeding. Re-logging a period that
  /// starts on a day already recorded updates that row rather than adding a
  /// duplicate, so correcting the date twice does not litter her history.
  Future<void> logPeriod({
    required DateTime start,
    DateTime? end,
    int? cycleLength,
    int? periodDuration,
    String? cycleType,
  }) async {
    final session = UserSessionManager.instance;
    final healthId = session.healthDataId;
    final startDay = _dateOnly(start);

    if (healthId.isNotEmpty) {
      final existing = await _db.getCycleHistories(healthId);
      CycleHistory? sameDay;
      for (final c in existing) {
        if (_isSameDay(c.cycleStartDate, startDay)) {
          sameDay = c;
          break;
        }
      }

      await _db.saveCycleHistory(
        CycleHistoriesCompanion(
          id: Value(sameDay?.id ?? const Uuid().v4()),
          healthId: Value(healthId),
          cycleStartDate: Value(startDay),
          cycleEndDate: Value(end == null ? null : _dateOnly(end)),
          cycleType: Value(cycleType),
          createdAt: Value(sameDay?.createdAt ?? DateTime.now()),
        ),
      );
    }

    // Only the most recent period is the LMP: back-filling an older cycle
    // must not drag the prediction backwards.
    final currentLmp = session.lmpDate;
    final isMostRecent = currentLmp == null || !startDay.isBefore(currentLmp);

    await session.updateCycleSetup(
      lastPeriodStart: isMostRecent ? startDay : null,
      cycleLength: cycleLength,
      periodDuration: periodDuration,
    );
  }

  /// Her cycle length measured from what she has actually logged, or null
  /// until two periods are on record.
  ///
  /// Offered as a correction rather than written over her own answer — she
  /// stays the authority on her own cycle.
  Future<int?> measuredCycleLength() async =>
      cycleLengthFromHistory(await history());

  /// [measuredCycleLength] without the database, so it can be tested directly.
  static int? cycleLengthFromHistory(List<CycleHistory> logged) =>
      predictor.observedCycleLength([
        for (final c in logged) c.cycleStartDate,
      ]);

  static DateTime _dateOnly(DateTime v) => DateTime(v.year, v.month, v.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
