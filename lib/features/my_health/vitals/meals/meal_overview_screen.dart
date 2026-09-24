// Ported from AlloConnect lib/features/health_section/vitals/{breakfast,lunch,dinner}/
// *_overview_screen.dart (one parameterised screen for the three meals).
import 'package:flutter/material.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:intl/intl.dart';

import 'package:allomom/models/vitals_stream_model.dart';

import 'meal_entry_bottom_sheet.dart';
import 'meal_kind.dart';
import 'meal_swipe_actions.dart';
import 'meal_vitals_store.dart';

class MealTimeStats {
  final String avgTimeStr;
  final String timeRangeStr;
  final double avgCalories;
  final int totalDaysTracked;

  MealTimeStats({
    required this.avgTimeStr,
    required this.timeRangeStr,
    required this.avgCalories,
    required this.totalDaysTracked,
  });

  /// Average eating time and range over [meals], preferring `data['time']`
  /// (HH:mm) over the row's timestamp, as AlloConnect does.
  factory MealTimeStats.of(List<VitalsStreamResponse> meals) {
    if (meals.isEmpty) {
      return MealTimeStats(
        avgTimeStr: '--',
        timeRangeStr: 'No history yet',
        avgCalories: 0,
        totalDaysTracked: 0,
      );
    }

    int totalMinutes = 0;
    double totalCalories = 0;
    int minMinutes = 24 * 60;
    int maxMinutes = 0;
    final Set<String> uniqueDays = {};

    for (final meal in meals) {
      uniqueDays.add(DateFormat('yyyy-MM-dd').format(meal.createdAt));
      totalCalories += meal.value;

      int mealMinutes = meal.createdAt.hour * 60 + meal.createdAt.minute;
      final timeStr = meal.data?['time']?.toString();
      if (timeStr != null) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) mealMinutes = h * 60 + m;
        }
      }

      totalMinutes += mealMinutes;
      if (mealMinutes < minMinutes) minMinutes = mealMinutes;
      if (mealMinutes > maxMinutes) maxMinutes = mealMinutes;
    }

    final avgMinutes = (totalMinutes / meals.length).round();
    final avgTime = DateTime(2026, 1, 1, avgMinutes ~/ 60, avgMinutes % 60);
    final avgTimeFormatted = DateFormat('hh:mm a').format(avgTime);

    String rangeFormatted;
    if (meals.length == 1) {
      rangeFormatted = 'Logged around $avgTimeFormatted';
    } else if (minMinutes == maxMinutes) {
      rangeFormatted = avgTimeFormatted;
    } else {
      final minTime = DateTime(2026, 1, 1, minMinutes ~/ 60, minMinutes % 60);
      final maxTime = DateTime(2026, 1, 1, maxMinutes ~/ 60, maxMinutes % 60);
      rangeFormatted =
          '${DateFormat('hh:mm a').format(minTime)} - ${DateFormat('hh:mm a').format(maxTime)}';
    }

    return MealTimeStats(
      avgTimeStr: avgTimeFormatted,
      timeRangeStr: rangeFormatted,
      avgCalories: totalCalories / meals.length,
      totalDaysTracked: uniqueDays.length,
    );
  }
}

/// Breakfast / Lunch / Dinner overview: today's stats, average eating time,
/// and Today / History lists with swipe-to-edit/delete.
class MealOverviewScreen extends StatefulWidget {
  final MealKind meal;

  /// Defaults to the signed-in user.
  final String? userId;

  const MealOverviewScreen({super.key, required this.meal, this.userId});

  @override
  State<MealOverviewScreen> createState() => _MealOverviewScreenState();
}

class _MealOverviewScreenState extends State<MealOverviewScreen> {
  int _selectedTabIndex = 0; // 0: Today, 1: History
  final List<String> _tabs = ['Today', 'History'];

  bool _isLoading = true;
  List<VitalsStreamResponse> _todayMeals = [];
  List<VitalsStreamResponse> _allMeals = [];

  MealKind get _meal => widget.meal;
  Color get _mealColor => _meal.overviewColor;
  String get _userId => MealVitalsStore.resolveUserId(widget.userId);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final all = await MealVitalsStore.loadHistory(
        _userId,
        keys: _meal.readKeys,
        foodType: _meal.vitalKey,
      );

      _todayMeals = all
          .where(
            (v) =>
                v.createdAt.isAfter(startOfToday) &&
                v.createdAt.isBefore(endOfToday),
          )
          .toList();
      _allMeals = all;
    } catch (e) {
      debugPrint('Error loading ${_meal.lower} history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEntrySheet([VitalsStreamResponse? vital]) async {
    final changed = await showMealEntrySheet(
      context,
      meal: _meal,
      vital: vital,
      userId: _userId,
    );
    if (changed == true && mounted) _loadData();
  }

  Future<void> _deleteMeal(VitalsStreamResponse meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete ${_meal.label}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this ${_meal.lower} log?',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mealColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await MealVitalsStore.deleteVital(meal.id);
      if (mounted) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF0A111F)
        : const Color(0xFFF8FAFF);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          '${_meal.label} Overview',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      // The one add control, as on Snacks: it stays after the first log, so a
      // second meal can be added.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEntrySheet(),
        backgroundColor: _mealColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VitalBabyBanner(
              narrationKey: NarrationKeys.pgNutritionMeal,
              margin: EdgeInsets.fromLTRB(20, 10, 20, 6),
              // Fixed above the list here, so kept short.
              height: 170,
            ),
            // Stats Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildStatsPanel(isDarkMode, textColor),
            ),

            // Tab bar toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildTabToggle(isDarkMode, textColor),
            ),
            const SizedBox(height: 8),

            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedTabIndex == 0
                            ? _buildTodayTab(isDarkMode, textColor)
                            : _buildHistoryTab(isDarkMode, textColor),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel(bool isDarkMode, Color textColor) {
    final todayCalories = _todayMeals.fold<double>(
      0.0,
      (sum, item) => sum + item.value,
    );
    final stats = MealTimeStats.of(_allMeals);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's ${_meal.label}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _todayMeals.isNotEmpty
                              ? '${todayCalories.toInt()}'
                              : '0',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _todayMeals.isNotEmpty
                          ? 'Tracked today'
                          : 'Not tracked yet',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _todayMeals.isNotEmpty
                            ? _mealColor
                            : textColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                width: 1,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days Tracked',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stats.totalDaysTracked == 1
                          ? '1 day'
                          : '${stats.totalDaysTracked} days',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _mealColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_allMeals.length} total logs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average Time Range Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _mealColor.withValues(alpha: isDarkMode ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _mealColor.withValues(alpha: isDarkMode ? 0.2 : 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _mealColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: _mealColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avg Eating Time & Range',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textColor.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            stats.avgTimeStr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          if (stats.avgTimeStr != '--') ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '(${stats.timeRangeStr})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _mealColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle(bool isDarkMode, Color textColor) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDarkMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: isSelected
                        ? (isDarkMode ? Colors.white : _mealColor)
                        : textColor.withValues(alpha: 0.5),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMealTile(
    VitalsStreamResponse meal, {
    required bool isDarkMode,
    required Color textColor,
    bool showDate = true,
  }) {
    final timeStr = DateFormat('hh:mm a').format(meal.createdAt);
    final date = meal.createdAt;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;
    final isYesterday = yesterday.year == date.year &&
        yesterday.month == date.month &&
        yesterday.day == date.day;

    final String displayDate;
    if (isToday) {
      displayDate = 'Today';
    } else if (isYesterday) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat('MMMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MealSwipeActions(
          key: ValueKey(meal.id),
          extentRatio: 0.44,
          actions: [
            MealSwipeAction(
              onPressed: () => _openEntrySheet(meal),
              backgroundColor: isDarkMode
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                  : Colors.blue.shade50,
              foregroundColor: isDarkMode
                  ? Colors.lightBlueAccent
                  : Colors.blue.shade700,
              icon: Icons.edit_rounded,
              label: 'Edit',
            ),
            MealSwipeAction(
              onPressed: () => _deleteMeal(meal),
              backgroundColor: isDarkMode
                  ? const Color(0xFF7F1D1D).withValues(alpha: 0.5)
                  : Colors.red.shade50,
              foregroundColor: isDarkMode
                  ? Colors.redAccent.shade100
                  : Colors.red.shade700,
              icon: Icons.delete_rounded,
              label: 'Delete',
            ),
          ],
          child: Material(
            color: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
            child: InkWell(
              onTap: () => _openEntrySheet(meal),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with Date / Status and Calories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showDate)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: _mealColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                displayDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: _mealColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tracked',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _mealColor,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${meal.value.toInt()}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Details and time row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _mealColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _meal.overviewIcon,
                            color: _mealColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mealDetailsOf(meal) ?? _meal.defaultTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: textColor.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: textColor.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTab(bool isDarkMode, Color textColor) {
    if (_todayMeals.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('today-empty'),
        textColor: textColor,
        title: 'No ${_meal.lower} tracked today yet',
        subtitle: _meal.emptyTodaySubtitle,
      );
    }

    return ListView.builder(
      key: const ValueKey('today'),
      physics: const BouncingScrollPhysics(),
      itemCount: _todayMeals.length,
      padding: const EdgeInsets.only(bottom: 96),
      itemBuilder: (context, index) => _buildMealTile(
        _todayMeals[index],
        isDarkMode: isDarkMode,
        textColor: textColor,
        showDate: false,
      ),
    );
  }

  Widget _buildHistoryTab(bool isDarkMode, Color textColor) {
    if (_allMeals.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('history-empty'),
        textColor: textColor,
        title: 'No ${_meal.lower} history found',
        subtitle:
            'Tap + to track your ${_meal.lower} and build your nutrition record.',
      );
    }

    return ListView.builder(
      key: const ValueKey('history'),
      physics: const BouncingScrollPhysics(),
      itemCount: _allMeals.length,
      padding: const EdgeInsets.only(bottom: 96),
      itemBuilder: (context, index) => _buildMealTile(
        _allMeals[index],
        isDarkMode: isDarkMode,
        textColor: textColor,
        showDate: true,
      ),
    );
  }

  Widget _buildEmptyState({
    Key? key,
    required Color textColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        // Clear of the add button.
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _mealColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_meal.overviewIcon, size: 48, color: _mealColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
