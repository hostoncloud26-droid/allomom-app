import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/vitals/drinks/drinks_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/nutrition_routes.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_detail_page.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

import 'nutrition/drinks_tile.dart';
import 'nutrition/health_tile_parts.dart';
import 'nutrition/meal_tiles.dart';
import 'nutrition/water_tile.dart';

/// Daily water goal, in glasses.
const int _waterTargetGlasses = 10;

/// The day's nutrition as AlloConnect lays it out — water, drinks, snacks,
/// then breakfast, lunch and dinner, each its own tile.
///
/// Shows [date] (today when null). A past day is a record: its tiles are
/// read-only, and logging always writes to today.
class NutritionTiles extends StatefulWidget {
  final String? userId;

  /// Day whose meals are shown. Defaults to today when omitted.
  final DateTime? date;

  const NutritionTiles({super.key, this.userId, this.date});

  @override
  State<NutritionTiles> createState() => _NutritionTilesState();
}

class _NutritionTilesState extends State<NutritionTiles> {
  List<VitalsStreamResponse> _breakfast = const [];
  List<VitalsStreamResponse> _lunch = const [];
  List<VitalsStreamResponse> _dinner = const [];
  List<VitalsStreamResponse> _snacks = const [];
  List<VitalsStreamResponse> _drinks = const [];
  int _waterGlasses = 0;

  int _loadSeq = 0;

  DateTime get _selectedDate => widget.date ?? DateTime.now();
  bool get _readOnly => !DateUtils.isSameDay(_selectedDate, DateTime.now());
  String get _userId => widget.userId ?? MainController.instance.userId;

  @override
  void initState() {
    super.initState();
    _load();
    HealthVitalsController.instance.addListener(_load);
  }

  @override
  void didUpdateWidget(covariant NutritionTiles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        !DateUtils.isSameDay(oldWidget.date ?? DateTime.now(), _selectedDate)) {
      _load();
    }
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final seq = ++_loadSeq;
    try {
      final bounds = dayBounds(_selectedDate);
      final service = VitalsSqLiteService();
      Future<List<VitalsStreamResponse>> rows(String key) async {
        final r = await service.getVitalsHistory(
          _userId,
          key,
          fromDate: bounds.start,
          toDate: bounds.end,
        );
        return r.map(vitalFromRow).toList();
      }

      final results = await Future.wait([
        rows('breakfast'),
        rows('break_fast'),
        rows('lunch'),
        rows('dinner'),
        rows('snacks'),
        rows('drinks'),
        rows('water'),
      ]);
      if (!mounted || seq != _loadSeq) return;

      int newestFirst(VitalsStreamResponse a, VitalsStreamResponse b) =>
          b.createdAt.compareTo(a.createdAt);

      final water = results[6].fold<double>(0, (s, v) => s + v.value).round();
      setState(() {
        _breakfast = [...results[0], ...results[1]]..sort(newestFirst);
        _lunch = results[2]..sort(newestFirst);
        _dinner = results[3]..sort(newestFirst);
        _snacks = results[4]..sort(newestFirst);
        _drinks = results[5]..sort(newestFirst);
        _waterGlasses = water < 0 ? 0 : water;
      });
    } catch (e) {
      debugPrint('NutritionTiles: failed to load day: $e');
    }
  }

  /// Opens a tile's own detail page — its trend, its numbers, its entries.
  Future<void> _openDetail(NutritionMetric metric) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => nutritionOverviewScreen(metric, userId: _userId),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _logMeal(NutritionMetric metric) async {
    if (_readOnly) return;
    final saved = await showNutritionEntrySheet(
      context,
      metric,
      userId: _userId,
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _addWater(int glasses) async {
    if (_readOnly || glasses <= 0) return;
    setState(() => _waterGlasses += glasses);
    await HealthVitalsController.instance.addVitalEntry(
      key: 'water',
      value: glasses.toDouble(),
      unit: 'glasses',
      createdAt: DateTime.now(),
      userId: _userId,
      data: {
        'details': '$glasses ${glasses == 1 ? 'glass' : 'glasses'}',
        'type': 'water',
      },
    );
  }

  Future<void> _removeWater() async {
    if (_readOnly || _waterGlasses <= 0) return;
    setState(() => _waterGlasses -= 1);
    // Rows hold increments (the reader sums them), so a correction is logged
    // as -1, not as the new total.
    await HealthVitalsController.instance.addVitalEntry(
      key: 'water',
      value: -1,
      unit: 'glasses',
      createdAt: DateTime.now(),
      userId: _userId,
      data: const {'details': 'Corrected by 1 glass', 'type': 'water'},
    );
  }

  Future<void> _logDrink(String name, IconData icon) async {
    if (_readOnly) return;
    final saved = await showDrinksEntrySheet(
      context,
      userId: _userId,
      initialType: name,
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final breakfastColor = Colors.orange.shade400;
    final lunchColor = Colors.green.shade400;
    final dinnerColor = Colors.indigo.shade400;
    const gap = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Nutrition',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        WaterTile(
          glasses: _waterGlasses,
          targetGlasses: _waterTargetGlasses,
          readOnly: _readOnly,
          onOpen: () => _openDetail(NutritionMetric.water),
          onAdd: _addWater,
          onRemove: _removeWater,
        ),
        gap,
        DrinksTile(
          entries: _drinks,
          readOnly: _readOnly,
          onOpen: () => _openDetail(NutritionMetric.drinks),
          onLog: _logDrink,
        ),
        gap,
        SnacksTile(
          entries: _snacks,
          readOnly: _readOnly,
          onOpen: () => _openDetail(NutritionMetric.snacks),
          onLog: () => _logMeal(NutritionMetric.snacks),
        ),
        gap,
        MealTile(
          label: 'Breakfast',
          color: breakfastColor,
          entries: _breakfast,
          emptyHint: 'Start your day by tracking your breakfast.',
          fallbackDetails: 'Healthy Breakfast',
          readOnly: _readOnly,
          onOpen: () => _openDetail(NutritionMetric.breakfast),
          onLog: () => _logMeal(NutritionMetric.breakfast),
        ),
        gap,
        MealTile(
          label: 'Lunch',
          color: lunchColor,
          entries: _lunch,
          emptyHint: 'Keep your energy up by tracking your lunch.',
          fallbackDetails: 'Healthy Lunch',
          readOnly: _readOnly,
          onOpen: () => _openDetail(NutritionMetric.lunch),
          onLog: () => _logMeal(NutritionMetric.lunch),
        ),
        gap,
        MealTile(
          label: 'Dinner',
          color: dinnerColor,
          entries: _dinner,
          emptyHint: 'Wrap up your day by tracking your dinner.',
          fallbackDetails: 'Healthy Dinner',
          readOnly: _readOnly,
          onOpen: () => _openDetail(NutritionMetric.dinner),
          onLog: () => _logMeal(NutritionMetric.dinner),
        ),
      ],
    );
  }
}
