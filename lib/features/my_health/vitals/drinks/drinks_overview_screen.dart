import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/widgets/nutrition/health_tile_parts.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

import 'drinks_entry_bottom_sheet.dart';

/// AlloConnect's drinks overview (Today / History) over Allomom's `drinks`
/// rows (kcal in the value, cups in `data['count']`).
class DrinksOverviewScreen extends StatefulWidget {
  /// Whose drinks to show; the signed-in user when omitted.
  final String? userId;

  const DrinksOverviewScreen({super.key, this.userId});

  @override
  State<DrinksOverviewScreen> createState() => _DrinksOverviewScreenState();
}

class _DrinksOverviewScreenState extends State<DrinksOverviewScreen> {
  int _selectedTabIndex = 0; // 0: Today, 1: History
  final List<String> _tabs = ['Today', 'History'];

  bool _isLoading = true;
  List<VitalsStreamResponse> _todayDrinks = [];
  List<VitalsStreamResponse> _allDrinks = [];
  final Map<String, List<VitalsStreamResponse>> _groupedDrinks = {};
  final Set<String> _expandedDates = {};

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
      final rows = await VitalsSqLiteService().getVitalsHistory(
        _userId,
        'drinks',
      );

      final allDrinks = rows.map(vitalFromRow).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Separate today's drinks
      _todayDrinks = allDrinks
          .where(
            (v) =>
                !v.createdAt.isBefore(today.start) &&
                !v.createdAt.isAfter(today.end),
          )
          .toList();

      _allDrinks = allDrinks;

      // Group history by date
      _groupedDrinks.clear();
      for (final drink in _allDrinks) {
        final dateKey = DateFormat('yyyy-MM-dd').format(drink.createdAt);
        _groupedDrinks.putIfAbsent(dateKey, () => []).add(drink);
      }
    } catch (e) {
      debugPrint('Error loading drinks history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Cups a row stands for; rows without a count are one cup.
  int _cupsOf(VitalsStreamResponse v) {
    final c = v.data?['count'];
    if (c is num && c > 0) return c.round();
    return int.tryParse(c?.toString() ?? '') ?? 1;
  }

  int _sumCups(Iterable<VitalsStreamResponse> rows) =>
      rows.fold<int>(0, (sum, v) => sum + _cupsOf(v));

  Future<void> _openAddDrinkBottomSheet() async {
    final wasAdded = await showDrinksEntrySheet(context, userId: _userId);
    if (wasAdded == true && mounted) _loadData();
  }

  Future<void> _openEditDrinkBottomSheet(VitalsStreamResponse vital) async {
    final wasUpdated = await showDrinksEntrySheet(
      context,
      vital: vital,
      userId: _userId,
    );
    if (wasUpdated == true && mounted) _loadData();
  }

  Future<void> _deleteDrink(VitalsStreamResponse drink) async {
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
            'Delete Drink Log',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this drink log?',
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
                backgroundColor: Colors.amber.shade800,
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
      await VitalsSqLiteService().deleteVital(drink.id);
      await HealthVitalsController.instance.fetchLatestVitals(
        showLoading: false,
      );
      if (mounted) _loadData();
    }
  }

  String _typeLabel(String type, Map<String, dynamic>? data) {
    switch (type) {
      case 'tea':
        return 'Tea';
      case 'coffee':
        return 'Coffee';
      default:
        final temp = data?['temperature']?.toString();
        if (temp == 'hot') return 'Hot Drink';
        if (temp == 'cold') return 'Cold Drink';
        return 'Other Drink';
    }
  }

  IconData _getIconForType(String? type) {
    if (type == 'coffee') {
      return Icons.coffee_rounded;
    } else if (type == 'beverages') {
      return Icons.local_bar_rounded;
    } else {
      return Icons.emoji_food_beverage_rounded;
    }
  }

  Color _getColorForType(String? type) {
    if (type == 'coffee') {
      return Colors.amber.shade900;
    } else if (type == 'beverages') {
      return Colors.indigo.shade600;
    } else {
      return Colors.teal.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF0A111F)
        : const Color(0xFFF8FAFF);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);
    final drinksColor = Colors.amber.shade800;

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
          'Drinks Overview',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDrinkBottomSheet,
        backgroundColor: drinksColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const VitalBabyBanner(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              // Fixed above the list here, so kept short.
              height: 170,
            ),
            // Upper Statistics Panel
            _buildStatsHeader(isDarkMode, textColor, drinksColor),

            const SizedBox(height: 16),

            // Tab Selector
            _buildTabSelector(isDarkMode, textColor, drinksColor),

            const SizedBox(height: 16),

            // Tab View Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTabIndex == 0
                  ? _buildTodayTab(isDarkMode, textColor, drinksColor)
                  : _buildHistoryTab(isDarkMode, textColor, drinksColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(bool isDark, Color textColor, Color drinksColor) {
    final todayCalories = _todayDrinks.fold<double>(
      0.0,
      (sum, item) => sum + item.value,
    );
    final todayCups = _sumCups(_todayDrinks);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E2433), const Color(0xFF161B26)]
              : [Colors.white, Colors.white.withValues(alpha: 0.95)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: '${todayCalories.toInt()}',
            unit: 'kcal',
            label: 'Total Calories',
            isDark: isDark,
            textColor: textColor,
          ),
          Container(
            width: 1,
            height: 48,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
          _buildStatItem(
            value: '$todayCups',
            unit: todayCups == 1 ? 'cup' : 'cups',
            label: 'Sips Had Today',
            isDark: isDark,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String unit,
    required String label,
    required bool isDark,
    required Color textColor,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(bool isDark, Color textColor, Color drinksColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade200,
        ),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF1E2433) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                margin: const EdgeInsets.all(2),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? drinksColor
                        : textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTodayTab(bool isDark, Color textColor, Color drinksColor) {
    if (_todayDrinks.isEmpty) {
      return _buildEmptyState(
        isDark,
        textColor,
        'No drinks tracked today',
        'Tap + to log coffee, tea or other beverages and see your overview.',
        drinksColor,
      );
    }

    return ListView.builder(
      itemCount: _todayDrinks.length,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemBuilder: (context, index) {
        final drink = _todayDrinks[index];
        return _buildDrinkItemCard(drink, isDark, textColor);
      },
    );
  }

  Widget _buildHistoryTab(bool isDark, Color textColor, Color drinksColor) {
    if (_groupedDrinks.isEmpty) {
      return _buildEmptyState(
        isDark,
        textColor,
        'No history recorded',
        'Past logged sips and brews will show up categorized by date here.',
        drinksColor,
      );
    }

    final sortedDates = _groupedDrinks.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final list = _groupedDrinks[dateKey] ?? [];
        final parsedDate = DateTime.tryParse(dateKey) ?? DateTime.now();
        final formattedDate = DateFormat(
          'EEEE, MMMM d, yyyy',
        ).format(parsedDate);
        final sumCalories = list.fold<double>(0.0, (sum, v) => sum + v.value);
        final cups = _sumCups(list);
        final isExpanded = _expandedDates.contains(dateKey);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E2433).withValues(alpha: 0.6)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  '$cups ${cups == 1 ? 'sip' : 'sips'}  •  ${sumCalories.toInt()} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: drinksColor,
                  ),
                ),
                trailing: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: textColor.withValues(alpha: 0.4),
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
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: list.map((drink) {
                      return _buildDrinkItemCard(
                        drink,
                        isDark,
                        textColor,
                        isHistory: true,
                      );
                    }).toList(),
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrinkItemCard(
    VitalsStreamResponse drink,
    bool isDark,
    Color textColor, {
    bool isHistory = false,
  }) {
    final type = drinkTypeOf(data: drink.data);
    final label = _typeLabel(type, drink.data);
    final rawDetails = drink.data?['details']?.toString().trim();
    final details = (rawDetails == null || rawDetails.isEmpty)
        ? label
        : rawDetails;
    final typeColor = _getColorForType(type);
    final typeIcon = _getIconForType(type);
    final formattedTime = DateFormat('h:mm a').format(drink.createdAt);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isHistory ? 12 : 0, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B26) : const Color(0xFFFAFBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          // Visual category indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Drink text details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Calories & Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${drink.value.toInt()} kcal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              if (!isHistory) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openEditDrinkBottomSheet(drink),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteDrink(drink),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    Color textColor,
    String title,
    String desc,
    Color drinksColor,
  ) {
    return Center(
      child: SingleChildScrollView(
        // Extra bottom inset keeps the text clear of the FAB.
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: drinksColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_food_beverage_outlined,
                size: 48,
                color: drinksColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
