import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/features/pregnancy/data/anc_visit_guide.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/widgets/baby_care_carousel.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/features/pregnancy/widgets/journey_train.dart';
import 'package:allomom/features/pregnancy/widgets/month_weather.dart';
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

/// The ANC check-ups, vaccinations and lab reports of the month the picked
/// week is in, as swipeable cards — laid out as the baby's carousels are.
/// The page owns the picked week and its [PregnancyWeekTrain]; picking a
/// week in another month swipes each carousel to that month's first item.
class PregnancyMonthTrack extends StatefulWidget {
  const PregnancyMonthTrack({
    super.key,
    required this.onChanged,
    required this.currentWeek,
    required this.selectedWeek,
    this.header,
  });

  /// Called after an item is marked or a schedule page closes, so the page
  /// can reload.
  final VoidCallback onChanged;

  /// The pregnancy's week today (1–40), outlined on the train.
  final int currentWeek;

  /// The week picked on the train (1–40).
  final int selectedWeek;

  /// Shown above the carousels.
  final Widget? header;

  /// The pregnancy month (1–9) a week falls in, by the rule the schedules
  /// use, taken at the middle of the week.
  static int monthOfWeek(int week) =>
      (((week * 7 + 3) / 30.44).floor() + 1).clamp(1, 9);

  @override
  State<PregnancyMonthTrack> createState() => _PregnancyMonthTrackState();
}

/// The forty weeks as wagons, with the picked week's month in the heading.
/// Not part of the page: it is pinned to the top once the features grid
/// starts scrolling under it.
class PregnancyWeekTrain extends StatelessWidget {
  const PregnancyWeekTrain({
    super.key,
    required this.currentWeek,
    required this.selectedWeek,
    required this.onSelected,
  });

  final int currentWeek;
  final int selectedWeek;
  final ValueChanged<int> onSelected;

  /// The month a week is in; today's week keeps today's month, by the rule
  /// the schedules use, so the two never disagree at a month's edge.
  static int monthFor(int week, {required int currentWeek}) {
    if (week != currentWeek) return PregnancyMonthTrack.monthOfWeek(week);
    final lmp = PregnancyController.instance.lmpDate;
    if (lmp == null) return 1;
    final days = DateTime.now().difference(lmp).inDays;
    if (days < 0) return 1;
    return ((days / 30.44).floor() + 1).clamp(1, 9);
  }

  @override
  Widget build(BuildContext context) => JourneyTrain(
    title: 'Week Train',
    chip: 'Month ${monthFor(selectedWeek, currentWeek: currentWeek)}',
    selected: selectedWeek,
    current: currentWeek,
    onSelected: onSelected,
    wagons: [
      for (var w = 1; w <= 40; w++)
        TrainWagon(value: w, number: '$w', label: 'Week'),
    ],
  );
}

class _PregnancyMonthTrackState extends State<PregnancyMonthTrack> {
  CareCarouselFocus? _focus;

  PregnancyController get _preg => PregnancyController.instance;

  int _monthOf(int week) =>
      PregnancyWeekTrain.monthFor(week, currentWeek: widget.currentWeek);

  int get _selected => _monthOf(widget.selectedWeek);

  @override
  void didUpdateWidget(covariant PregnancyMonthTrack old) {
    super.didUpdateWidget(old);
    final month = _selected;
    if (old.selectedWeek != widget.selectedWeek &&
        _monthOf(old.selectedWeek) != month) {
      _focus = (month: month, seq: (_focus?.seq ?? 0) + 1);
    }
  }

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
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 16),
        ],
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
    // An ANC is named by its month, so it wears that month's weather.
    final weather = i.kind == _Kind.anc && due != null
        ? MonthWeather.of(due.month, pincode: MainController.instance.pincode)
        : null;
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
      background: weather?.backdrop(context),
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
        description: i.kind == _Kind.anc
            ? AncVisitGuide.forMonth(i.month)
            : null,
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
