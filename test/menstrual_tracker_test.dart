import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/cycle_predictor.dart';
import 'package:allomom/services/menstrual_tracker.dart';

PeriodLog _log({
  required DateTime start,
  String status = PeriodStatus.notOnPeriod,
  int duration = 5,
  int cycle = 28,
  DateTime? end,
}) => PeriodLog.fromData(
  id: 'x',
  createdAt: start,
  data: PeriodLog.newData(
    start: start,
    end: end,
    status: status,
    periodDuration: duration,
    averageCycle: cycle,
  ),
)!;

void main() {
  final lmp = DateTime(2026, 9, 21);

  test('parses the AlloConnect lmp_date blob', () {
    final log = PeriodLog.fromData(
      id: 'a',
      createdAt: lmp,
      data: {
        'lmp_date': '2026-09-21T00:00:00.000',
        'period_end_date': '2026-09-25T00:00:00.000',
        'period_duration': 5,
        'average_cycle': 30.0,
        'status': 'not_on_period',
      },
    )!;
    expect(log.start, lmp);
    expect(log.end, DateTime(2026, 9, 25));
    expect(log.averageCycle, 30);
    expect(log.isOngoing, isFalse);
  });

  test('entries without lmp_date are skipped', () {
    expect(
      PeriodLog.fromData(id: 'a', createdAt: lmp, data: {'mood': 'ok'}),
      isNull,
    );
  });

  test('ongoing period: day count, headline and day-specific guidance', () {
    final s = MenstrualStatus.from(
      _log(start: lmp, status: PeriodStatus.onPeriod),
      today: DateTime(2026, 9, 22),
    );
    expect(s.cycleDay, 2);
    expect(s.phase, CyclePhase.menstrual);
    expect(s.headline, 'Currently bleeding');
    expect(s.guidance.label, 'Day 2 — Heaviest Flow');
    expect(s.nextPeriod, DateTime(2026, 10, 19));
  });

  test('an ongoing period stays menstrual past its predicted length', () {
    final s = MenstrualStatus.from(
      _log(start: lmp, status: PeriodStatus.onPeriod),
      today: DateTime(2026, 9, 28),
    );
    expect(s.guidance.label, 'Day 8 — Extended Period');
    expect(s.isPeriodDay(DateTime(2026, 9, 28)), isTrue);
  });

  test('fertile window is ovulation day -3 to +1', () {
    final log = _log(start: lmp);
    // 28-day cycle: ovulation on day 14, fertile days 11–15.
    expect(
      MenstrualStatus.from(log, today: DateTime(2026, 10, 1)).phase,
      CyclePhase.fertile,
    ); // day 11
    expect(
      MenstrualStatus.from(log, today: DateTime(2026, 9, 30)).phase,
      CyclePhase.follicular,
    ); // day 10
    expect(
      MenstrualStatus.from(log, today: DateTime(2026, 10, 6)).phase,
      CyclePhase.luteal,
    ); // day 16
    expect(
      MenstrualStatus.from(log, today: lmp).ovulationDate,
      DateTime(2026, 10, 4),
    );
  });

  test('late periods count from the logged start instead of rolling on', () {
    final s = MenstrualStatus.from(
      _log(start: lmp),
      today: DateTime(2026, 10, 24),
    );
    expect(s.cycleDay, 34);
    expect(s.overdueDays, 5);
    expect(s.phase, CyclePhase.late);
    expect(s.headline, 'Period late by 5 days');
    expect(s.guidance.label, 'Late by 5 days — 1 Week');
    expect(s.calendarDays.last, DateTime(2026, 10, 24));
  });

  test('marking a period ended records the end and derived length', () {
    final log = _log(start: lmp, status: PeriodStatus.onPeriod);
    final ended = PeriodLog.fromData(
      id: log.id,
      createdAt: log.createdAt,
      data: log.endedData(DateTime(2026, 9, 26)),
    )!;
    expect(ended.isOngoing, isFalse);
    expect(ended.periodDuration, 6);
    expect(ended.end, DateTime(2026, 9, 26));
  });

  test('editing recomputes the end date from the new length', () {
    final edited = PeriodLog.fromData(
      id: 'x',
      createdAt: lmp,
      data: _log(start: lmp).editedData(
        start: DateTime(2026, 9, 20),
        periodDuration: 4,
        averageCycle: 32,
      ),
    )!;
    expect(edited.start, DateTime(2026, 9, 20));
    expect(edited.end, DateTime(2026, 9, 23));
    expect(edited.averageCycle, 32);
  });

  test('newest period first, by start date', () {
    final sorted = sortPeriodLogs([
      _log(start: DateTime(2026, 7, 25)),
      _log(start: lmp),
      _log(start: DateTime(2026, 8, 23)),
    ]);
    expect(sorted.first.start, lmp);
  });
}
