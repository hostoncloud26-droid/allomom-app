import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/vitals/sleep/models/sleep_response_map_model.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_utils.dart';
import 'package:allomom/models/vitals_stream_model.dart';

/// Opens AlloConnect's sleep entry sheet. Resolves to true once a session was
/// saved (or updated), null / false when dismissed.
///
/// Saves under Allomom's key `sleep` with the value in hours (what the sleep
/// tile, Home and the summary card read) and AlloConnect's window in `data`
/// (`sleep_time`, `awake_time`, `total_sleep_duration` in minutes, `source`),
/// stamped with the wake-up time.
Future<bool?> showSleepEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? existingEntry,
  String? userId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        SleepEntryBottomSheet(userId: userId, existingEntry: existingEntry),
  );
}

class SleepEntryBottomSheet extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;

  /// The manually entered session being edited, if any. When null the sheet
  /// adds a new session instead.
  final VitalsStreamResponse? existingEntry;

  const SleepEntryBottomSheet({super.key, this.userId, this.existingEntry});

  @override
  State<SleepEntryBottomSheet> createState() => _SleepEntryBottomSheetState();
}

class _SleepEntryBottomSheetState extends State<SleepEntryBottomSheet> {
  TimeOfDay? _sleepTime;
  TimeOfDay? _awakeTime;

  /// Nights usually start the day before they end, so the bedtime defaults to
  /// yesterday and the wake-up to today. Both are pickable.
  late DateTime _sleepDay;
  late DateTime _wakeDay;

  /// Once a date is picked by hand the times stop moving it around.
  bool _datesEdited = false;

  TimeOfDay? _suggestedBedTime;
  TimeOfDay? _suggestedWakeTime;
  bool _isLoadingSuggestions = false;
  bool _appliedSuggestion = false;
  bool _isSaving = false;

  String get _userId {
    final id = widget.userId?.trim() ?? '';
    return id.isNotEmpty ? id : HealthVitalsController.instance.userId;
  }

  bool get _isValid =>
      _sleepTime != null && _awakeTime != null && _hoursSlept > 0;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _wakeDay = DateTime(now.year, now.month, now.day);
    _sleepDay = _wakeDay.subtract(const Duration(days: 1));

    final existing = widget.existingEntry;
    if (existing != null) {
      final data = existing.data;
      bool parsed = false;
      if (data != null) {
        try {
          final model = SleepResponseMapModel.fromJson(data);
          _setWindow(model.sleepTime, model.awakeTime);
          parsed = true;
        } catch (_) {
          // Falls through to the row's own value below.
        }
      }
      if (!parsed) {
        // An older Allomom log carries only a duration, stamped at wake-up.
        final minutes = SleepUtils.valueMinutes(existing.value, existing.unit);
        if (minutes > 0) {
          final wake = existing.createdAt;
          _setWindow(wake.subtract(Duration(minutes: minutes)), wake);
        }
      }
      // Suggestions are for a fresh entry; an edit starts from its own times.
      return;
    }

    _loadSuggestions();
  }

  void _setWindow(DateTime sleep, DateTime wake) {
    _sleepTime = TimeOfDay.fromDateTime(sleep);
    _awakeTime = TimeOfDay.fromDateTime(wake);
    _sleepDay = DateTime(sleep.year, sleep.month, sleep.day);
    _wakeDay = DateTime(wake.year, wake.month, wake.day);
    _datesEdited = true;
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final yesterdayMidnight = todayMidnight.subtract(const Duration(days: 1));

      // Steps for yesterday and today.
      final stepsHistory = await HealthVitalsController.instance
          .getVitalsHistory(
            _userId,
            'steps',
            fromDate: yesterdayMidnight,
            toDate: now,
          );

      final result = SleepUtils.calculateSuggestions(stepsHistory);

      if (mounted) {
        setState(() {
          _suggestedBedTime = result?.bedTime;
          _suggestedWakeTime = result?.wakeTime;
          _appliedSuggestion = false;
        });
      }
    } catch (e) {
      debugPrint('Error calculating sleep suggestions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  DateTime get _sleepDateTime {
    if (_sleepTime == null) return DateTime.now();
    return DateTime(
      _sleepDay.year,
      _sleepDay.month,
      _sleepDay.day,
      _sleepTime!.hour,
      _sleepTime!.minute,
    );
  }

  DateTime get _awakeDateTime {
    if (_awakeTime == null) return DateTime.now();
    return DateTime(
      _wakeDay.year,
      _wakeDay.month,
      _wakeDay.day,
      _awakeTime!.hour,
      _awakeTime!.minute,
    );
  }

  double get _hoursSlept {
    if (_sleepTime == null || _awakeTime == null) return 0;

    final minutes = _awakeDateTime.difference(_sleepDateTime).inMinutes;
    if (minutes <= 0) return 0;

    return minutes / 60.0;
  }

  /// While the dates are still the defaults, a bedtime later on the clock than
  /// the wake-up means the night crossed midnight, so it sits the day before.
  void _alignSleepDayToTimes() {
    if (_datesEdited || _sleepTime == null || _awakeTime == null) {
      return;
    }

    final sleepMinutes = _sleepTime!.hour * 60 + _sleepTime!.minute;
    final wakeMinutes = _awakeTime!.hour * 60 + _awakeTime!.minute;

    _sleepDay = sleepMinutes >= wakeMinutes
        ? _wakeDay.subtract(const Duration(days: 1))
        : _wakeDay;
  }

  Future<void> _selectTime(BuildContext context, bool isSleepTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isSleepTime
          ? (_sleepTime ?? const TimeOfDay(hour: 22, minute: 0))
          : (_awakeTime ?? const TimeOfDay(hour: 7, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isSleepTime) {
          _sleepTime = picked;
        } else {
          _awakeTime = picked;
        }
        _alignSleepDayToTimes();
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isSleepDate) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // A night cannot end before it began: the wake-up date starts at the
    // bedtime date, and the bedtime date stops at the wake-up date.
    var firstDate = isSleepDate
        ? today.subtract(const Duration(days: 365))
        : _sleepDay;
    var lastDate = isSleepDate
        ? (_wakeDay.isBefore(today) ? _wakeDay : today)
        : today;

    if (firstDate.isAfter(lastDate)) {
      firstDate = lastDate;
    }

    var initialDate = isSleepDate ? _sleepDay : _wakeDay;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isSleepDate) {
          _sleepDay = DateTime(picked.year, picked.month, picked.day);
        } else {
          _wakeDay = DateTime(picked.year, picked.month, picked.day);
        }
        _datesEdited = true;
      });
    }
  }

  Future<void> _saveSleepData() async {
    if (!_isValid || _isSaving) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);

    try {
      // Both ends carry their own date, so the window is taken as picked.
      final DateTime sleepDate = _sleepDateTime;
      final DateTime awakeDate = _awakeDateTime;
      final hours = _hoursSlept;

      final controller = HealthVitalsController.instance;
      final data = SleepUtils.manualSessionData(
        sleepTime: sleepDate,
        awakeTime: awakeDate,
      );

      // The session is stamped with its wake-up time: a night that starts
      // before midnight still counts for the day it ended on.
      final existing = widget.existingEntry;
      final VitalsStreamResponse? saved;
      if (existing != null) {
        saved = await controller.updateVitalEntry(
          vitalId: existing.id,
          key: 'sleep',
          value: hours,
          unit: 'hours',
          data: data,
          createdAt: awakeDate,
          userId: _userId,
        );
      } else {
        saved = await controller.addVitalEntry(
          key: 'sleep',
          value: hours,
          unit: 'hours',
          data: data,
          createdAt: awakeDate,
          userId: _userId,
        );
      }

      if (saved == null) {
        throw Exception(controller.error);
      }

      navigator.pop(true);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Sleep data updated successfully'
                : 'Sleep data saved successfully',
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text('Error saving sleep data'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hours = _hoursSlept;
    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isEditing ? 'Edit sleep session' : 'How did you sleep ?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your rest to help us understand your recovery better.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    title: 'Bedtime',
                    time: _sleepTime,
                    date: _sleepDay,
                    icon: Icons.nights_stay_rounded,
                    color: Colors.indigo.shade400,
                    onTap: () => _selectTime(context, true),
                    onDateTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    title: 'Wake up',
                    time: _awakeTime,
                    date: _wakeDay,
                    icon: Icons.light_mode_rounded,
                    color: Colors.orange.shade400,
                    onTap: () => _selectTime(context, false),
                    onDateTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            if (!_isValid && _sleepTime != null && _awakeTime != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wake-up must come after bedtime. Check the dates.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_isValid) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.indigo.shade900
                      : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.indigo.shade700
                        : Colors.indigo.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: isDark
                          ? Colors.indigo.shade300
                          : Colors.indigo.shade400,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Sleep',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.indigo.shade300
                                : Colors.indigo.shade400,
                          ),
                        ),
                        Text(
                          '${hours.toStringAsFixed(1)} hours',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_isLoadingSuggestions) ...[
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Analyzing steps for sleep suggestions...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 350),
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              sizeCurve: Curves.easeInOut,
              crossFadeState:
                  (!_isLoadingSuggestions &&
                      _suggestedBedTime != null &&
                      _suggestedWakeTime != null &&
                      !_appliedSuggestion)
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _sleepTime = _suggestedBedTime;
                        _awakeTime = _suggestedWakeTime;
                        _appliedSuggestion = true;
                        _alignSleepDayToTimes();
                      });
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF3730A3), Color(0xFF4338CA)]
                              : const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4F46E5,
                            ).withValues(alpha: isDark ? 0.5 : 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tap to apply suggestion',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_suggestedBedTime?.format(context) ?? ''}  →  ${_suggestedWakeTime?.format(context) ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isValid && !_isSaving ? _saveSleepData : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  disabledBackgroundColor: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Sleep Data' : 'Save Sleep Data',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String title,
    required TimeOfDay? time,
    required DateTime date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onDateTap,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: time != null
                    ? color.withValues(alpha: isDark ? 0.6 : 0.5)
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: 1.5,
              ),
              boxShadow: [
                if (time != null)
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  time != null ? time.format(context) : 'Select Time',
                  style: TextStyle(
                    fontSize: time != null ? 22 : 16,
                    fontWeight: time != null
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: time != null
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 10),
                // The date is picked separately so a night that crosses
                // midnight can be entered as it happened.
                InkWell(
                  onTap: onDateTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _formatEntryDate(date),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Yesterday and today are named rather than dated, since that is what a
  /// night's two ends almost always are.
  String _formatEntryDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) {
      return 'Today';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return DateFormat('EEE, MMM d').format(day);
  }
}
