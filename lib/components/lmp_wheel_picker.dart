import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';

class MonthOption {
  final int year;
  final int month;
  final String label;
  final String fullName;

  MonthOption({
    required this.year,
    required this.month,
    required this.label,
    required this.fullName,
  });
}

/// The day-and-month wheels she picks her last period on — in sign-up and
/// when she registers a pregnancy later. Months run up to the current one and
/// back as far as a pregnancy (or, outside one, a cycle) can reach, so a date
/// in the future or out of range cannot be picked at all.
class LmpWheelPicker extends StatefulWidget {
  const LmpWheelPicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.isPregnant = true,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  /// Pregnant: the last 42 weeks. Otherwise: the last 12 months.
  final bool isPregnant;

  @override
  State<LmpWheelPicker> createState() => _LmpWheelPickerState();
}

class _LmpWheelPickerState extends State<LmpWheelPicker> {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late DateTime _selectedDate;
  late List<MonthOption> _validMonths;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  int _selectedMonthIndex = 0;
  int _selectedDay = 1;

  bool get _isPregnant => widget.isPregnant;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _minDate {
    if (_isPregnant) {
      // Pregnant: today to past 42 weeks (42 * 7 = 294 days)
      return _today.subtract(const Duration(days: 42 * 7));
    }
    // Pre Pregnancy or New Mom: today to past 12 months
    return DateTime(_today.year - 1, _today.month, _today.day);
  }

  @override
  void initState() {
    super.initState();
    _initData(widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant LmpWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPregnant != widget.isPregnant) {
      _monthController.dispose();
      _dayController.dispose();
      _initData(_selectedDate);
      setState(() {});
    }
  }

  void _initData(DateTime initialDate) {
    final today = _today;
    final minDate = _minDate;

    // Clamp initialDate between minDate and today
    DateTime clampedDate = initialDate;
    if (clampedDate.isAfter(today)) clampedDate = today;
    if (clampedDate.isBefore(minDate)) clampedDate = minDate;
    _selectedDate = clampedDate;

    // Generate list of valid months from minDate up to today
    _validMonths = _generateValidMonths(minDate, today);

    // Find selected month index
    _selectedMonthIndex = _validMonths.indexWhere(
      (m) => m.year == _selectedDate.year && m.month == _selectedDate.month,
    );
    if (_selectedMonthIndex < 0) {
      _selectedMonthIndex = _validMonths.length - 1; // Default to current month
    }

    final currentMonthOpt = _validMonths[_selectedMonthIndex];
    final minDay = _getMinDayForMonth(currentMonthOpt, minDate);
    final maxDay = _getMaxDayForMonth(currentMonthOpt, today);
    _selectedDay = _selectedDate.day.clamp(minDay, maxDay);

    final dayIndex = (_selectedDay - minDay).clamp(0, maxDay - minDay);

    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonthIndex,
    );
    _dayController = FixedExtentScrollController(initialItem: dayIndex);
  }

  List<MonthOption> _generateValidMonths(DateTime minDate, DateTime today) {
    final List<MonthOption> list = [];
    var cur = DateTime(minDate.year, minDate.month, 1);
    final end = DateTime(today.year, today.month, 1);

    while (!cur.isAfter(end)) {
      final isCurrentYear = cur.year == today.year;
      final label = isCurrentYear
          ? _monthNames[cur.month - 1]
          : '${_monthNames[cur.month - 1]} \'${cur.year % 100}';

      list.add(
        MonthOption(
          year: cur.year,
          month: cur.month,
          label: label,
          fullName: '${_monthNames[cur.month - 1]} ${cur.year}',
        ),
      );
      cur = DateTime(cur.year, cur.month + 1, 1);
    }
    return list;
  }

  int _getMinDayForMonth(MonthOption monthOpt, DateTime minDate) {
    if (monthOpt.year == minDate.year && monthOpt.month == minDate.month) {
      return minDate.day;
    }
    return 1;
  }

  int _getMaxDayForMonth(MonthOption monthOpt, DateTime today) {
    if (monthOpt.year == today.year && monthOpt.month == today.month) {
      return today.day;
    }
    return DateTime(monthOpt.year, monthOpt.month + 1, 0).day;
  }

  void _onMonthWheelChanged(int index) {
    if (index < 0 || index >= _validMonths.length) return;
    HapticFeedback.selectionClick();

    final monthOpt = _validMonths[index];
    final minDay = _getMinDayForMonth(monthOpt, _minDate);
    final maxDay = _getMaxDayForMonth(monthOpt, _today);

    final newDay = _selectedDay.clamp(minDay, maxDay);
    final newDate = DateTime(monthOpt.year, monthOpt.month, newDay);

    setState(() {
      _selectedMonthIndex = index;
      _selectedDay = newDay;
      _selectedDate = newDate;
    });

    final targetDayIndex = newDay - minDay;
    if (_dayController.hasClients) {
      _dayController.jumpToItem(targetDayIndex);
    }

    widget.onDateChanged(newDate);
  }

  void _onDayWheelChanged(int index) {
    final monthOpt = _validMonths[_selectedMonthIndex];
    final minDay = _getMinDayForMonth(monthOpt, _minDate);
    final maxDay = _getMaxDayForMonth(monthOpt, _today);

    final targetDay = (minDay + index).clamp(minDay, maxDay);
    HapticFeedback.selectionClick();

    final newDate = DateTime(monthOpt.year, monthOpt.month, targetDay);
    setState(() {
      _selectedDay = targetDay;
      _selectedDate = newDate;
    });

    widget.onDateChanged(newDate);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final muted = p.pick(const Color(0xFF8E95A5), p.textMuted);
    final currentMonthOpt = _validMonths[_selectedMonthIndex];
    final minDay = _getMinDayForMonth(currentMonthOpt, _minDate);
    final maxDay = _getMaxDayForMonth(currentMonthOpt, _today);
    final dayCount = maxDay - minDay + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LAST MENSTRUAL PERIOD (LMP)',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: muted,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF4E6A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date Picker Wheel Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: p.pick(const Color(0xFFF9FAFB), p.card),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: p.pick(const Color(0xFFE5E7EB), p.border),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Column Labels: DAY | MONTH
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'DAY',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'MONTH',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Wheel Picker Area
              SizedBox(
                height: 138,
                child: Stack(
                  children: [
                    // Center Selection Highlight Bar
                    Center(
                      child: Container(
                        height: 42,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: p.tint(
                            const Color(0xFFFF4E6A),
                            const Color(0xFFFFF0F3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFFF4E6A,
                            ).withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Day & Month Wheels
                    Row(
                      children: [
                        // Day wheel
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _dayController,
                            itemExtent: 42,
                            perspective: 0.003,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: _onDayWheelChanged,
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                if (index < 0 || index >= dayCount) return null;
                                final dayVal = minDay + index;
                                final isSelected = dayVal == _selectedDay;
                                return Center(
                                  child: Text(
                                    '$dayVal',
                                    style: GoogleFonts.outfit(
                                      fontSize: isSelected ? 21 : 15.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFFF4E6A)
                                          : muted,
                                    ),
                                  ),
                                );
                              },
                              childCount: dayCount,
                            ),
                          ),
                        ),

                        // Month wheel (Stops strictly at Current Month)
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _monthController,
                            itemExtent: 42,
                            perspective: 0.003,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: _onMonthWheelChanged,
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                if (index < 0 || index >= _validMonths.length) {
                                  return null;
                                }
                                final m = _validMonths[index];
                                final isSelected = index == _selectedMonthIndex;
                                return Center(
                                  child: Text(
                                    m.label,
                                    style: GoogleFonts.outfit(
                                      fontSize: isSelected ? 19 : 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFFF4E6A)
                                          : muted,
                                    ),
                                  ),
                                );
                              },
                              childCount: _validMonths.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
