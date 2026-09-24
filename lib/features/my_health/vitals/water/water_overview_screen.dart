import 'package:flutter/material.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/widgets/nutrition/health_tile_parts.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_day_data.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

import 'water_entry_bottom_sheet.dart';

class WaterStats {
  final double todayTotal;
  final double dailyAverage;
  final int totalDaysTracked;

  WaterStats({
    required this.todayTotal,
    required this.dailyAverage,
    required this.totalDaysTracked,
  });
}

/// AlloConnect's water overview (Today / History) over Allomom's glass-based
/// `water` rows, shown in millilitres.
class WaterOverviewScreen extends StatefulWidget {
  /// Whose water to show; the signed-in user when omitted.
  final String? userId;

  const WaterOverviewScreen({super.key, this.userId});

  @override
  State<WaterOverviewScreen> createState() => _WaterOverviewScreenState();
}

class _WaterOverviewScreenState extends State<WaterOverviewScreen> {
  int _selectedTabIndex = 0; // 0: Today, 1: History
  final List<String> _tabs = ['Today', 'History'];

  bool _isLoading = true;
  List<VitalsStreamResponse> _todayWater = [];
  List<VitalsStreamResponse> _allWater = [];
  final Map<String, List<VitalsStreamResponse>> _groupedWater = {};
  final Set<String> _expandedDates = {};

  final Color _waterColor = Colors.cyan.shade600;

  String get _userId => widget.userId?.trim().isNotEmpty == true
      ? widget.userId!.trim()
      : MainController.instance.userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final today = dayBounds(DateTime.now());
      final waterRows = await VitalsSqLiteService().getVitalsHistory(
        _userId,
        'water',
      );

      final allWater = waterRows.map(vitalFromRow).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _todayWater = allWater
          .where(
            (v) =>
                !v.createdAt.isBefore(today.start) &&
                !v.createdAt.isAfter(today.end),
          )
          .toList();

      _allWater = allWater;

      _groupedWater.clear();
      for (final entry in _allWater) {
        final dateKey = DateFormat('yyyy-MM-dd').format(entry.createdAt);
        _groupedWater.putIfAbsent(dateKey, () => []).add(entry);
      }
    } catch (e) {
      debugPrint('Error loading water history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _sumMl(Iterable<VitalsStreamResponse> rows) {
    final total = rows.fold<double>(0.0, (sum, v) => sum + waterRowMl(v));
    return total < 0 ? 0 : total;
  }

  WaterStats _calculateStats() {
    final todayTotal = _sumMl(_todayWater);

    if (_allWater.isEmpty) {
      return WaterStats(
        todayTotal: todayTotal,
        dailyAverage: 0,
        totalDaysTracked: 0,
      );
    }

    final uniqueDays = _groupedWater.keys.length;
    final allTotal = _sumMl(_allWater);
    final dailyAvg = uniqueDays > 0 ? (allTotal / uniqueDays) : 0.0;

    return WaterStats(
      todayTotal: todayTotal,
      dailyAverage: dailyAvg,
      totalDaysTracked: uniqueDays,
    );
  }

  Future<void> _openCustomLogBottomSheet({VitalsStreamResponse? vital}) async {
    final wasAdded = await showWaterEntrySheet(
      context,
      vital: vital,
      userId: _userId,
    );
    if (wasAdded == true && mounted) _loadData();
  }

  Future<bool> _deleteWater(VitalsStreamResponse entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Water Log',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this water entry?',
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
                backgroundColor: _waterColor,
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
      await VitalsSqLiteService().deleteVital(entry.id);
      await HealthVitalsController.instance.fetchLatestVitals(
        showLoading: false,
      );
      if (mounted) _loadData();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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
          'Water Tracking',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomLogBottomSheet(),
        backgroundColor: _waterColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.water_drop_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: const Text(
          'Log Water',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VitalBabyBanner(
              narrationKey: NarrationKeys.pgNutritionWater,
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
    final double targetGoal = (waterGoalGlasses() * kGlassMl).toDouble();
    final stats = _calculateStats();
    final progress = (stats.todayTotal / targetGoal).clamp(0.0, 1.0);
    final percentInt = (progress * 100).toInt();

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Today Intake
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Intake",
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
                    Flexible(
                      child: Text(
                        '${stats.todayTotal.toInt()}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${targetGoal.toInt()} ml',
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
                  '$percentInt% of goal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _waterColor,
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
          // Daily Average
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Average',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${stats.dailyAverage.toInt()} ml',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _waterColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalDaysTracked} ${stats.totalDaysTracked == 1 ? 'day' : 'days'} tracked',
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
                        ? (isDarkMode ? Colors.white : _waterColor)
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

  Widget _buildTodayTab(bool isDarkMode, Color textColor) {
    if (_todayWater.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('today_empty'),
        isDarkMode: isDarkMode,
        textColor: textColor,
        title: 'No water tracked today yet',
        subtitle:
            'Stay hydrated! Tap Log Water to track your intake and reach your daily goal.',
      );
    }

    return ListView.builder(
      key: const ValueKey('today'),
      physics: const BouncingScrollPhysics(),
      itemCount: _todayWater.length,
      padding: const EdgeInsets.only(bottom: 96),
      itemBuilder: (context, index) {
        final entry = _todayWater[index];
        return _buildWaterEntryTile(
          entry,
          isDarkMode: isDarkMode,
          textColor: textColor,
        );
      },
    );
  }

  Widget _buildWaterEntryTile(
    VitalsStreamResponse entry, {
    required bool isDarkMode,
    required Color textColor,
  }) {
    final timeStr = DateFormat('hh:mm a').format(entry.createdAt);
    final ml = waterRowMl(entry).round();
    final isCorrection = ml < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        // Swipe left to delete; tap to edit.
        child: Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _deleteWater(entry),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: isDarkMode
                ? const Color(0xFF7F1D1D).withValues(alpha: 0.5)
                : Colors.red.shade50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_rounded,
                  color: isDarkMode
                      ? Colors.redAccent.shade100
                      : Colors.red.shade700,
                ),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.redAccent.shade100
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          child: Material(
            color: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
            child: InkWell(
              onTap: () => _openCustomLogBottomSheet(vital: entry),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _waterColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isCorrection
                            ? Icons.undo_rounded
                            : Icons.water_drop_rounded,
                        color: _waterColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrection ? 'Correction' : 'Water Intake',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
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
                    Text(
                      '$ml ml',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _waterColor,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(bool isDarkMode, Color textColor) {
    if (_groupedWater.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('history_empty'),
        isDarkMode: isDarkMode,
        textColor: textColor,
        title: 'No water history found',
        subtitle:
            'Track your daily water intake to build a comprehensive hydration record.',
      );
    }

    final dateKeys = _groupedWater.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      key: const ValueKey('history'),
      physics: const BouncingScrollPhysics(),
      itemCount: dateKeys.length,
      padding: const EdgeInsets.only(bottom: 96),
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final dayEntries = _groupedWater[dateKey]!;
        final dayTotal = _sumMl(dayEntries);

        final date = DateTime.parse(dateKey);
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final String displayDate;
        if (DateUtils.isSameDay(date, now)) {
          displayDate = 'Today';
        } else if (DateUtils.isSameDay(date, yesterday)) {
          displayDate = 'Yesterday';
        } else {
          displayDate = DateFormat('MMMM dd, yyyy').format(date);
        }

        final isExpanded = _expandedDates.contains(dateKey);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedDates.remove(dateKey);
                      } else {
                        _expandedDates.add(dateKey);
                      }
                    });
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _waterColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: _waterColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    displayDate,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    dayEntries.length == 1
                        ? '1 intake'
                        : '${dayEntries.length} intakes',
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${dayTotal.toInt()} ml',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _waterColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: textColor.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                // Expanded Details Section
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 4),
                        ...dayEntries.map((entry) {
                          return _buildWaterEntryTile(
                            entry,
                            isDarkMode: isDarkMode,
                            textColor: textColor,
                          );
                        }),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    Key? key,
    required bool isDarkMode,
    required Color textColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      key: key,
      child: SingleChildScrollView(
        // Bottom inset keeps the text clear of the FAB.
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _waterColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop_rounded,
                size: 48,
                color: _waterColor,
              ),
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
