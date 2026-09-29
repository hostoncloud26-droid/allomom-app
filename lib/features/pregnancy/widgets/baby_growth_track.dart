import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/features/pregnancy/widgets/journey_train.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';

const _pink = Color(0xFFFF3B5C);
const _vaccineAccent = Color(0xFF8B5CF6);
const _milestoneAccent = Color(0xFFF59E0B);

/// What the track lists under the train.
enum BabyTrackMode { all, vaccinations, milestones }

/// Whole months from [birth] to [date], never below zero — the wagon a dated
/// item rides in.
int babyMonthOf(DateTime birth, DateTime? date) {
  if (date == null) return 0;
  final b = DateUtils.dateOnly(birth);
  final d = DateUtils.dateOnly(date);
  var months = (d.year - b.year) * 12 + d.month - b.month;
  if (d.day < b.day) months--;
  return months < 0 ? 0 : months;
}

/// A baby's first months as a train — `babytrain.png` pulling one wagon per
/// month — with that month's vaccinations and milestones under it, laid out
/// as the ANC schedule is: a rail of markers, a card per item, the next thing
/// to do outlined in pink.
class BabyGrowthTrack extends StatefulWidget {
  const BabyGrowthTrack({
    super.key,
    required this.baby,
    required this.doses,
    required this.milestones,
    required this.onDoseGiven,
    required this.onMilestoneReached,
    this.mode = BabyTrackMode.all,
    this.trainOnly = false,
    this.onMonthSelected,
  });

  /// Just the train, without the lists — for a page that shows the items its
  /// own way and follows the wagon picked through [onMonthSelected].
  final bool trainOnly;

  /// Called with the month of the wagon picked.
  final ValueChanged<int>? onMonthSelected;

  /// Both lists, or just one of them — the Vaccination and Milestones pages.
  final BabyTrackMode mode;

  final Baby baby;
  final List<BabyImmunizationRecord> doses;
  final List<BabyMilestone> milestones;

  /// Marks a dose given (true) or not given yet (false).
  final Future<void> Function(BabyImmunizationRecord dose, bool given)
  onDoseGiven;

  /// Marks a milestone reached (true) or not yet (false).
  final Future<void> Function(BabyMilestone milestone, bool reached)
  onMilestoneReached;

  @override
  State<BabyGrowthTrack> createState() => _BabyGrowthTrackState();
}

class _BabyGrowthTrackState extends State<BabyGrowthTrack> {
  /// The wagon picked; defaults to the month the baby is in now.
  int? _month;

  DateTime get _birth => DateUtils.dateOnly(widget.baby.deliveryDate);

  /// Whole months from birth to [date], never below zero.
  int _monthOf(DateTime? date) => babyMonthOf(_birth, date);

  int get _ageMonth => _monthOf(DateTime.now());

  /// Every month that has something in it, plus the one the baby is in now.
  List<int> get _wagons {
    final months = <int>{
      _ageMonth,
      if (widget.mode != BabyTrackMode.milestones)
        for (final d in widget.doses) _monthOf(d.expectedDate),
      if (widget.mode != BabyTrackMode.vaccinations)
        for (final m in widget.milestones) _monthOf(m.expectedDate),
    };
    return months.toList()..sort();
  }

  /// The "All" wagon — every item, grouped by month.
  static const _all = -1;

  /// Only the single-list pages (Vaccination, Milestones) get an "All" wagon,
  /// and open on it.
  bool get _hasAll => widget.mode != BabyTrackMode.all;

  int get _selected => _month ?? (_hasAll ? _all : _ageMonth);

  bool _inSelection(DateTime? date) =>
      _selected == _all || _monthOf(date) == _selected;

  @override
  void didUpdateWidget(covariant BabyGrowthTrack old) {
    super.didUpdateWidget(old);
    if (old.baby.id != widget.baby.id) _month = null;
  }

  static String _monthName(int m) => m == 0
      ? 'Newborn'
      : m == 1
      ? '1 Month'
      : '$m Months';

  @override
  Widget build(BuildContext context) {
    if (widget.trainOnly) return _train(context);
    final showDoses = widget.mode != BabyTrackMode.milestones;
    final showMilestones = widget.mode != BabyTrackMode.vaccinations;
    final doses = !showDoses
        ? <BabyImmunizationRecord>[]
        : (widget.doses
              .where((d) => _inSelection(d.expectedDate))
              .toList()
            ..sort(_byDate((d) => d.expectedDate)));
    final milestones = !showMilestones
        ? <BabyMilestone>[]
        : (widget.milestones
              .where((m) => _inSelection(m.expectedDate))
              .toList()
            ..sort(_byDate((m) => m.expectedDate)));
    final done =
        doses.where((d) => d.vaccinationDate != null).length +
        milestones.where((m) => m.achieved).length;
    final total = doses.length + milestones.length;

    // The one item in the whole record due next — only it is outlined.
    final nextDose = (widget.doses.where((d) => d.vaccinationDate == null)
            .toList()
          ..sort(_byDate((d) => d.expectedDate)))
        .firstOrNull;
    final nextMilestone = (widget.milestones.where((m) => !m.achieved).toList()
          ..sort(_byDate((m) => m.expectedDate)))
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _train(context),
        const SizedBox(height: 4),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              _selected == _all
                  ? 'Nothing scheduled yet.'
                  : 'Nothing scheduled for ${_monthName(_selected).toLowerCase()}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        if (doses.isNotEmpty)
          ..._timeline<BabyImmunizationRecord>(
            label: 'Vaccination',
            color: _vaccineAccent,
            items: doses,
            dateOf: (d) => d.expectedDate,
            marker: (d) => _doseMarker(d, nextDose),
            card: (d) => _doseCard(d, d.id == nextDose?.id),
          ),
        if (milestones.isNotEmpty)
          ..._timeline<BabyMilestone>(
            label: 'Milestones',
            color: _milestoneAccent,
            items: milestones,
            dateOf: (m) => m.expectedDate,
            marker: (m) => _milestoneMarker(m, nextMilestone),
            card: (m) => _milestoneCard(m, m.id == nextMilestone?.id),
          ),
        // The month's progress, under the list.
        if (total > 0) ...[
          const SizedBox(height: 8),
          CareProgressCard(done: done, total: total),
        ],
      ],
    );
  }

  /// One list on the rail. Under "All" it is broken up by month, each month
  /// under its own heading; otherwise it is one run under [label].
  List<Widget> _timeline<T>({
    required String label,
    required Color color,
    required List<T> items,
    required DateTime? Function(T) dateOf,
    required CareMarker Function(T) marker,
    required Widget Function(T) card,
  }) {
    List<Widget> run(List<T> group) => [
      for (var i = 0; i < group.length; i++)
        CareTimelineTile(
          marker: marker(group[i]),
          isFirst: i == 0,
          isLast: i == group.length - 1,
          child: card(group[i]),
        ),
    ];

    if (_selected != _all) {
      return [CareSectionLabel(label, color: color), ...run(items)];
    }
    final byMonth = <int, List<T>>{};
    for (final item in items) {
      byMonth.putIfAbsent(_monthOf(dateOf(item)), () => []).add(item);
    }
    final months = byMonth.keys.toList()..sort();
    return [
      for (final m in months) ...[
        CareSectionLabel(_monthName(m), color: color),
        ...run(byMonth[m]!),
      ],
    ];
  }

  // ── The train ─────────────────────────────────────────────────────────────

  Widget _train(BuildContext context) {
    final days = DateTime.now().difference(_birth).inDays;
    return JourneyTrain(
      title: 'Milestone train',
      chip: days < 0 ? 'Due' : 'Day ${days + 1}',
      selected: _selected,
      current: _ageMonth,
      onSelected: (m) {
        setState(() => _month = m);
        widget.onMonthSelected?.call(m);
      },
      wagons: [
        if (_hasAll)
          const TrainWagon(value: _all, number: 'All', label: 'Months'),
        for (final m in _wagons)
          TrainWagon(
            value: m,
            number: '$m',
            label: m == 0 ? 'Newborn' : (m == 1 ? 'Month' : 'Months'),
          ),
      ],
    );
  }

  // ── Vaccinations ──────────────────────────────────────────────────────────

  CareMarker _doseMarker(BabyImmunizationRecord d, BabyImmunizationRecord? next) {
    if (d.vaccinationDate != null) return CareMarker.done;
    if (d.id == next?.id) return CareMarker.next;
    final due = d.expectedDate;
    if (due != null && due.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return CareMarker.missed;
    }
    return CareMarker.later;
  }

  CareStatus _doseStatus(BabyImmunizationRecord d) => CareStatus.resolve(
    status: d.vaccinationDate != null ? 'done' : 'pending',
    date: d.expectedDate,
  );

  Widget _doseCard(BabyImmunizationRecord d, bool isNext) {
    final p = context.palette;
    final status = _doseStatus(d);
    final given = d.vaccinationDate;
    final due = d.expectedDate;
    return _itemCard(
      isNext: isNext,
      eyebrow: given != null
          ? 'Given ${careDateFmt.format(given)}'
          : due == null
          ? 'No due date set'
          : 'Due ${careDateFmt.format(due)}',
      title: d.vaccineName,
      trailing: isNext ? null : CarePill(status: status),
      p: p,
      onTap: () => _openDose(d),
    );
  }

  void _openDose(BabyImmunizationRecord d) {
    final status = _doseStatus(d);
    final given = d.vaccinationDate != null;
    showCareDetailSheet(
      context,
      eyebrow: _monthName(_monthOf(d.expectedDate)),
      title: d.vaccineName,
      status: status,
      facts: [
        (
          Icons.event_rounded,
          d.expectedDate == null
              ? 'Date to be decided'
              : 'Due ${careDateFmt.format(d.expectedDate!)}',
        ),
        if (given)
          (
            Icons.verified_rounded,
            'Given ${careDateFmt.format(d.vaccinationDate!)}',
          ),
      ],
      primaryLabel: given ? 'Mark as not given' : 'Mark as given',
      primaryIcon: given ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
      primaryQuiet: given,
      primaryEnabled: given || careIsDue(d.expectedDate),
      disabledNote: 'You can mark it once the due date arrives.',
      onPrimary: () => widget.onDoseGiven(d, !given),
    );
  }

  // ── Milestones ────────────────────────────────────────────────────────────

  /// Milestones are guides, not deadlines — a late one is never "missed".
  CareMarker _milestoneMarker(BabyMilestone m, BabyMilestone? next) {
    if (m.achieved) return CareMarker.done;
    if (m.id == next?.id) return CareMarker.next;
    return CareMarker.later;
  }

  Widget _milestoneCard(BabyMilestone m, bool isNext) {
    final p = context.palette;
    return _itemCard(
      isNext: isNext,
      eyebrow: m.completedAt != null
          ? 'Reached ${careDateFmt.format(m.completedAt!)}'
          : m.expectedDate == null
          ? 'Any time now'
          : 'Usually around ${careDateFmt.format(m.expectedDate!)}',
      title: m.milestone,
      subtitle: m.description,
      trailing: m.achieved && !isNext
          ? const CarePill(status: CareStatus.completed)
          : null,
      p: p,
      onTap: () => _openMilestone(m),
    );
  }

  void _openMilestone(BabyMilestone m) {
    final reached = m.achieved;
    showCareDetailSheet(
      context,
      eyebrow: _monthName(_monthOf(m.expectedDate)),
      title: m.milestone,
      status: CareStatus.resolve(
        status: reached ? 'done' : 'pending',
        date: m.expectedDate,
      ),
      statusLabel: reached ? null : 'Watch for it',
      facts: [
        if (m.description.isNotEmpty) (Icons.info_outline_rounded, m.description),
        if (m.expectedDate != null)
          (
            Icons.event_rounded,
            'Usually around ${careDateFmt.format(m.expectedDate!)}',
          ),
        if (reached)
          (
            Icons.emoji_events_rounded,
            'Reached ${careDateFmt.format(m.completedAt!)}',
          ),
      ],
      primaryLabel: reached ? 'Mark as not yet' : 'Mark as reached',
      primaryIcon: reached ? Icons.undo_rounded : Icons.emoji_events_rounded,
      primaryQuiet: reached,
      onPrimary: () => widget.onMilestoneReached(m, !reached),
    );
  }

  // ── Shared card ───────────────────────────────────────────────────────────

  Widget _itemCard({
    required bool isNext,
    required String eyebrow,
    required String title,
    String? subtitle,
    Widget? trailing,
    required AppPalette p,
    required VoidCallback onTap,
  }) {
    return CareCard(
      highlighted: isNext,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                          color: _pink,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      eyebrow,
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isNext ? 16.5 : 15,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(height: 8),
                      trailing,
                    ],
                  ],
                ),
              ),
              const CareChevron(),
            ],
          ),
          if (isNext)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: CareOutlineButton(label: 'View details', onTap: onTap),
              ),
            ),
        ],
      ),
    );
  }

  /// Sorts by date with undated items last.
  static int Function(T, T) _byDate<T>(DateTime? Function(T) dateOf) {
    return (a, b) {
      final x = dateOf(a);
      final y = dateOf(b);
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    };
  }
}
