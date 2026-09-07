import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_count_sheet.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// Today's care, scoped to the current part of the day.
///
/// The list is rebuilt from [careItemsFor] whenever the clock crosses into a
/// new [CareDayPart], so before 11 AM it asks about breakfast, the afternoon
/// asks about lunch and the evening about dinner. Completion is read back from
/// the vitals the rest of the app already writes (`breakfast`, `lunch`,
/// `dinner`, `snacks`, `water`, `drinks`) plus the `todocare` tick-offs, so
/// logging a meal in My Health also ticks it off here.
class TodocareSection extends StatefulWidget {
  const TodocareSection({super.key});

  @override
  State<TodocareSection> createState() => _TodocareSectionState();
}

class _TodocareSectionState extends State<TodocareSection> {
  /// How often we re-check whether the day part changed under us.
  static const _slotWatchInterval = Duration(minutes: 1);

  CareDayPart _part = CareDayPart.at();
  List<CareItem> _items = const [];
  bool _isLoading = true;

  /// `todocare` action values already ticked off today.
  Set<String> _completedActions = <String>{};

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

  String _storageKey() {
    final now = DateTime.now();
    final date =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'todocare_${UserSessionManager.instance.userId}_$date';
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
    final session = UserSessionManager.instance;
    final part = CareDayPart.at();
    final items = careItemsFor(
      part: part,
      isPregnant: session.isPregnant,
      pregnancyDay: session.currentPregnancyDay,
    );

    final completed = await _loadCompletedActions();
    final counts = await _loadCountsToday(items);
    final meals = await _loadMealsLoggedToday(items);
    final navigated = await _loadNavigateDone(items);

    if (!mounted) return;
    setState(() {
      _part = part;
      _items = items;
      _completedActions = completed;
      _countsToday = counts;
      _mealsLogged = meals;
      _navigateDone = navigated;
      _isLoading = false;
    });
  }

  /// Tick-offs come from SharedPreferences (fast) plus today's `todocare`
  /// vitals (durable), because the two can drift if a write failed.
  Future<Set<String>> _loadCompletedActions() async {
    final completed = <String>{};

    try {
      final prefs = await SharedPreferences.getInstance();
      completed.addAll(prefs.getStringList(_storageKey()) ?? const <String>[]);
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Could not read cached tick-offs: $e');
    }

    final userId = UserSessionManager.instance.userId;
    if (userId.isEmpty) return completed;

    try {
      final rows = await VitalsSqLiteService().getVitalsHistory(
        userId,
        'todocare',
        fromDate: _startOfToday(),
      );

      for (final row in rows) {
        final unit = row['unit']?.toString().toLowerCase().trim();
        if (unit != null && unit.isNotEmpty) completed.add(unit);

        for (final value in _decodeData(row).values) {
          final text = value?.toString().toLowerCase().trim();
          if (text != null && text.isNotEmpty) completed.add(text);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Could not read todocare vitals: $e');
    }

    return completed;
  }

  /// Sums today's rows for each count item. Rows hold increments, so a sum is
  /// the running total for the day.
  ///
  /// Calorie-backed keys (`snacks`, `drinks`) store kcal in the value, so the
  /// count is read from `data['count']`. Rows written elsewhere in the app
  /// (My Health's snack dialog) carry no count, so they count as one unit.
  Future<Map<String, int>> _loadCountsToday(List<CareItem> items) async {
    final counts = <String, int>{};
    final userId = UserSessionManager.instance.userId;
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

        var total = 0;
        for (final row in rows) {
          if (item.caloriesPerUnit == null) {
            total += ((row['value'] as num?)?.toDouble() ?? 0).round();
          } else {
            final recorded = _decodeData(row)['count'];
            final parsed = recorded is num
                ? recorded.round()
                : int.tryParse(recorded?.toString() ?? '');
            total += parsed ?? 1;
          }
        }
        counts[key] = total < 0 ? 0 : total;
      } catch (e) {
        debugPrint('⚠️ [TodocareSection] Could not read "$key" vitals: $e');
      }
    }

    return counts;
  }

  Future<Set<String>> _loadMealsLoggedToday(List<CareItem> items) async {
    final logged = <String>{};
    final userId = UserSessionManager.instance.userId;
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
    final userId = UserSessionManager.instance.userId;
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
    CareActionKind.navigate => _navigateDone.contains(item.doneVitalKey),
  };

  int _countFor(CareItem item) => _countsToday[item.countVitalKey] ?? 0;

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
          'day_part': _part.name,
        },
      );
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
          'day_part': _part.name,
        },
      );
      _showLogged('Logged $amount $unit');
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Error logging ${item.countVitalKey}: $e');
      _showError('Could not log ${item.title.toLowerCase()}');
    }

    await _refresh();
  }

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

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey();
      final stored = (prefs.getStringList(key) ?? const <String>[]).toSet();
      if (wasDone) {
        stored.remove(action);
      } else {
        stored.add(action);
      }
      await prefs.setStringList(key, stored.toList());
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Could not cache tick-off: $e');
    }

    // Only completions are written to the vitals stream; un-ticking just
    // clears the cache, matching how the rest of the app treats these.
    if (wasDone) return;

    final session = UserSessionManager.instance;
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
          'day_part': _part.name,
          'pregnancy_day': session.isPregnant ? session.currentPregnancyDay : 0,
          'is_pregnant': session.isPregnant,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('⚠️ [TodocareSection] Error logging todocare: $e');
    }
  }

  Future<void> _navigate(CareItem item) async {
    switch (item.destination) {
      case CareDestination.kickCounter:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KickCounterPage()),
        );
      case null:
        return;
    }
    if (mounted) await _refresh();
  }

  String? _userIdOrNull() {
    final id = UserSessionManager.instance.userId.trim();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final progress = _items.isEmpty ? 0.0 : _doneCount / _items.length;
    final name = UserSessionManager.instance.userName.split(' ').first;

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
                      "Today's care",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_part.greeting}, $name · ${_part.headline}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
                    backgroundColor: const Color(0xFFF0F2F5),
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
          const SizedBox(height: 16),
          ..._items.map(_buildCareItem),
        ],
      ),
    );
  }

  Widget _buildCareItem(CareItem item) {
    final isDone = _isDone(item);
    final progressLabel = _progressLabel(item);
    final isTickable = item.kind == CareActionKind.checkoff;

    return GestureDetector(
      onTap: () => _onItemTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? const Color(0xFFE2F5EA) : const Color(0xFFF0F2F5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E2024),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF9EA5B4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDone
                          ? const Color(0xFF9EA5B4)
                          : const Color(0xFF5E6573),
                      height: 1.3,
                    ),
                  ),
                  if (progressLabel != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        progressLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
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
            : Border.all(color: const Color(0xFFD0D5DD), width: 1.8),
      ),
      child: isDone
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : null,
    );
  }
}
