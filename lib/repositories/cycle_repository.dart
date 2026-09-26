import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/vitals_controller.dart';
import 'package:allomom/services/cycle_predictor.dart' as predictor;
import 'package:allomom/services/menstrual_tracker.dart';

/// Her menstrual cycle, tracked the way AlloConnect tracks it.
///
/// Every period is one `lmp_date` reading in the vitals stream. It is written
/// locally first and marked unsynced, then pushed by the vitals sync, so
/// logging works offline and lands on the server — and in AlloConnect — once
/// there is a connection. Ending or editing a period rewrites that same row.
class CycleRepository {
  static final CycleRepository instance = CycleRepository._internal();
  CycleRepository._internal();

  VitalsController get _vitals => VitalsController.instance;

  /// Logged periods, most recent first.
  ///
  /// Before she has logged one, the LMP on her profile (or an older
  /// period-start reading) stands in as a single entry, so the tracker is not
  /// empty for someone who gave her LMP at sign-up. That entry has no id;
  /// ending or editing it saves it as a real period.
  List<PeriodLog> history() {
    final logged = _vitals.periodLogs;
    if (logged.isNotEmpty) return logged;

    final session = MainController.instance;
    final anchor = session.cycleAnchorDate;
    if (anchor == null) return const [];
    return [
      PeriodLog(
        id: null,
        start: dateOnly(anchor),
        end: null,
        periodDuration: session.averagePeriodDuration,
        averageCycle: session.averageCycleLength,
        status: PeriodStatus.notOnPeriod,
        createdAt: anchor,
      ),
    ];
  }

  /// The period the tracker reads today's status from.
  PeriodLog? latest() {
    final all = history();
    return all.isEmpty ? null : all.first;
  }

  /// First-time setup: is the latest period still going, when did it start,
  /// and — if it is over — how long did it last.
  Future<void> setUpTracking({
    required DateTime start,
    required bool completed,
    required int periodDuration,
    required int averageCycle,
  }) async {
    // An ongoing period gets the predicted length until she marks it ended.
    final duration = completed ? periodDuration : trackerDefaultDuration;
    final startDay = dateOnly(start);
    await _save(
      unit: 'setup',
      data: PeriodLog.newData(
        start: startDay,
        end: addDays(startDay, duration - 1),
        periodDuration: duration,
        averageCycle: averageCycle,
        status: completed ? PeriodStatus.notOnPeriod : PeriodStatus.onPeriod,
        onboarding: true,
      ),
      sameDayAs: startDay,
    );
  }

  /// "Log period start": a new period that is still going.
  ///
  /// Carries her last cycle and period length forward rather than resetting
  /// them to 28 and 5, so a corrected cycle length survives the next log.
  Future<void> logPeriodStart(DateTime start) async {
    final previous = latest();
    await _save(
      unit: 'manual',
      data: PeriodLog.newData(
        start: start,
        status: PeriodStatus.onPeriod,
        periodDuration: previous?.periodDuration ?? trackerDefaultDuration,
        averageCycle: previous?.averageCycle ?? trackerDefaultCycle,
      ),
      sameDayAs: dateOnly(start),
    );
  }

  /// "Mark period ended": records the last day and the length that follows.
  Future<void> markPeriodEnded(PeriodLog log, DateTime end) =>
      _write(log, log.endedData(end));

  /// Corrects a logged period's start, length or cycle length.
  Future<void> editPeriod(
    PeriodLog log, {
    required DateTime start,
    required int periodDuration,
    required int averageCycle,
  }) => _write(
    log,
    log.editedData(
      start: start,
      periodDuration: periodDuration,
      averageCycle: averageCycle,
    ),
  );

  /// Her cycle length measured from what she has actually logged, or null
  /// until two periods are on record.
  int? measuredCycleLength() => cycleLengthFromHistory(_vitals.periodLogs);

  /// [measuredCycleLength] without the database, so it can be tested directly.
  static int? cycleLengthFromHistory(List<PeriodLog> logged) =>
      predictor.observedCycleLength([for (final l in logged) l.start]);

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Updates [log] in place, or saves it as a new period when it was only
  /// derived from her profile LMP.
  Future<void> _write(PeriodLog log, Map<String, dynamic> data) async {
    final id = log.id;
    if (id == null) {
      await _save(unit: 'manual', data: data);
      return;
    }
    await _vitals.updateReading(id, data: data);
    await MainController.instance.loadFromLocal();
  }

  /// Adds a period, or — when one already starts on [sameDayAs] — rewrites
  /// that one, so logging the same day twice does not litter her history.
  Future<void> _save({
    required String unit,
    required Map<String, dynamic> data,
    DateTime? sameDayAs,
  }) async {
    PeriodLog? existing;
    if (sameDayAs != null) {
      for (final l in _vitals.periodLogs) {
        if (l.start == sameDayAs) {
          existing = l;
          break;
        }
      }
    }

    if (existing != null) {
      await _vitals.updateReading(
        existing.id!,
        data: {...existing.data, ...data},
      );
    } else {
      await _vitals.record(VitalKeys.lmpDate, value: 0, unit: unit, data: data);
    }
    await MainController.instance.loadFromLocal();
  }
}
