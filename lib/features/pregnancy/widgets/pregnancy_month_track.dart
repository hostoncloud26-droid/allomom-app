import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/widgets/baby_care_carousel.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/features/pregnancy/widgets/journey_train.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';

const _ancAccent = Color(0xFFFF3B5C);
const _vaccineAccent = Color(0xFF8B5CF6);
const _labAccent = Color(0xFF3898EC);

enum _Kind { anc, vaccine, lab }

/// One ANC visit, vaccine dose or lab report, reduced to what a card shows.
class _Item {
  const _Item({
    required this.kind,
    required this.id,
    required this.title,
    required this.date,
    required this.doneAt,
    required this.status,
    required this.month,
  });

  final _Kind kind;
  final String id;
  final String title;
  final DateTime? date;
  final DateTime? doneAt;
  final String status;
  final int month;

  bool get done => doneAt != null;
}

/// The pregnancy's nine months as a train, with the ANC check-ups,
/// vaccinations and lab reports under it as swipeable cards — laid out as
/// the baby's milestone train and carousels are. Picking a month swipes each
/// carousel to that month's first item.
class PregnancyMonthTrack extends StatefulWidget {
  const PregnancyMonthTrack({
    super.key,
    required this.onChanged,
    this.aboveTrain,
    this.onMonthSelected,
  });

  /// Called after an item is marked or a schedule page closes, so the page
  /// can reload.
  final VoidCallback onChanged;

  /// Shown above the train.
  final Widget? aboveTrain;

  /// Called when the user selects a month wagon on the train.
  final ValueChanged<int>? onMonthSelected;

  @override
  State<PregnancyMonthTrack> createState() => _PregnancyMonthTrackState();
}

class _PregnancyMonthTrackState extends State<PregnancyMonthTrack> {
  int? _month;
  CareCarouselFocus? _focus;

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
        // Named by the month it falls in, e.g. "September 2026".
        title: a.scheduledDate == null
            ? 'ANC Check-up'
            : DateFormat('MMMM yyyy').format(a.scheduledDate!),
        date: a.scheduledDate,
        doneAt: a.completedAt,
        status: a.status,
        month: a.pregnancyMonth.clamp(1, 9),
      ),
    for (final v in _preg.vaccinations)
      _Item(
        kind: _Kind.vaccine,
        id: v.id,
        title: v.vaccineName,
        date: v.scheduledDate,
        doneAt: v.receivedDate,
        status: v.status,
        month: (v.pregnancyMonth ?? 1).clamp(1, 9),
      ),
    for (final r in _preg.reportChecklists)
      _Item(
        kind: _Kind.lab,
        id: r.id,
        title: r.reportName,
        date: r.expectedDate,
        doneAt: r.completedDate,
        status: r.status,
        month: (r.pregnancyMonth ?? 1).clamp(1, 9),
      ),
  ];

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    widget.onChanged();
    if (mounted) setState(() {});
  }

  Widget _pageFor(_Kind kind) => switch (kind) {
    _Kind.anc => const AncSchedulePage(),
    _Kind.vaccine => const VaccinationSchedulePage(),
    _Kind.lab => const LabReportsSchedulePage(),
  };

  Future<void> _setDone(_Item i, bool done) async {
    final at = done ? DateTime.now() : null;
    await switch (i.kind) {
      _Kind.anc => _preg.setAncCompleted(i.id, at),
      _Kind.vaccine => _preg.setVaccinationReceived(i.id, at),
      _Kind.lab => _preg.setReportCompleted(i.id, at),
    };
    widget.onChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _items..sort(_byDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.aboveTrain != null) ...[
          widget.aboveTrain!,
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 2),
        JourneyTrain(
          title: 'Pregnancy Checklist',
          selected: _selected,
          current: _currentMonth,
          onSelected: (m) {
            setState(() {
              _month = m;
              _focus = (month: m, seq: (_focus?.seq ?? 0) + 1);
            });
            widget.onMonthSelected?.call(m);
          },
          wagons: [
            for (var m = 1; m <= 9; m++)
              TrainWagon(value: m, number: '$m', label: 'Month'),
          ],
        ),
        const SizedBox(height: 8),
        for (final (kind, label, color) in const [
          (_Kind.anc, 'ANC Check-ups', _ancAccent),
          (_Kind.vaccine, 'Vaccinations', _vaccineAccent),
          (_Kind.lab, 'Lab Reports & Scans', _labAccent),
        ])
          ..._carousel(kind, label, color, items),
      ],
    );
  }

  /// One kind's carousel — left out once the picked month is past its last
  /// item, as vaccinations are after the fifth month.
  List<Widget> _carousel(
    _Kind kind,
    String label,
    Color color,
    List<_Item> all,
  ) {
    final items = all.where((i) => i.kind == kind).toList();
    if (items.isEmpty) return const [];
    final lastMonth = items.map((i) => i.month).reduce((a, b) => a > b ? a : b);
    if (_selected > lastMonth) return const [];
    return [
      CareCarousel<_Item>(
        key: ValueKey(kind),
        title: label,
        accent: color,
        height: 150,
        focus: _focus,
        monthOf: (i) => i.month,
        items: items,
        dateOf: (i) => i.date,
        onShowAll: () => _open(_pageFor(kind)),
        card: _card,
      ),
      const SizedBox(height: 12),
    ];
  }

  /// As the baby's vaccination card: status top right, when it is due, what
  /// it is, and a tick to mark it done once the day arrives.
  Widget _card(_Item i, bool isCurrent) {
    final status = CareStatus.resolve(status: i.status, date: i.date);
    final due = i.date;
    final doneAt = i.doneAt;
    final canMark = careIsDue(due);
    final (kindLabel, doneWord) = switch (i.kind) {
      _Kind.anc => ('ANC Check-up', 'Attended'),
      _Kind.vaccine => ('Vaccination', 'Given'),
      _Kind.lab => ('Lab Report', 'Done'),
    };

    return CareCarouselCard(
      isCurrent: isCurrent,
      pill: switch (status) {
        CareStatus.completed => CarePill(
          status: CareStatus.completed,
          label: doneWord,
        ),
        CareStatus.overdue => const CarePill(
          status: CareStatus.overdue,
          label: 'Overdue',
        ),
        CareStatus.scheduled ||
        CareStatus.dueSoon => CarePill(status: status, label: 'Upcoming'),
        _ => CarePill(status: status),
      },
      eyebrow: doneAt != null
          ? '$doneWord ${careDateFmt.format(doneAt)}'
          : due == null
          ? 'Date to be decided'
          // An ANC's title is already its month and year, and its pregnancy
          // month sits on the top row.
          : i.kind == _Kind.anc
          ? ''
          : 'Due ${careDateFmt.format(due)} · ${relativeDayLabel(due)}',
      tag: i.kind == _Kind.anc ? 'MONTH ${i.month}' : null,
      title: i.title,
      done: i.done,
      actionLabel: canMark
          ? 'Mark as completed'
          : 'Can mark from ${careDateFmt.format(due!)}',
      actionEnabled: canMark,
      onAction: (value) => _setDone(i, value),
      onTap: () => showCareDetailSheet(
        context,
        eyebrow: kindLabel,
        title: i.title,
        status: status,
        facts: [
          (
            Icons.event_rounded,
            due == null
                ? 'Date to be decided'
                : 'Due ${careDateFmt.format(due)}',
          ),
          if (doneAt != null)
            (Icons.verified_rounded, '$doneWord ${careDateFmt.format(doneAt)}'),
        ],
        primaryLabel: i.done ? 'Mark as not done' : 'Mark as completed',
        primaryIcon: i.done
            ? Icons.undo_rounded
            : Icons.check_circle_outline_rounded,
        primaryQuiet: i.done,
        primaryEnabled: i.done || canMark,
        disabledNote: 'You can mark it once the date arrives.',
        onPrimary: () => _setDone(i, !i.done),
        secondaryLabel: 'Open full schedule',
        secondaryIcon: Icons.list_alt_rounded,
        onSecondary: () => _open(_pageFor(i.kind)),
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
