import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_custom_activity.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/todays_care_checklist_page.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_count_sheet.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/health_vital_sync_service.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

/// Today's care, scoped to the current part of the day.
///
/// The list is rebuilt from [careItemsFor] whenever the clock crosses into a
/// new [CareDayPart], so before 11 AM it asks about breakfast, the afternoon
/// asks about lunch and the evening about dinner. Completion is read back from
/// the vitals the rest of the app already writes (`breakfast`, `lunch`,
/// `dinner`, `snacks`, `water`, `drinks`) plus the `todocare` tick-offs, so
/// logging a meal in My Health also ticks it off here.
class TodocareSection extends StatefulWidget {
  const TodocareSection({super.key, this.allDayParts = false});

  /// Every window of the day, instead of only the one the clock is in.
  ///
  /// Home shows the current window — the three or four things she can act on
  /// right now. [TodaysCareChecklistPage], which "View more" opens, shows the
  /// lot grouped by window, and reuses this widget so the sheets, the tick-off
  /// writes and the completion rules are the same ones, not a second copy.
  final bool allDayParts;

  @override
  State<TodocareSection> createState() => _TodocareSectionState();
}

class _TodocareSectionState extends State<TodocareSection> {
  /// How often we re-check whether the day part changed under us.
  static const _slotWatchInterval = Duration(minutes: 1);

  CareDayPart _part = CareDayPart.at();

  /// Each window and what it asks for. One entry on home, all of them on the
  /// checklist page.
  List<_CareGroup> _groups = const [];

  /// Every item across [_groups], which is what progress and the loaders read.
  List<CareItem> _items = const [];

  /// The clock hour each item sits at on the timeline.
  Map<CareItem, int> _hours = const {};

  /// Her own activities, by the id their [CareItem] carries.
  Map<String, CareCustomActivity> _customById = const {};
  bool _isLoading = true;

  /// `todocare` action values already ticked off today.
  Set<String> _completedActions = <String>{};

  /// Today's `todocare` rows behind each ticked action, so un-ticking can
  /// delete exactly them.
  Map<String, List<String>> _todocareRowIds = const {};

  /// Count-item vital key -> amount logged today (glasses, cups, portions).
  Map<String, int> _countsToday = <String, int>{};

  /// Meal vital keys logged today.
  Set<String> _mealsLogged = <String>{};

  /// `doneVitalKey`s that already have a row today.
  Set<String> _navigateDone = <String>{};

  Timer? _slotTimer;

  /// `addVitalEntry` notifies listeners several times per write, and each
  /// notification would otherwise kick off a fresh round of queries. Coalesce
  /// them: run one refresh at a time and remember if another was asked for.
  bool _isRefreshing = false;
  bool _refreshQueued = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    HealthVitalsController.instance.addListener(_onVitalsChanged);
    _slotTimer = Timer.periodic(
      _slotWatchInterval,
      (_) => _checkSlotRollover(),
    );
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
    HealthVitalsController.instance.removeListener(_onVitalsChanged);
    super.dispose();
  }

  void _onVitalsChanged() {
    if (mounted) _refresh();
  }

  /// Rebuilds when the clock moves into a new window (e.g. the user leaves the
  /// app open through 11 AM and breakfast becomes the mid-morning snack).
  void _checkSlotRollover() {
    final current = CareDayPart.at();
    if (current != _part && mounted) _refresh();
  }

  // ─── LOADING ────────────────────────────────────────────────

  Future<void> _refresh() async {
    if (_isRefreshing) {
      _refreshQueued = true;
      return;
    }
    _isRefreshing = true;
    try {
      do {
        _refreshQueued = false;
        await _loadOnce();
      } while (_refreshQueued && mounted);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadOnce() async {
    final session = MainController.instance;
    final part = CareDayPart.at();
    final parts = widget.allDayParts ? CareDayPart.values : <CareDayPart>[part];

    final customs = await CareCustomActivityStore.load();
    final hours = <CareItem, int>{};
    final customById = <String, CareCustomActivity>{};

    final babyAgeDays = WeeklyBabyTalk.babyAgeDays();
    final groups = <_CareGroup>[];
    for (final window in parts) {
      final items = <CareItem>[];
      for (final item in careItemsFor(
        part: window,
        isPregnant: session.isPregnant,
        pregnancyDay: session.currentPregnancyDay,
        babyAgeDays: babyAgeDays,
      )) {
        items.add(item);
        hours[item] = careHourFor(item.id, window);
      }
      // Her own activities join the window their hour falls in, so progress,
      // tick-offs and `day_part` treat them like any other item.
      for (final custom in customs) {
        if (_partAtHour(custom.hour) != window) continue;
        final item = custom.toCareItem();
        items.add(item);
        hours[item] = custom.hour;
        customById[item.id] = custom;
      }
      groups.add(_CareGroup(part: window, items: items));
    }
    final items = [for (final group in groups) ...group.items];

    final ticks = await _loadTodocareTicks();
    final counts = await _loadCountsToday(items);
    final meals = await _loadMealsLoggedToday(items);
    final navigated = await _loadNavigateDone(items);

    if (!mounted) return;
    setState(() {
      _part = part;
      _groups = groups;
      _items = items;
      _hours = hours;
      _customById = customById;
      _completedActions = ticks.actions;
      _todocareRowIds = ticks.rowIds;
      _countsToday = counts;
      _mealsLogged = meals;
      _navigateDone = navigated;
      _isLoading = false;
    });
  }

  /// Today's tick-offs, read from the `todocare` rows in the vitals stream.
  ///
  /// The vitals table is the only record: a tick is a row, an un-tick deletes
  /// it, and both reach the server through the `vitals` sync. Each row is
  /// indexed under every value it carries, since older builds wrote the action
  /// to different fields.
  Future<({Set<String> actions, Map<String, List<String>> rowIds})>
  _loadTodocareTicks() async {
    final actions = <String>{};
    final rowIds = <String, List<String>>{};

    final userId = MainController.instance.userId;
    if (userId.isEmpty) return (actions: actions, rowIds: rowIds);

    try {
      final rows = await VitalsSqLiteService().getVitalsHistory(
        userId,
        'todocare',
        fromDate: _startOfToday(),
      );

      for (final row in rows) {
        final id = row['id']?.toString();
        final values = <String>{
          ?row['unit']?.toString().toLowerCase().trim(),
          for (final value in _decodeData(row).values)
            ?value?.toString().toLowerCase().trim(),
        }..removeWhere((v) => v.isEmpty);

        for (final value in values) {
          actions.add(value);
          if (id != null) rowIds.putIfAbsent(value, () => []).add(id);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Could not read todocare vitals: $e');
    }

    return (actions: actions, rowIds: rowIds);
  }

  /// Sums today's rows for each count item. Rows hold increments, so a sum is
  /// the running total for the day.
  ///
  /// Calorie-backed keys (`snacks`, `drinks`) store kcal in the value, so the
  /// count is read from `data['count']`. Rows written elsewhere in the app
  /// (My Health's snack dialog) carry no count, so they count as one unit.
  Future<Map<String, int>> _loadCountsToday(List<CareItem> items) async {
    final counts = <String, int>{};
    final userId = MainController.instance.userId;
    if (userId.isEmpty) return counts;

    final countItems = items
        .where((i) => i.kind == CareActionKind.count && i.countVitalKey != null)
        .toList();

    for (final item in countItems) {
      final key = item.countVitalKey!;
      if (counts.containsKey(key)) continue;

      try {
        final rows = await VitalsSqLiteService().getVitalsHistory(
          userId,
          key,
          fromDate: _startOfToday(),
        );

        // Summed before rounding: water can arrive in part-glasses (a 100 ml
        // entry is 0.4), and rounding each row would drop them.
        var total = 0.0;
        for (final row in rows) {
          if (item.caloriesPerUnit == null) {
            total += (row['value'] as num?)?.toDouble() ?? 0;
          } else {
            final recorded = _decodeData(row)['count'];
            final parsed = recorded is num
                ? recorded.round()
                : int.tryParse(recorded?.toString() ?? '');
            total += parsed ?? 1;
          }
        }
        final rounded = total.round();
        counts[key] = rounded < 0 ? 0 : rounded;
      } catch (e) {
        debugPrint('⚠️ [TodocareSection] Could not read "$key" vitals: $e');
      }
    }

    return counts;
  }

  Future<Set<String>> _loadMealsLoggedToday(List<CareItem> items) async {
    final logged = <String>{};
    final userId = MainController.instance.userId;
    if (userId.isEmpty) return logged;

    final meals = items.map((i) => i.meal).whereType<CareMeal>().toSet();
    for (final meal in meals) {
      final keys = <String>[meal.vitalKey, ?meal.legacyVitalKey];
      for (final key in keys) {
        try {
          final rows = await VitalsSqLiteService().getVitalsHistory(
            userId,
            key,
            fromDate: _startOfToday(),
          );
          if (rows.isNotEmpty) {
            logged.add(meal.vitalKey);
            break;
          }
        } catch (e) {
          debugPrint('⚠️ [TodocareSection] Could not read "$key" vitals: $e');
        }
      }
    }

    return logged;
  }

  /// Marks a navigate item done when the screen it opens has already written
  /// its vital today (e.g. kicks counted in the kick counter).
  Future<Set<String>> _loadNavigateDone(List<CareItem> items) async {
    final done = <String>{};
    final userId = MainController.instance.userId;
    if (userId.isEmpty) return done;

    final keys = items.map((i) => i.doneVitalKey).whereType<String>().toSet();
    for (final key in keys) {
      try {
        final rows = await VitalsSqLiteService().getVitalsHistory(
          userId,
          key,
          fromDate: _startOfToday(),
        );
        if (rows.isNotEmpty) done.add(key);
        // Also by window, for items that recur through the day (feeds).
        for (final row in rows) {
          final raw = row['createdAt'];
          final at = raw is DateTime
              ? raw
              : DateTime.tryParse(raw?.toString() ?? '');
          if (at != null) done.add('$key@${CareDayPart.at(at.toLocal()).name}');
        }
      } catch (e) {
        debugPrint('⚠️ [TodocareSection] Could not read "$key" vitals: $e');
      }
    }

    return done;
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static CareDayPart _partAtHour(int hour) {
    final now = DateTime.now();
    return CareDayPart.at(DateTime(now.year, now.month, now.day, hour));
  }

  static Map<String, dynamic> _decodeData(Map<String, dynamic> row) {
    final raw = row['data'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Not JSON — nothing to pull out of it.
      }
    }
    return const {};
  }

  // ─── STATE OF AN ITEM ───────────────────────────────────────

  bool _isDone(CareItem item) => switch (item.kind) {
    CareActionKind.meal => _mealsLogged.contains(item.meal!.vitalKey),
    CareActionKind.count =>
      _countFor(item) > 0 &&
          (item.dailyTarget == null || _countFor(item) >= item.dailyTarget!),
    CareActionKind.checkoff => _completedActions.contains(
      item.actionValue?.toLowerCase().trim(),
    ),
    CareActionKind.navigate => _navigateDone.contains(
      item.donePerPart
          ? '${item.doneVitalKey}@${_partOf(item).name}'
          : item.doneVitalKey,
    ),
  };

  int _countFor(CareItem item) => _countsToday[item.countVitalKey] ?? 0;

  /// The window [item] belongs to, which is what its `day_part` records — on
  /// the checklist page that is not always the window the clock is in.
  CareDayPart _partOf(CareItem item) {
    for (final group in _groups) {
      if (group.items.contains(item)) return group.part;
    }
    return _part;
  }

  /// Trailing status line for count items, e.g. "4 of 10 glasses today".
  String? _progressLabel(CareItem item) {
    if (item.kind != CareActionKind.count) return null;
    final logged = _countFor(item);
    if (logged == 0) return null;
    final unit = logged == 1 ? item.unitSingular : item.unitPlural;
    final target = item.dailyTarget;
    return target == null
        ? '$logged $unit today'
        : '$logged of $target $unit today';
  }

  // ─── ACTIONS ────────────────────────────────────────────────

  Future<void> _onItemTap(CareItem item) async {
    switch (item.kind) {
      case CareActionKind.meal:
        await _logMeal(item);
      case CareActionKind.count:
        await _logCount(item);
      case CareActionKind.checkoff:
        await _toggleCheckoff(item);
      case CareActionKind.navigate:
        await _navigate(item);
    }
  }

  Future<void> _logMeal(CareItem item) async {
    final meal = item.meal!;
    final log = await CareMealSheet.show(
      context,
      meal: meal,
      color: item.color,
      icon: item.icon,
      suggestion: item.subtitle,
    );
    if (log == null) return;

    HapticFeedback.mediumImpact();
    try {
      await HealthVitalsController.instance.addVitalEntry(
        key: meal.vitalKey,
        value: log.calories,
        unit: 'kcal',
        createdAt: DateTime.now(),
        userId: _userIdOrNull(),
        data: {
          'items': log.details,
          'details': log.details,
          'meal': meal.label,
          'meal_type': meal.vitalKey,
          'type': meal.vitalKey,
          'day_part': _partOf(item).name,
        },
      );
      speak(NarrationKeys.pgConfMealSaved, force: true);
      _showLogged('${meal.label} logged · ${log.calories.round()} kcal');
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Error logging ${meal.vitalKey}: $e');
      _showError('Could not log ${meal.label.toLowerCase()}');
    }

    await _refresh();
  }

  Future<void> _logCount(CareItem item) async {
    final amount = await CareCountSheet.show(
      context,
      title: item.title,
      unitLabel: item.unitPlural,
      unitLabelSingular: item.unitSingular,
      icon: item.icon,
      color: item.color,
      loggedToday: _countFor(item),
      target: item.dailyTarget,
      presets: item.presets,
      subtitle: item.subtitle,
      // Water is the only count with a recorded line; the rest open silent.
      narrationKey: item.countVitalKey == 'water'
          ? NarrationKeys.pgNutritionWater
          : null,
    );
    if (amount == null) return;

    HapticFeedback.mediumImpact();
    final unit = amount == 1 ? item.unitSingular : item.unitPlural;
    final caloriesPerUnit = item.caloriesPerUnit;
    try {
      await HealthVitalsController.instance.addVitalEntry(
        key: item.countVitalKey!,
        value: caloriesPerUnit == null
            ? amount.toDouble()
            : (amount * caloriesPerUnit).toDouble(),
        unit: caloriesPerUnit == null ? item.unitPlural : 'kcal',
        createdAt: DateTime.now(),
        userId: _userIdOrNull(),
        data: {
          'details': '$amount $unit',
          'type': item.countVitalKey,
          'count': amount,
          'count_unit': item.unitPlural,
          'day_part': _partOf(item).name,
        },
      );
      if (item.countVitalKey == 'water') {
        speak(NarrationKeys.pgConfWaterAdded, force: true);
      }
      _showLogged('Logged $amount $unit');
    } catch (e) {
      debugPrint(
        '⚠️ [TodocareSection] Error logging ${item.countVitalKey}: $e',
      );
      _showError('Could not log ${item.title.toLowerCase()}');
    }

    await _refresh();
  }

  /// Ticks an item off, or undoes it.
  ///
  /// A tick writes a `todocare` row to the vitals stream; undoing it deletes
  /// today's rows for that action. Either way the vitals sync carries it to the
  /// server, so a tick and an undo look the same on every device.
  Future<void> _toggleCheckoff(CareItem item) async {
    final action = item.actionValue;
    if (action == null) return;

    final normalized = action.toLowerCase().trim();
    final wasDone = _completedActions.contains(normalized);

    HapticFeedback.selectionClick();
    setState(() {
      if (wasDone) {
        _completedActions.remove(normalized);
      } else {
        _completedActions.add(normalized);
      }
    });

    if (wasDone) {
      try {
        for (final id in _todocareRowIds[normalized] ?? const <String>[]) {
          await VitalsSqLiteService().deleteVital(id);
        }
        await HealthVitalSyncService.instance.syncUnsyncedVitals();
      } catch (e) {
        debugPrint('⚠️ [TodocareSection] Error undoing todocare: $e');
        _showError('Could not undo ${item.title.toLowerCase()}');
      }
      await _refresh();
      return;
    }

    // addVitalEntry saves the row with synced = 0 and starts the vitals sync.
    final session = MainController.instance;
    try {
      await HealthVitalsController.instance.addVitalEntry(
        key: 'todocare',
        value: 1.0,
        unit: action,
        createdAt: DateTime.now(),
        userId: _userIdOrNull(),
        data: {
          'value': action,
          'action': action,
          'todocare': action,
          'details': action,
          'title': item.title,
          'day_part': _partOf(item).name,
          'pregnancy_day': session.isPregnant ? session.currentPregnancyDay : 0,
          'is_pregnant': session.isPregnant,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Error logging todocare: $e');
      _showError('Could not save ${item.title.toLowerCase()}');
    }
    await _refresh();
  }

  Future<void> _navigate(CareItem item) async {
    switch (item.destination) {
      case CareDestination.kickCounter:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const KickCounterPage()));
      case CareDestination.feedingTracker:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FeedingTrackerPage()));
      case null:
        return;
    }
    if (mounted) await _refresh();
  }

  String? _userIdOrNull() {
    final id = MainController.instance.userId.trim();
    return id.isEmpty ? null : id;
  }

  void _showLogged(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────

  int get _doneCount => _items.where(_isDone).length;

  static final _hourFmt = DateFormat('hh:mm a');

  static String _hourLabel(int hour) =>
      _hourFmt.format(DateTime(2000, 1, 1, hour));

  /// The day as the timeline reads it: from 5 AM, when the morning window
  /// opens, round to 4 AM.
  static final List<int> _dayHours = [
    for (var i = 0; i < 24; i++) (5 + i) % 24,
  ];

  /// The hours the window the clock is in covers, for the home card.
  List<int> get _windowHours =>
      _dayHours.where((h) => _partAtHour(h) == _part).toList();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final p = context.palette;
    final progress = _items.isEmpty ? 0.0 : _doneCount / _items.length;
    final name = MainController.instance.userName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    Text(
                      widget.allDayParts
                          ? '${_part.greeting}, $name'
                          : "Today's care",
                      style: GoogleFonts.outfit(
                        fontSize: widget.allDayParts ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.allDayParts
                          ? 'Your day, hour by hour'
                          : '${_part.greeting}, $name · ${_part.headline}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (widget.allDayParts)
                _AddActivityButton(onTap: () => _addActivity())
              else
                _DayPartBadge(part: _part),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: p.pick(const Color(0xFFF0F2F5), p.surface),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$_doneCount/${_items.length}',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Home shows the hours of the window she is in; the checklist page
          // the whole day. Both leave empty hours open to add to.
          _buildTimeline(widget.allDayParts ? _dayHours : _windowHours),

          if (!widget.allDayParts) ...[
            const SizedBox(height: 4),
            _buildViewMore(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(List<int> hours) {
    final byHour = <int, List<CareItem>>{};
    for (final item in _items) {
      final hour = _hours[item] ?? _partOf(item).startHour;
      byHour.putIfAbsent(hour, () => []).add(item);
    }
    final nowHour = DateTime.now().hour;

    return Column(
      children: [
        for (var i = 0; i < hours.length; i++)
          _TimelineRow(
            label: _hourLabel(hours[i]),
            isNow: hours[i] == nowHour,
            isFirst: i == 0,
            isLast: i == hours.length - 1,
            child: (byHour[hours[i]] ?? const []).isEmpty
                ? _EmptySlot(onTap: () => _addActivity(hour: hours[i]))
                : Column(
                    children: [
                      for (final item in byHour[hours[i]]!)
                        _buildTimelineCard(item),
                    ],
                  ),
          ),
      ],
    );
  }

  /// Opens the rest of today. Home only ever shows the window she is in, and
  /// the other windows were unreachable until this.
  Widget _buildViewMore() {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TodaysCareChecklistPage()),
        );
        // She may have logged something while she was in there.
        if (mounted) await _refresh();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.schedule_rounded, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'View full day',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// One activity on the timeline: its icon in a soft circle, the name in
  /// capitals, what to do, and — for a count — how far through the day's goal
  /// she is.
  Widget _buildTimelineCard(CareItem item) {
    final p = context.palette;
    final isDone = _isDone(item);
    final progressLabel = _progressLabel(item);
    final isTickable = item.kind == CareActionKind.checkoff;
    final custom = _customById[item.id];
    final target = item.dailyTarget;
    final countProgress = item.kind == CareActionKind.count && target != null
        ? (_countFor(item) / target).clamp(0.0, 1.0)
        : null;

    return GestureDetector(
      onTap: () => _onItemTap(item),
      onLongPress: custom == null ? null : () => _confirmRemove(custom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? const Color(
                    0xFF10B981,
                  ).withValues(alpha: p.isDark ? 0.45 : 0.4)
                : item.color.withValues(alpha: p.isDark ? 0.5 : 0.38),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: p.pick(item.color.withValues(alpha: 0.08), p.shadow),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.tint(item.color, item.color.withValues(alpha: 0.12)),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: p.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: isDone ? p.textMuted : p.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  if (countProgress != null) ...[
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: countProgress,
                        minHeight: 4,
                        backgroundColor: p.pick(
                          const Color(0xFFEFF1F5),
                          p.surface,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
                      ),
                    ),
                  ],
                  if (progressLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      progressLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: item.color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ItemTrailing(
              isDone: isDone,
              // Tick-offs get a checkbox; everything else opens a sheet or a
              // screen, so it gets an affordance that says "there's more".
              showChevron: !isTickable && !isDone,
              color: item.color,
            ),
          ],
        ),
      ),
    );
  }

  // ─── HER OWN ACTIVITIES ─────────────────────────────────────

  Future<void> _addActivity({int? hour}) async {
    final result = await _AddActivitySheet.show(
      context,
      hours: _dayHours,
      initialHour: hour ?? DateTime.now().hour,
      hourLabel: _hourLabel,
    );
    if (result == null) return;

    try {
      await CareCustomActivityStore.add(
        type: result.type,
        title: result.title,
        hour: result.hour,
        note: result.note,
      );
      HapticFeedback.mediumImpact();
      _showLogged('${result.title} added at ${_hourLabel(result.hour)}');
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Could not save activity: $e');
      _showError('Could not add the activity');
    }
    await _refresh();
  }

  Future<void> _confirmRemove(CareCustomActivity activity) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Remove "${activity.title}"?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'It will no longer appear at ${_hourLabel(activity.hour)} each day.',
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep',
              style: TextStyle(color: ctx.palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: dangerRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (remove != true) return;
    await CareCustomActivityStore.remove(activity.id);
    await _refresh();
  }
}

/// One hour on the timeline: the time, a dot on the rail, and what is on.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.child,
    this.isNow = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final Widget child;

  /// The hour the clock is in — the time and the dot turn pink.
  final bool isNow;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rail = p.pick(const Color(0xFFD5D9E0), p.border);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                  color: isNow ? primaryColor : p.textSecondary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 1.6,
                  height: 22,
                  color: isFirst ? Colors.transparent : rail,
                ),
                Container(
                  width: isNow ? 11 : 7,
                  height: isNow ? 11 : 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNow ? primaryColor : rail,
                    border: isNow
                        ? Border.all(
                            color: primaryColor.withValues(alpha: 0.25),
                            width: 3,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1.6,
                    color: isLast ? Colors.transparent : rail,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// An hour with nothing in it, open to add to.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: p.pick(
          const Color(0xFFF1F3F6),
          p.surface.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: p.pick(const Color(0xFFDDE1E7), p.border),
                width: 1.1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: p.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pink "Add activity" pill at the top of the full day.
class _AddActivityButton extends StatelessWidget {
  const _AddActivityButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primaryColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_rounded,
                size: 17,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'ADD ACTIVITY',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the add sheet hands back.
typedef _NewActivity = ({
  CareActivityType type,
  String title,
  String note,
  int hour,
});

/// Picks what to add, what to call it and when.
class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet({
    required this.hours,
    required this.initialHour,
    required this.hourLabel,
  });

  final List<int> hours;
  final int initialHour;
  final String Function(int) hourLabel;

  static Future<_NewActivity?> show(
    BuildContext context, {
    required List<int> hours,
    required int initialHour,
    required String Function(int) hourLabel,
  }) {
    return showModalBottomSheet<_NewActivity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddActivitySheet(
        hours: hours,
        initialHour: initialHour,
        hourLabel: hourLabel,
      ),
    );
  }

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  CareActivityType _type = CareActivityType.meal;
  late int _hour = widget.initialHour;
  final _title = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim().isEmpty ? _type.label : _title.text.trim();
    Navigator.pop<_NewActivity>(context, (
      type: _type,
      title: title,
      note: _note.text.trim(),
      hour: _hour,
    ));
  }

  InputDecoration _field(AppPalette p, String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: p.textMuted),
    filled: true,
    fillColor: p.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: primaryColor, width: 1.4),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add activity',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'It will show at this time every day.',
                style: GoogleFonts.poppins(fontSize: 12, color: p.textMuted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in CareActivityType.values)
                    ChoiceChip(
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                      avatar: Icon(
                        type.icon,
                        size: 16,
                        color: _type == type ? Colors.white : type.color,
                      ),
                      label: Text(type.label),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _type == type ? Colors.white : p.textPrimary,
                      ),
                      showCheckmark: false,
                      selectedColor: type.color,
                      backgroundColor: p.inputFill,
                      side: BorderSide(
                        color: _type == type ? type.color : p.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14, color: p.textPrimary),
                decoration: _field(p, 'Name, e.g. ${_type.label}'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14, color: p.textPrimary),
                decoration: _field(p, 'Note (optional)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _hour,
                dropdownColor: p.card,
                borderRadius: BorderRadius.circular(14),
                menuMaxHeight: 320,
                style: GoogleFonts.poppins(fontSize: 14, color: p.textPrimary),
                decoration: _field(p, 'Time').copyWith(
                  prefixIcon: const Icon(
                    Icons.schedule_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                items: [
                  for (final h in widget.hours)
                    DropdownMenuItem(
                      value: h,
                      child: Text(widget.hourLabel(h)),
                    ),
                ],
                onChanged: (h) {
                  if (h != null) setState(() => _hour = h);
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Add to my day',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One window of the day and what it asks for.
class _CareGroup {
  const _CareGroup({required this.part, required this.items});

  final CareDayPart part;
  final List<CareItem> items;
}

class _DayPartBadge extends StatelessWidget {
  const _DayPartBadge({required this.part});

  final CareDayPart part;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(part.icon, size: 14, color: primaryColor),
          const SizedBox(width: 5),
          Text(
            part.label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTrailing extends StatelessWidget {
  const _ItemTrailing({
    required this.isDone,
    required this.showChevron,
    required this.color,
  });

  final bool isDone;
  final bool showChevron;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (showChevron) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
        ),
        child: Icon(Icons.add_rounded, color: color, size: 18),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? const Color(0xFF10B981) : Colors.transparent,
        border: isDone
            ? null
            : Border.all(
                color: context.palette.pick(
                  const Color(0xFFD0D5DD),
                  context.palette.textMuted,
                ),
                width: 1.8,
              ),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}
