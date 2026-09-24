// Blood glucose summary, built in the shape of AlloConnect's
// lib/features/health_section/vitals/blood_oxygen/blood_oxygen_summary_screen.dart
// (AlloConnect has no glucose screen). Data: key `glucose` (legacy
// `blood_glucose` read too), mg/dL, data['mealPhase'].
import 'package:flutter/material.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:intl/intl.dart';

import 'blood_glucose_entry_sheet.dart';
import 'models/blood_glucose_models.dart';
import 'views/daily_blood_glucose_view.dart';
import 'views/monthly_blood_glucose_view.dart';
import 'views/weekly_blood_glucose_view.dart';

class BloodGlucoseSummaryScreen extends StatefulWidget {
  /// Day shown by the Day tab. Defaults to today.
  final DateTime? initialDate;

  /// 0: Day, 1: Week, 2: Month.
  final int initialTab;

  const BloodGlucoseSummaryScreen({
    super.key,
    this.initialDate,
    this.initialTab = 0,
  });

  @override
  State<BloodGlucoseSummaryScreen> createState() =>
      _BloodGlucoseSummaryScreenState();
}

class _BloodGlucoseSummaryScreenState extends State<BloodGlucoseSummaryScreen> {
  late int _selectedFilterIndex = widget.initialTab.clamp(0, 2);
  final List<String> _filters = const ['Day', 'Week', 'Month'];
  late DateTime _selectedDate;
  int _refreshTick = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final d = widget.initialDate ?? now;
    _selectedDate = d.isAfter(now)
        ? DateUtils.dateOnly(now)
        : DateUtils.dateOnly(d);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _refreshTick++);
  }

  Future<void> _openAddSheet() async {
    final saved = await showBloodGlucoseEntrySheet(
      context,
      initialDate: _selectedFilterIndex == 0 ? _selectedDate : null,
    );
    if (saved == true) _refresh();
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
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Blood Glucose Analysis',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: kGlucoseColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Glucose',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: kGlucoseColor,
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VitalBabyBanner(narrationKey: NarrationKeys.pgVitalsGlucose),
                _buildFilterToggle(isDarkMode, textColor),
                if (_selectedFilterIndex == 0) ...[
                  const SizedBox(height: 16),
                  _buildDateNavigator(isDarkMode, textColor),
                ],
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildCurrentView(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigator(bool isDark, Color textColor) {
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = DateUtils.isSameDay(_selectedDate, today);
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: textColor),
          onPressed: () => setState(
            () =>
                _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(today.year - 2),
                lastDate: today,
              );
              if (picked != null) {
                setState(() => _selectedDate = DateUtils.dateOnly(picked));
              }
            },
            child: Text(
              isToday
                  ? 'Today'
                  : DateFormat('EEE, d MMM yyyy').format(_selectedDate),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right_rounded,
            color: isToday ? textColor.withValues(alpha: 0.2) : textColor,
          ),
          onPressed: isToday
              ? null
              : () => setState(
                  () => _selectedDate = _selectedDate.add(
                    const Duration(days: 1),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterToggle(bool isDarkMode, Color textColor) {
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
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
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
                  _filters[index],
                  style: TextStyle(
                    color: isSelected
                        ? textColor
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

  Widget _buildCurrentView() {
    switch (_selectedFilterIndex) {
      case 0:
        return DailyBloodGlucoseView(
          key: ValueKey(
            'daily-${_selectedDate.toIso8601String()}-$_refreshTick',
          ),
          date: _selectedDate,
          onChanged: _refresh,
        );
      case 1:
        return WeeklyBloodGlucoseView(
          key: ValueKey('weekly-$_refreshTick'),
          onChanged: _refresh,
        );
      case 2:
        return MonthlyBloodGlucoseView(
          key: ValueKey('monthly-$_refreshTick'),
          onChanged: _refresh,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
