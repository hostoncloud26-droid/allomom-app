import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/features/pregnancy/widgets/journey_train.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';

const _ancAccent = Color(0xFFFF3B5C);
const _vaccineAccent = Color(0xFF8B5CF6);
const _labAccent = Color(0xFF3898EC);

enum _Kind { anc, vaccine, lab }

/// One ANC visit, vaccine dose or lab report, reduced to what the timeline
/// shows.
class _Item {
  const _Item({
    required this.kind,
    required this.id,
    required this.title,
    required this.date,
    required this.done,
    required this.status,
    required this.month,
  });

  final _Kind kind;
  final String id;
  final String title;
  final DateTime? date;
  final bool done;
  final String status;
  final int month;
}

/// The pregnancy's nine months as a train, with that month's ANC check-ups,
/// vaccinations and lab reports under it — laid out as the baby's milestone
/// track is — then boxes that open each full schedule.
class PregnancyMonthTrack extends StatefulWidget {
  const PregnancyMonthTrack({
    super.key,
    required this.onChanged,
    this.belowTrain,
    this.onMonthSelected,
  });

  /// Called after a schedule page closes, so the page can reload.
  final VoidCallback onChanged;

  /// Shown between the train and the month's schedule.
  final Widget? belowTrain;

  /// Called when the user selects a month wagon on the train.
  final ValueChanged<int>? onMonthSelected;

  @override
  State<PregnancyMonthTrack> createState() => _PregnancyMonthTrackState();
}

class _PregnancyMonthTrackState extends State<PregnancyMonthTrack> {
  int? _month;

  PregnancyController get _preg => PregnancyController.instance;

  /// Pregnancy month (1–9) today, by the same rule the schedules use.
  int get _currentMonth {
    final lmp = _preg.lmpDate;
    if (lmp == null) return 1;
    final days = DateTime.now().difference(lmp).inDays;
    if (days < 0) return 1;
    return ((days / 30.44).floor() + 1).clamp(1, 9);
  }

  int get _selected => _month ?? _currentMonth;

  List<_Item> get _items => [
    for (final a in _preg.ancCheckups)
      _Item(
        kind: _Kind.anc,
        id: a.id,
        title: 'ANC Check-up',
        date: a.scheduledDate,
        done: a.isDone,
        status: a.status,
        month: a.pregnancyMonth.clamp(1, 9),
      ),
    for (final v in _preg.vaccinations)
      _Item(
        kind: _Kind.vaccine,
        id: v.id,
        title: v.vaccineName,
        date: v.scheduledDate,
        done: v.isDone,
        status: v.status,
        month: (v.pregnancyMonth ?? 1).clamp(1, 9),
      ),
    for (final r in _preg.reportChecklists)
      _Item(
        kind: _Kind.lab,
        id: r.id,
        title: r.reportName,
        date: r.expectedDate,
        done: r.isDone,
        status: r.status,
        month: (r.pregnancyMonth ?? 1).clamp(1, 9),
      ),
  ];

  static String _ordinal(int m) => switch (m) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${m}th',
  };

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => page));
    widget.onChanged();
    if (mounted) setState(() {});
  }

  Widget _pageFor(_Kind kind) => switch (kind) {
    _Kind.anc => const AncSchedulePage(),
    _Kind.vaccine => const VaccinationSchedulePage(),
    _Kind.lab => const LabReportsSchedulePage(),
  };

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final inMonth = items.where((i) => i.month == _selected).toList()
      ..sort(_byDate);
    final done = inMonth.where((i) => i.done).length;

    // The next thing to do of each kind, across the whole pregnancy.
    final next = <_Kind, String>{};
    for (final kind in _Kind.values) {
      final pending = items.where((i) => i.kind == kind && !i.done).toList()
        ..sort(_byDate);
      if (pending.isNotEmpty) next[kind] = pending.first.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JourneyTrain(
          title: 'Pregnancy train',
          chip: '${_ordinal(_currentMonth)} month',
          selected: _selected,
          current: _currentMonth,
          onSelected: (m) {
            setState(() => _month = m);
            widget.onMonthSelected?.call(m);
          },
          wagons: [
            for (var m = 1; m <= 9; m++)
              TrainWagon(value: m, number: '$m', label: 'Month'),
          ],
        ),
        if (widget.belowTrain != null) ...[
          const SizedBox(height: 14),
          widget.belowTrain!,
        ],
        const SizedBox(height: 4),
        CareSectionLabel(
          'Upcoming schedule · ${_ordinal(_selected)} month',
          color: context.palette.textSecondary,
        ),
        if (inMonth.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nothing scheduled in the ${_ordinal(_selected)} month.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        for (final (kind, label, color) in const [
          (_Kind.anc, 'ANC Check-ups', _ancAccent),
          (_Kind.vaccine, 'Vaccination', _vaccineAccent),
          (_Kind.lab, 'Lab Reports & Scans', _labAccent),
        ])
          ..._section(
            label,
            color,
            inMonth.where((i) => i.kind == kind).toList(),
            next[kind],
          ),
        if (inMonth.isNotEmpty) ...[
          const SizedBox(height: 8),
          CareProgressCard(done: done, total: inMonth.length),
        ],
        const SizedBox(height: 14),
        _boxes(items),
      ],
    );
  }

  List<Widget> _section(
    String label,
    Color color,
    List<_Item> items,
    String? nextId,
  ) {
    if (items.isEmpty) return const [];
    return [
      CareSectionLabel(label, color: color),
      for (var i = 0; i < items.length; i++)
        CareTimelineTile(
          marker: _marker(items[i], nextId),
          isFirst: i == 0,
          isLast: i == items.length - 1,
          child: _card(items[i], items[i].id == nextId),
        ),
    ];
  }

  CareMarker _marker(_Item i, String? nextId) {
    if (i.done) return CareMarker.done;
    if (i.id == nextId) return CareMarker.next;
    final d = i.date;
    if (d != null && d.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return CareMarker.missed;
    }
    return CareMarker.later;
  }

  Widget _card(_Item i, bool isNext) {
    final p = context.palette;
    final status = CareStatus.resolve(status: i.status, date: i.date);
    final d = i.date;
    return CareCard(
      highlighted: isNext,
      onTap: () => _open(_pageFor(i.kind)),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNext) ...[
                  const Text(
                    'NEXT UP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _ancAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  d == null ? 'Date to be decided' : careDateFmt.format(d),
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  i.title,
                  style: TextStyle(
                    fontSize: isNext ? 16 : 15,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                CarePill(
                  status: status,
                  label:
                      status == CareStatus.scheduled ||
                          status == CareStatus.dueSoon
                      ? 'Upcoming'
                      : null,
                ),
              ],
            ),
          ),
          const CareChevron(),
        ],
      ),
    );
  }

  /// ANC, Vaccination and Lab Reports, each opening its full schedule.
  Widget _boxes(List<_Item> items) {
    String count(_Kind k) {
      final all = items.where((i) => i.kind == k);
      return '${all.where((i) => i.done).length}/${all.length} done';
    }

    return Row(
      children: [
        for (final (kind, icon, color, title) in const [
          (_Kind.anc, Icons.local_hospital_rounded, _ancAccent, 'ANC'),
          (_Kind.vaccine, Icons.vaccines_rounded, _vaccineAccent, 'Vaccination'),
          (_Kind.lab, Icons.science_rounded, _labAccent, 'Lab Reports'),
        ]) ...[
          if (kind != _Kind.anc) const SizedBox(width: 10),
          Expanded(
            child: _box(
              icon: icon,
              color: color,
              title: title,
              count: count(kind),
              onTap: () => _open(_pageFor(kind)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _box({
    required IconData icon,
    required Color color,
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.pick(const Color(0xFFF0F1F5), p.border)),
        boxShadow: [
          BoxShadow(
            color: p.pick(Colors.black.withValues(alpha: 0.03), p.shadow),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: p.tint(color, color.withValues(alpha: 0.10)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _byDate(_Item a, _Item b) {
    final x = a.date;
    final y = b.date;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }
}
