// Ported from AlloConnect lib/features/health_section/vitals/snacks/snacks_overview_screen.dart.
import 'package:flutter/material.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:intl/intl.dart';

import 'package:allomom/models/vitals_stream_model.dart';

import 'meal_entry_bottom_sheet.dart' show mealDetailsOf;
import 'meal_overview_screen.dart' show MealTimeStats;
import 'meal_vitals_store.dart';
import 'snacks_entry_bottom_sheet.dart';

class SnacksOverviewScreen extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;

  const SnacksOverviewScreen({super.key, this.userId});

  @override
  State<SnacksOverviewScreen> createState() => _SnacksOverviewScreenState();
}

class _SnacksOverviewScreenState extends State<SnacksOverviewScreen> {
  int _selectedTabIndex = 0; // 0: Today, 1: History
  final List<String> _tabs = ['Today', 'History'];

  bool _isLoading = true;
  List<VitalsStreamResponse> _todaySnacks = [];
  List<VitalsStreamResponse> _allSnacks = [];
  final Map<String, List<VitalsStreamResponse>> _groupedSnacks = {};
  final Set<String> _expandedDates = {};

  final Color _snacksColor = Colors.pink.shade400;

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

      final allSnacks = await MealVitalsStore.loadHistory(
        _userId,
        keys: const ['snacks'],
        foodType: 'snacks',
      );

      // Separate today's snacks
      _todaySnacks = allSnacks
          .where(
            (v) =>
                v.createdAt.isAfter(startOfToday) &&
                v.createdAt.isBefore(endOfToday),
          )
          .toList();
      _allSnacks = allSnacks;

      // Group history by date
      _groupedSnacks.clear();
      for (final snack in _allSnacks) {
        final dateKey = DateFormat('yyyy-MM-dd').format(snack.createdAt);
        _groupedSnacks.putIfAbsent(dateKey, () => []).add(snack);
      }
    } catch (e) {
      debugPrint('Error loading snacks history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEntrySheet([VitalsStreamResponse? vital]) async {
    final changed = await showSnacksEntrySheet(
      context,
      vital: vital,
      userId: _userId,
    );
    if (changed == true && mounted) _loadData();
  }

  Future<void> _deleteSnack(VitalsStreamResponse snack) async {
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
            'Delete Snack',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this snack log?',
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
                backgroundColor: Colors.pink.shade400,
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
      await MealVitalsStore.deleteVital(snack.id);
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
    final snacksColor = _snacksColor;

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
          'Snacks Overview',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEntrySheet(),
        backgroundColor: snacksColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VitalBabyBanner(
              narrationKey: NarrationKeys.pgNutritionSnacks,
              margin: EdgeInsets.fromLTRB(20, 10, 20, 6),
              // Fixed above the list here, so kept short.
              height: 170,
            ),
            // Stats Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildStatsPanel(isDarkMode, snacksColor, textColor),
            ),

            // Tab bar toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildTabToggle(isDarkMode, textColor, snacksColor),
            ),
            const SizedBox(height: 12),

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

  Widget _buildStatsPanel(bool isDarkMode, Color snacksColor, Color textColor) {
    final todayCalories = _todaySnacks.fold<double>(
      0.0,
      (sum, item) => sum + item.value,
    );
    final stats = MealTimeStats.of(_allSnacks);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Snacks",
                    style: TextStyle(
                      fontSize: 14,
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
                        '${todayCalories.toInt()}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Snacks Tracked',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _todaySnacks.length == 1
                        ? '1 snack'
                        : '${_todaySnacks.length} snacks',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: snacksColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average Time Range Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: snacksColor.withValues(alpha: isDarkMode ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: snacksColor.withValues(alpha: isDarkMode ? 0.2 : 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: snacksColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: snacksColor,
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
                                  color: snacksColor,
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

  Widget _buildTabToggle(bool isDarkMode, Color textColor, Color snacksColor) {
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
                        ? (isDarkMode ? Colors.white : snacksColor)
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
    if (_todaySnacks.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('today-empty'),
        textColor: textColor,
        title: 'No snacks tracked today yet',
        subtitle:
            'Tap + to log a snack and stay mindful of your nutrition.',
      );
    }

    return ListView.builder(
      key: const ValueKey('today'),
      physics: const BouncingScrollPhysics(),
      itemCount: _todaySnacks.length,
      padding: const EdgeInsets.only(bottom: 96),
      itemBuilder: (context, index) {
        final snack = _todaySnacks[index];
        final timeStr = DateFormat('hh:mm a').format(snack.createdAt);

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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _snacksColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.cookie_rounded,
                    color: _snacksColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealDetailsOf(snack) ?? 'Mindful Snack',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${snack.value.toInt()} kcal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: _snacksColor,
                            size: 18,
                          ),
                          onPressed: () => _openEntrySheet(snack),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          onPressed: () => _deleteSnack(snack),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(bool isDarkMode, Color textColor) {
    if (_groupedSnacks.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('history-empty'),
        textColor: textColor,
        title: 'No snack history found',
        subtitle:
            'Track your snacks daily to build a comprehensive nutrition log.',
      );
    }

    final dateKeys = _groupedSnacks.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      key: const ValueKey('history'),
      physics: const BouncingScrollPhysics(),
      itemCount: dateKeys.length,
      padding: const EdgeInsets.only(bottom: 96),
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final daySnacks = _groupedSnacks[dateKey]!;
        final totalCalories = daySnacks.fold<double>(
          0.0,
          (sum, item) => sum + item.value,
        );

        final date = DateTime.parse(dateKey);
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final isToday = now.year == date.year &&
            now.month == date.month &&
            now.day == date.day;
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
                      color: _snacksColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: _snacksColor,
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
                    daySnacks.length == 1
                        ? '1 snack'
                        : '${daySnacks.length} snacks',
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
                            '${totalCalories.toInt()} kcal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textColor,
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
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        ...daySnacks.map((snack) {
                          final timeStr = DateFormat(
                            'hh:mm a',
                          ).format(snack.createdAt);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cookie_outlined,
                                  size: 16,
                                  color: _snacksColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mealDetailsOf(snack) ??
                                            'Mindful Snack',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textColor.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${snack.value.toInt()} kcal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: _snacksColor,
                                  ),
                                  onPressed: () => _openEntrySheet(snack),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Edit',
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _deleteSnack(snack),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
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
                color: _snacksColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cookie_outlined,
                size: 48,
                color: _snacksColor,
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
