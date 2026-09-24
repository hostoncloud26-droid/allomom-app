import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/vitals/sleep/models/sleep_response_map_model.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_entry_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_utils.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// AlloConnect's sleep analysis screen: Overview (today's hero ring, sessions
/// and insights), Weekly (summary, 7-day bar chart, insights) and History
/// (expandable per-day sessions with stage bars).
///
/// Reads every sleep key Allomom stores (`sleep`, `sleep_data`,
/// `sleep_hours`); manual sessions can be swiped to edit or delete.
class SleepSummaryScreen extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;
  final double initialSleepHours;
  final double targetSleepHours;
  final DateTime? bedTime;
  final DateTime? wakeTime;

  const SleepSummaryScreen({
    super.key,
    this.userId,
    this.initialSleepHours = 0,
    this.targetSleepHours = 8.0,
    this.bedTime,
    this.wakeTime,
  });

  @override
  State<SleepSummaryScreen> createState() => _SleepSummaryScreenState();
}

class _SleepSummaryScreenState extends State<SleepSummaryScreen> {
  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;

  String get _userId {
    final id = widget.userId?.trim() ?? '';
    return id.isNotEmpty ? id : _vitalsController.userId;
  }

  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Overview', 'Weekly', 'History'];

  bool _isLoadingHistory = false;
  List<_SleepSession> _sessions = const [];
  List<_SleepNightAggregate> _history = const [];
  final Set<String> _expandedHistoryDayKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchSleepHistory();
  }

  void _showSleepEntrySheet({_SleepSession? session}) {
    if (!mounted) return;
    showSleepEntrySheet(
      context,
      userId: _userId,
      existingEntry: session?.vital,
    ).then((wasUpdated) {
      if (wasUpdated == true) {
        _fetchSleepHistory();
      }
    });
  }

  Future<void> _deleteSession(_SleepSession session) async {
    // Soft delete through the local store so the removal syncs; the
    // controller's deleteVital would rewrite the row under key 'deleted'.
    await VitalsSqLiteService().deleteVital(session.id);
    await _fetchSleepHistory();
    await _vitalsController.fetchLatestVitals(showLoading: false);
  }

  Future<bool> _confirmDeleteSession(_SleepSession session) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final range =
        '${DateFormat('hh:mm a').format(session.sleepTime)} - ${DateFormat('hh:mm a').format(session.wakeTime)}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF16203A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete sleep session?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : const Color(0xFF1A1C1E),
            ),
          ),
          content: Text(
            '$range · ${_formatDuration(session.totalSleepMinutes)}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _fetchSleepHistory() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingHistory = true;
        });
      }

      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30));
      // A night that ended today is stamped with today's wake-up time, so
      // the window runs to the end of today.
      final toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final vitals = <VitalsStreamResponse>[];
      for (final key in SleepUtils.sleepVitalKeys) {
        vitals.addAll(
          await _vitalsController.getVitalsHistory(
            _userId,
            key,
            fromDate: fromDate,
            toDate: toDate,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      // Each row is one session, kept apart; a day is the sessions that ended
      // on it, so a night started before midnight lands on its wake-up date.
      final sessions = <_SleepSession>[];
      final byDay = <String, List<_SleepSession>>{};

      for (final vital in vitals) {
        final parsed = _SleepSession.fromVital(vital);
        if (parsed == null || !parsed.hasData) {
          continue;
        }

        sessions.add(parsed);
        byDay
            .putIfAbsent(
              DateFormat('yyyy-MM-dd').format(parsed.day),
              () => <_SleepSession>[],
            )
            .add(parsed);
      }

      sessions.sort((a, b) => b.wakeTime.compareTo(a.wakeTime));

      final sortedHistory =
          byDay.values
              .map(
                (daySessions) => _SleepNightAggregate.fromSessions(
                  daySessions.first.day,
                  daySessions,
                ),
              )
              .toList()
            ..sort((a, b) => a.day.compareTo(b.day));

      setState(() {
        _sessions = sessions;
        _history = sortedHistory;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  /// Today's sessions, newest wake-up first.
  List<_SleepSession> get _todaySessions {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _sessions
        .where(
          (session) => DateFormat('yyyy-MM-dd').format(session.day) == todayKey,
        )
        .toList();
  }

  _SleepNightAggregate get _currentNight {
    final todaySessions = _todaySessions;
    if (todaySessions.isNotEmpty) {
      return _SleepNightAggregate.fromSessions(
        todaySessions.first.day,
        todaySessions,
      );
    }

    final wakeTime = widget.wakeTime ?? DateTime.now();
    final now = DateTime.now();
    final isWakeTimeToday =
        wakeTime.year == now.year &&
        wakeTime.month == now.month &&
        wakeTime.day == now.day;

    if (isWakeTimeToday && widget.initialSleepHours > 0) {
      final fallbackMinutes = math.max(
        0,
        (widget.initialSleepHours * 60).round(),
      );
      final defaultBed = wakeTime.subtract(Duration(minutes: fallbackMinutes));
      final bedTime = widget.bedTime ?? defaultBed;

      return _SleepNightAggregate.estimated(
        day: DateTime(wakeTime.year, wakeTime.month, wakeTime.day),
        sleepTime: bedTime,
        wakeTime: wakeTime,
        totalSleepMinutes: fallbackMinutes,
        createdAt: wakeTime,
      );
    }

    return _SleepNightAggregate.empty(now);
  }

  int _qualityScore(_SleepStats night) {
    if (!night.hasData) {
      return 0;
    }

    final durationScore =
        (night.totalHours / widget.targetSleepHours).clamp(0.0, 1.0) * 50;

    final deepDeviation = (night.deepRatio - 0.22).abs();
    final deepScore = (1 - (deepDeviation / 0.22).clamp(0.0, 1.0)) * 20;

    final remDeviation = (night.remRatio - 0.22).abs();
    final remScore = (1 - (remDeviation / 0.22).clamp(0.0, 1.0)) * 15;

    final awakePenalty = (night.awakeRatio / 0.18).clamp(0.0, 1.0);
    final awakeScore = (1 - awakePenalty) * 15;

    final rawScore = (durationScore + deepScore + remScore + awakeScore)
        .round();
    return rawScore.clamp(0, 100).toInt();
  }

  Color _qualityColor(int score, {bool hasData = true}) {
    if (!hasData) {
      return const Color(0xFF6366F1);
    }
    if (score >= 85) {
      return const Color(0xFF16A34A);
    }
    if (score >= 70) {
      return const Color(0xFF0EA5E9);
    }
    if (score >= 55) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFFEF4444);
  }

  String _qualityLabel(int score, {bool hasData = true}) {
    if (!hasData) {
      return 'No Data';
    }
    if (score >= 85) {
      return 'Excellent';
    }
    if (score >= 70) {
      return 'Good';
    }
    if (score >= 55) {
      return 'Fair';
    }
    return 'Needs Attention';
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) {
      return '0m';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '${mins}m';
    }
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  String _formatDurationHours(int minutes) {
    if (minutes <= 0) {
      return '0 Hours';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '$mins Mins';
    }
    final hourLabel = hours == 1 ? 'Hour' : 'Hours';
    if (mins == 0) {
      return '$hours $hourLabel';
    }
    return '$hours $hourLabel $mins Mins';
  }

  String _formatHour(double value) {
    if (value <= 0) {
      return '0';
    }
    final isWhole = (value - value.roundToDouble()).abs() < 0.01;
    if (isWhole) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSleepEntrySheet,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Log Sleep',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
          'Sleep Analysis',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSleepHistory,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VitalBabyBanner(),
                _buildFilterToggle(isDarkMode, textColor),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: _buildCurrentView(isDarkMode, textColor),
                ),
                // Keeps the last card clear of the Log Sleep FAB.
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildCurrentView(bool isDarkMode, Color textColor) {
    switch (_selectedFilterIndex) {
      case 0:
        return _buildOverview(
          isDarkMode,
          textColor,
          key: const ValueKey('overview'),
        );
      case 1:
        return _buildWeeklyInsights(
          isDarkMode,
          textColor,
          key: const ValueKey('weekly'),
        );
      case 2:
        return _buildHistoryView(
          isDarkMode,
          textColor,
          key: const ValueKey('history'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverview(bool isDarkMode, Color textColor, {Key? key}) {
    final current = _currentNight;
    final sessions = _todaySessions;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroProgress(current, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildTodaySessions(sessions, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildTodayInsights(sessions, current, isDarkMode, textColor),
      ],
    );
  }

  Widget _buildHeroProgress(
    _SleepNightAggregate current,
    bool isDarkMode,
    Color textColor,
  ) {
    final progress = (current.totalHours / widget.targetSleepHours).clamp(
      0.0,
      1.0,
    );
    final score = _qualityScore(current);
    final qualityColor = _qualityColor(score, hasData: current.hasData);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date header. Sessions are added and edited from the list below,
          // so the card itself carries no edit action.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Date',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(current.day),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 176,
                height: 176,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: qualityColor.withValues(alpha: 0.1),
                  color: qualityColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: 134,
                height: 134,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      qualityColor.withValues(alpha: 0.18),
                      qualityColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatHour(current.totalHours),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HOURS',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: current.hasData
                  ? qualityColor.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  current.hasData
                      ? Icons.auto_awesome_rounded
                      : Icons.info_outline_rounded,
                  color: current.hasData
                      ? qualityColor
                      : textColor.withValues(alpha: 0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  current.hasData
                      ? '${_qualityLabel(score, hasData: true)} · $score/100'
                      : 'No Sleep Data Today',
                  style: TextStyle(
                    color: current.hasData
                        ? qualityColor
                        : textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCycleStatMetric(
                'Goal',
                '${_formatHour(widget.targetSleepHours)}h',
                textColor,
                Icons.flag_rounded,
                qualityColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: textColor.withValues(alpha: 0.1),
              ),
              _buildCycleStatMetric(
                'Bedtime',
                current.hasData
                    ? DateFormat('HH:mm').format(current.sleepTime)
                    : '--',
                textColor,
                Icons.nights_stay_rounded,
                qualityColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: textColor.withValues(alpha: 0.1),
              ),
              _buildCycleStatMetric(
                'Wake up',
                current.hasData
                    ? DateFormat('HH:mm').format(current.wakeTime)
                    : '--',
                textColor,
                Icons.light_mode_rounded,
                qualityColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCycleStatMetric(
    String label,
    String value,
    Color textColor,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySessions(
    List<_SleepSession> sessions,
    bool isDarkMode,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Sleep Sessions",
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          _buildSessionsEmptyState(isDarkMode, textColor)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildSessionCard(sessions[index], isDarkMode, textColor),
          ),
      ],
    );
  }

  Widget _buildSessionsEmptyState(bool isDarkMode, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 30,
            color: textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No sleep recorded today',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sessions show up here once you log them. Tap Log Sleep to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    _SleepSession session,
    bool isDarkMode,
    Color textColor,
  ) {
    final score = _qualityScore(session);
    final qualityColor = _qualityColor(score);
    final timeFormat = DateFormat('hh:mm a');
    final cardBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white;
    final cardBorder = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.03);

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: qualityColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.isNap
                      ? Icons.wb_twilight_rounded
                      : Icons.nights_stay_rounded,
                  color: qualityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDurationHours(session.totalSleepMinutes),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormat.format(session.sleepTime)} - ${timeFormat.format(session.wakeTime)}',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    session.isManual
                        ? Icons.smartphone_rounded
                        : Icons.watch_rounded,
                    size: 19,
                    color: textColor.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: qualityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Score: $score',
                      style: TextStyle(
                        color: qualityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStageBar(session, isDarkMode),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildStageLegend(
                'Deep',
                session.deepMinutes,
                const Color(0xFF4F46E5),
                textColor,
              ),
              _buildStageLegend(
                'Light',
                session.lightMinutes,
                const Color(0xFF0EA5E9),
                textColor,
              ),
              _buildStageLegend(
                'REM',
                session.remMinutes,
                const Color(0xFF9333EA),
                textColor,
              ),
              _buildStageLegend(
                'Awake',
                session.awakeMinutes,
                const Color(0xFFF59E0B),
                textColor,
              ),
            ],
          ),
        ],
      ),
    );

    // If source is allowear, no swipe function.
    // Only manual-added sessions can be swiped to edit or delete.
    if (!session.isManual) {
      return card;
    }

    return Dismissible(
      key: ValueKey('manual_session_${session.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          _showSleepEntrySheet(session: session);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await _confirmDeleteSession(session);
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
          _deleteSession(session);
        }
      },
      child: card,
    );
  }

  /// The session's stages as one bar, so the make-up of a session reads at a
  /// glance without a row of progress bars per card.
  Widget _buildStageBar(_SleepStats stats, bool isDarkMode) {
    final segments = <MapEntry<Color, int>>[
      MapEntry(const Color(0xFF4F46E5), stats.deepMinutes),
      MapEntry(const Color(0xFF0EA5E9), stats.lightMinutes),
      MapEntry(const Color(0xFF9333EA), stats.remMinutes),
      MapEntry(const Color(0xFFF59E0B), stats.awakeMinutes),
    ].where((segment) => segment.value > 0).toList();

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Row(
          children: segments
              .map(
                (segment) => Expanded(
                  flex: segment.value,
                  child: Container(color: segment.key),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStageLegend(
    String label,
    int minutes,
    Color color,
    Color textColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ${minutes > 0 ? _formatDuration(minutes) : '--'}',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Insights for the sessions that ended today, read off their wake-up times.
  Widget _buildTodayInsights(
    List<_SleepSession> sessions,
    _SleepNightAggregate current,
    bool isDarkMode,
    Color textColor,
  ) {
    final insights = <_SleepInsight>[];

    if (sessions.isEmpty) {
      insights.add(
        _SleepInsight(
          message: 'No sleep tracked today yet. Add a session to see insights.',
          icon: Icons.bedtime_outlined,
          color: const Color(0xFF6366F1),
        ),
      );
    } else {
      final goalMinutes = (widget.targetSleepHours * 60).round();
      final diff = current.totalSleepMinutes - goalMinutes;

      insights.add(
        _SleepInsight(
          message: diff >= 0
              ? 'You slept ${_formatDuration(current.totalSleepMinutes)} today, meeting your ${_formatHour(widget.targetSleepHours)}h goal.'
              : '${_formatDuration(diff.abs())} short of your ${_formatHour(widget.targetSleepHours)}h goal, at ${_formatDuration(current.totalSleepMinutes)} today.',
          icon: diff >= 0
              ? Icons.check_circle_rounded
              : Icons.trending_down_rounded,
          color: diff >= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        ),
      );

      // Latest wake-up of the day, against the wake-ups of the days before it.
      final latestWake = sessions.first.wakeTime;
      final wakeText = DateFormat('hh:mm a').format(latestWake);
      final averageWakeMinutes = _averageWakeMinutes(excludeToday: true);

      if (averageWakeMinutes != null) {
        final todayWakeMinutes = latestWake.hour * 60 + latestWake.minute;
        final wakeDiff = todayWakeMinutes - averageWakeMinutes;
        final usualWake = DateFormat('hh:mm a').format(
          DateTime(
            2000,
            1,
            1,
            averageWakeMinutes ~/ 60,
            averageWakeMinutes % 60,
          ),
        );

        insights.add(
          _SleepInsight(
            message: wakeDiff.abs() <= 20
                ? 'You woke at $wakeText, right around your usual $usualWake.'
                : wakeDiff < 0
                ? 'You woke at $wakeText, ${_formatDuration(wakeDiff.abs())} earlier than your usual $usualWake.'
                : 'You woke at $wakeText, ${_formatDuration(wakeDiff)} later than your usual $usualWake.',
            icon: Icons.light_mode_rounded,
            color: const Color(0xFF0EA5E9),
          ),
        );
      } else {
        insights.add(
          _SleepInsight(
            message: 'You woke at $wakeText today.',
            icon: Icons.light_mode_rounded,
            color: const Color(0xFF0EA5E9),
          ),
        );
      }

      if (sessions.length > 1) {
        final naps = sessions.where((session) => session.isNap).length;
        final longest = sessions.reduce(
          (a, b) => a.totalSleepMinutes >= b.totalSleepMinutes ? a : b,
        );

        insights.add(
          _SleepInsight(
            message: naps > 0
                ? '${sessions.length} sessions today: a main stretch of ${_formatDuration(longest.totalSleepMinutes)} plus ${naps == 1 ? '1 nap' : '$naps naps'}.'
                : '${sessions.length} sessions today, the longest running ${_formatDuration(longest.totalSleepMinutes)}.',
            icon: Icons.splitscreen_rounded,
            color: const Color(0xFF9333EA),
          ),
        );
      }

      final deepPercent = (current.deepRatio * 100).round();
      if (current.deepMinutes > 0) {
        insights.add(
          _SleepInsight(
            message: deepPercent >= 20
                ? 'Deep sleep was $deepPercent% of your rest -- solid physical recovery.'
                : 'Deep sleep was only $deepPercent% of your rest; aim for 20-25% with an earlier, steadier bedtime.',
            icon: Icons.auto_awesome_rounded,
            color: deepPercent >= 20
                ? const Color(0xFF10B981)
                : const Color(0xFF6366F1),
          ),
        );
      }

      if (current.awakeMinutes >= 30) {
        insights.add(
          _SleepInsight(
            message:
                'You were awake ${_formatDuration(current.awakeMinutes)} during the night -- a fragmented night dents recovery.',
            icon: Icons.warning_amber_rounded,
            color: Colors.amber.shade600,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Insights",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < insights.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _buildWeeklyInsightCard(
            insights[index].message,
            insights[index].icon,
            insights[index].color,
            isDarkMode,
            textColor,
          ),
        ],
      ],
    );
  }

  /// Average wake-up minute-of-day across the tracked days, used to say whether
  /// today's wake-up was early or late.
  int? _averageWakeMinutes({bool excludeToday = false}) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final wakeMinutes = _history
        .where(
          (night) =>
              night.hasData &&
              (!excludeToday ||
                  DateFormat('yyyy-MM-dd').format(night.day) != todayKey),
        )
        .map((night) => night.wakeTime.hour * 60 + night.wakeTime.minute)
        .toList();

    if (wakeMinutes.isEmpty) {
      return null;
    }

    return (wakeMinutes.reduce((a, b) => a + b) / wakeMinutes.length).round();
  }

  Widget _buildHistoryView(bool isDarkMode, Color textColor, {Key? key}) {
    if (_isLoadingHistory && _history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: _VitalsEmptyState(
          title: 'No sleep history found',
          subtitle: 'Track your sleep to build up your sleep history.',
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF6366F1),
        ),
      );
    }

    // Sort newest to oldest for history tiles
    final sortedHistory = _history.reversed.toList();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sleep History',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedHistory.length,
          itemBuilder: (context, index) {
            final night = sortedHistory[index];
            final score = _qualityScore(night);
            final qualityColor = _qualityColor(score, hasData: night.hasData);
            final formattedDate = DateFormat(
              'EEEE, MMMM dd, yyyy',
            ).format(night.day);
            final durationStr = _formatDurationHours(night.totalSleepMinutes);
            final dayKey = DateFormat('yyyy-MM-dd').format(night.day);
            final isExpanded = _expandedHistoryDayKeys.contains(dayKey);

            final cardBg = isDarkMode
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white;
            final cardBorder = isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkMode ? 0.2 : 0.02,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isExpanded) {
                        _expandedHistoryDayKeys.remove(dayKey);
                      } else {
                        _expandedHistoryDayKeys.add(dayKey);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: qualityColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.nights_stay_rounded,
                                color: qualityColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedDate,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    durationStr,
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: textColor.withValues(alpha: 0.4),
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: qualityColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Score: $score',
                                    style: TextStyle(
                                      color: qualityColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 14),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                          const SizedBox(height: 6),
                          if (night.sessions.isNotEmpty)
                            ...night.sessions.map(
                              (session) => _buildHistoryDropdownSessionItem(
                                session,
                                isDarkMode,
                                textColor,
                              ),
                            )
                          else
                            _buildHistoryDropdownAggregateItem(
                              night,
                              isDarkMode,
                              textColor,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryDropdownSessionItem(
    _SleepSession session,
    bool isDarkMode,
    Color textColor,
  ) {
    final timeFormat = DateFormat('hh:mm a');
    final score = _qualityScore(session);
    final qualityColor = _qualityColor(score);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.025)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                session.isNap
                    ? Icons.wb_twilight_rounded
                    : Icons.nights_stay_rounded,
                color: qualityColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${timeFormat.format(session.sleepTime)} - ${timeFormat.format(session.wakeTime)}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatDurationHours(session.totalSleepMinutes),
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                session.isManual
                    ? Icons.smartphone_rounded
                    : Icons.watch_rounded,
                size: 16,
                color: textColor.withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStageBar(session, isDarkMode),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildStageLegend(
                'Deep',
                session.deepMinutes,
                const Color(0xFF4F46E5),
                textColor,
              ),
              _buildStageLegend(
                'Light',
                session.lightMinutes,
                const Color(0xFF0EA5E9),
                textColor,
              ),
              _buildStageLegend(
                'REM',
                session.remMinutes,
                const Color(0xFF9333EA),
                textColor,
              ),
              _buildStageLegend(
                'Awake',
                session.awakeMinutes,
                const Color(0xFFF59E0B),
                textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDropdownAggregateItem(
    _SleepNightAggregate night,
    bool isDarkMode,
    Color textColor,
  ) {
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.025)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.nights_stay_rounded,
                color: textColor.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${timeFormat.format(night.sleepTime)} - ${timeFormat.format(night.wakeTime)}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatDurationHours(night.totalSleepMinutes),
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStageBar(night, isDarkMode),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildStageLegend(
                'Deep',
                night.deepMinutes,
                const Color(0xFF4F46E5),
                textColor,
              ),
              _buildStageLegend(
                'Light',
                night.lightMinutes,
                const Color(0xFF0EA5E9),
                textColor,
              ),
              _buildStageLegend(
                'REM',
                night.remMinutes,
                const Color(0xFF9333EA),
                textColor,
              ),
              _buildStageLegend(
                'Awake',
                night.awakeMinutes,
                const Color(0xFFF59E0B),
                textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyInsights(bool isDarkMode, Color textColor, {Key? key}) {
    final last7Days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      for (final night in _history) {
        if (DateFormat('yyyy-MM-dd').format(night.day) == dateKey) {
          return night;
        }
      }
      return _SleepNightAggregate.empty(date);
    }).reversed.toList();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklySummarySection(last7Days, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildWeeklyChart(last7Days, isDarkMode, textColor),
        const SizedBox(height: 24),
        _buildWeeklyInsightsSection(last7Days, isDarkMode, textColor),
      ],
    );
  }

  Widget _buildWeeklySummarySection(
    List<_SleepNightAggregate> last7Days,
    bool isDark,
    Color textColor,
  ) {
    double totalHours = 0;
    int daysWithData = 0;
    double maxHours = 0;
    int daysMetGoal = 0;

    for (var night in last7Days) {
      if (night.hasData) {
        totalHours += night.totalHours;
        daysWithData++;
        if (night.totalHours > maxHours) {
          maxHours = night.totalHours;
        }
        if (night.totalHours >= widget.targetSleepHours) {
          daysMetGoal++;
        }
      }
    }

    final avgHours = daysWithData > 0 ? totalHours / daysWithData : 0.0;
    final consistencyProgress = widget.targetSleepHours > 0
        ? (avgHours / widget.targetSleepHours).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat(
                'Weekly Avg',
                '${avgHours.toStringAsFixed(1)}h',
                textColor,
              ),
              _buildSimpleStat('Goal Met', '$daysMetGoal/7 days', textColor),
              _buildSimpleStat(
                'Best Night',
                '${maxHours.toStringAsFixed(1)}h',
                textColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildWeeklyAverageComparison(avgHours, consistencyProgress, isDark),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAverageComparison(
    double avgHours,
    double progress,
    bool isDark,
  ) {
    final color = progress >= 0.85
        ? const Color(0xFF10B981)
        : const Color(0xFF6366F1);
    final diff = avgHours - widget.targetSleepHours;
    final diffText = diff >= 0
        ? '${diff.toStringAsFixed(1)}h above goal'
        : '${diff.abs().toStringAsFixed(1)}h below goal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              avgHours > 0 ? diffText : 'No sleep tracked this week',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    List<_SleepNightAggregate> last7Days,
    bool isDark,
    Color textColor,
  ) {
    double maxHours = 10;
    for (var night in last7Days) {
      if (night.totalHours > maxHours) {
        maxHours = night.totalHours;
      }
    }
    final maxY = math.max(12.0, maxHours + 2.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Trends',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 3,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: widget.targetSleepHours,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.2),
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      labelResolver: (_) => 'Goal',
                    ),
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < last7Days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat(
                              'E',
                            ).format(last7Days[idx].day).toUpperCase(),
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.35),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: last7Days.asMap().entries.map((e) {
                final isGoalReached =
                    e.value.hasData &&
                    e.value.totalHours >= widget.targetSleepHours;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.totalHours,
                      color: isGoalReached
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1),
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.01),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyInsightsSection(
    List<_SleepNightAggregate> last7Days,
    bool isDark,
    Color textColor,
  ) {
    final bedtimeMinutes = last7Days.where((night) => night.hasData).map((
      night,
    ) {
      var mins = night.sleepTime.hour * 60 + night.sleepTime.minute;
      if (mins < 12 * 60) {
        mins += 24 * 60;
      }
      return mins;
    }).toList();

    String consistencyMsg = 'Start tracking sleep to see consistency.';
    IconData consistencyIcon = Icons.bedtime_outlined;
    Color consistencyColor = Colors.orange.shade400;

    if (bedtimeMinutes.length >= 2) {
      bedtimeMinutes.sort();
      final diff = bedtimeMinutes.last - bedtimeMinutes.first;
      if (diff <= 30) {
        consistencyMsg =
            'Highly Consistent Bedtimes (±15m variance). Great job!';
        consistencyIcon = Icons.check_circle_rounded;
        consistencyColor = const Color(0xFF10B981);
      } else if (diff <= 60) {
        consistencyMsg =
            'Moderate Bedtime Consistency (±30m variance). Try to sleep at same hour.';
        consistencyIcon = Icons.info_outline_rounded;
        consistencyColor = const Color(0xFF6366F1);
      } else {
        consistencyMsg =
            'Highly Variable Bedtimes (±${(diff / 2).round()}m variance). Aligning bedtimes aids sleep quality.';
        consistencyIcon = Icons.warning_amber_rounded;
        consistencyColor = Colors.amber.shade600;
      }
    }

    double totalQuality = 0;
    int qualityDays = 0;
    for (var night in last7Days) {
      if (night.hasData) {
        totalQuality += _qualityScore(night);
        qualityDays++;
      }
    }
    final avgQuality = qualityDays > 0
        ? (totalQuality / qualityDays).round()
        : 0;

    String qualityMsg = 'No sleep quality data available.';
    if (avgQuality >= 85) {
      qualityMsg =
          'Excellent average sleep quality of $avgQuality/100. Superb recovery!';
    } else if (avgQuality >= 70) {
      qualityMsg =
          'Good average sleep quality of $avgQuality/100. Restful recovery.';
    } else if (avgQuality >= 55) {
      qualityMsg =
          'Fair sleep quality of $avgQuality/100. Room for improvement.';
    } else if (avgQuality > 0) {
      qualityMsg =
          'Poor average sleep quality of $avgQuality/100. Prioritize recovery.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Sleep Insights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildWeeklyInsightCard(
          consistencyMsg,
          consistencyIcon,
          consistencyColor,
          isDark,
          textColor,
        ),
        const SizedBox(height: 12),
        _buildWeeklyInsightCard(
          qualityMsg,
          Icons.auto_awesome_rounded,
          const Color(0xFF9333EA),
          isDark,
          textColor,
        ),
      ],
    );
  }

  Widget _buildWeeklyInsightCard(
    String message,
    IconData icon,
    Color color,
    bool isDark,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The shape shared by one sleep session and by a whole day's sessions added
/// together, so quality scoring and the stage bars work on either.
abstract class _SleepStats {
  DateTime get sleepTime;
  DateTime get wakeTime;
  int get totalSleepMinutes;
  int get deepMinutes;
  int get lightMinutes;
  int get remMinutes;
  int get awakeMinutes;

  double get totalHours => totalSleepMinutes / 60;

  bool get hasData => totalSleepMinutes > 0;

  double _safeRatio(int value) {
    if (totalSleepMinutes <= 0) {
      return 0;
    }
    return (value / totalSleepMinutes).clamp(0.0, 1.0);
  }

  double get deepRatio => _safeRatio(deepMinutes);
  double get lightRatio => _safeRatio(lightMinutes);
  double get remRatio => _safeRatio(remMinutes);
  double get awakeRatio => _safeRatio(awakeMinutes);
}

/// One sleep session -- a night or a nap. Sessions are never merged into a
/// daily row: a session is credited to the day it woke up on, so a night from
/// 23:00 to 06:00 belongs to the wake-up date.
class _SleepSession extends _SleepStats {
  final String id;
  final DateTime day;
  @override
  final DateTime sleepTime;
  @override
  final DateTime wakeTime;
  @override
  final int totalSleepMinutes;
  @override
  final int deepMinutes;
  @override
  final int lightMinutes;
  @override
  final int remMinutes;
  @override
  final int awakeMinutes;
  final DateTime createdAt;

  /// Hand-entered sessions can be edited; the ones the band synced cannot.
  final bool isManual;
  final VitalsStreamResponse vital;

  _SleepSession({
    required this.id,
    required this.day,
    required this.sleepTime,
    required this.wakeTime,
    required this.totalSleepMinutes,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.createdAt,
    required this.isManual,
    required this.vital,
  });

  /// A short session reads as a nap rather than a night's sleep.
  bool get isNap => totalSleepMinutes > 0 && totalSleepMinutes < 180;

  static _SleepSession? fromVital(VitalsStreamResponse vital) {
    final payload = vital.data;
    final source = payload is Map<String, dynamic> ? payload['source'] : null;
    final isManual = source == null || source.toString() != 'allowear';

    if (payload is Map<String, dynamic>) {
      try {
        final model = SleepResponseMapModel.fromJson(payload);
        final wake = model.awakeTime;
        final sleep = model.sleepTime;

        var total = model.totalSleepDuration;
        if (total <= 0 && wake.isAfter(sleep)) {
          total = wake.difference(sleep).inMinutes;
        }
        total = math.max(0, total);

        var deep = math.max(0, model.deepSleepDuration);
        var light = math.max(0, model.lightSleepDuration);
        var rem = math.max(0, model.remSleepDuration);
        final awake = math.max(0, model.awakeDuration);

        if (total > 0 && deep == 0 && light == 0 && rem == 0) {
          deep = (total * 0.22).round();
          rem = (total * 0.20).round();
          light = math.max(0, total - deep - rem);
        }

        return _SleepSession(
          id: vital.id,
          day: DateTime(wake.year, wake.month, wake.day),
          sleepTime: sleep,
          wakeTime: wake,
          totalSleepMinutes: total,
          deepMinutes: deep,
          lightMinutes: light,
          remMinutes: rem,
          awakeMinutes: awake,
          createdAt: vital.createdAt,
          isManual: isManual,
          vital: vital,
        );
      } catch (_) {
        // Fallback below.
      }
    }

    // No window in the JSON: the row's timestamp is the wake-up time.
    final fallbackWake = vital.createdAt;
    // Allomom's `sleep` rows hold hours, `sleep_data` rows minutes.
    final fallbackTotal = math.max(
      0,
      SleepUtils.valueMinutes(vital.value, vital.unit),
    );
    if (fallbackTotal <= 0) {
      return null;
    }
    final fallbackSleep = fallbackWake.subtract(
      Duration(minutes: fallbackTotal),
    );
    var deep = (fallbackTotal * 0.22).round();
    var rem = (fallbackTotal * 0.20).round();
    var light = math.max(0, fallbackTotal - deep - rem);

    // Allomom's manual log keeps a deep / light split in hours. A 25% deep
    // share is its default, not a measurement, so only a different split is
    // kept -- as the sleep tile reads it.
    final deepH = _dataNum(payload, 'deepSleep');
    final lightH = _dataNum(payload, 'lightSleep');
    final hours = fallbackTotal / 60.0;
    if (deepH != null &&
        lightH != null &&
        deepH + lightH > 0 &&
        (deepH - hours * 0.25).abs() >= 0.01) {
      deep = (deepH * 60).round();
      light = (lightH * 60).round();
      rem = 0;
    }

    return _SleepSession(
      id: vital.id,
      day: DateTime(fallbackWake.year, fallbackWake.month, fallbackWake.day),
      sleepTime: fallbackSleep,
      wakeTime: fallbackWake,
      totalSleepMinutes: fallbackTotal,
      deepMinutes: deep,
      lightMinutes: light,
      remMinutes: rem,
      awakeMinutes: 0,
      createdAt: vital.createdAt,
      isManual: isManual,
      vital: vital,
    );
  }

  static double? _dataNum(Map<String, dynamic>? data, String field) {
    final raw = data?[field];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }
}

/// Every session of one day added up, for the weekly and history views.
class _SleepNightAggregate extends _SleepStats {
  final DateTime day;
  @override
  final DateTime sleepTime;
  @override
  final DateTime wakeTime;
  @override
  final int totalSleepMinutes;
  @override
  final int deepMinutes;
  @override
  final int lightMinutes;
  @override
  final int remMinutes;
  @override
  final int awakeMinutes;
  final DateTime createdAt;
  final int sessionCount;
  final List<_SleepSession> sessions;

  _SleepNightAggregate({
    required this.day,
    required this.sleepTime,
    required this.wakeTime,
    required this.totalSleepMinutes,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.createdAt,
    this.sessionCount = 0,
    this.sessions = const [],
  });

  factory _SleepNightAggregate.empty(DateTime day) {
    final wake = DateTime(day.year, day.month, day.day, 7, 0);
    final sleep = wake.subtract(const Duration(hours: 8));
    return _SleepNightAggregate(
      day: DateTime(day.year, day.month, day.day),
      sleepTime: sleep,
      wakeTime: wake,
      totalSleepMinutes: 0,
      deepMinutes: 0,
      lightMinutes: 0,
      remMinutes: 0,
      awakeMinutes: 0,
      createdAt: wake,
      sessions: const [],
    );
  }

  factory _SleepNightAggregate.estimated({
    required DateTime day,
    required DateTime sleepTime,
    required DateTime wakeTime,
    required int totalSleepMinutes,
    required DateTime createdAt,
  }) {
    final deep = (totalSleepMinutes * 0.22).round();
    final rem = (totalSleepMinutes * 0.20).round();
    final light = math.max(0, totalSleepMinutes - deep - rem);

    return _SleepNightAggregate(
      day: DateTime(day.year, day.month, day.day),
      sleepTime: sleepTime,
      wakeTime: wakeTime,
      totalSleepMinutes: totalSleepMinutes,
      deepMinutes: deep,
      lightMinutes: light,
      remMinutes: rem,
      awakeMinutes: 0,
      createdAt: createdAt,
      sessionCount: 1,
      sessions: const [],
    );
  }

  /// The day's sessions summed: the bedtime is the earliest one's, the wake
  /// time the latest one's.
  factory _SleepNightAggregate.fromSessions(
    DateTime day,
    List<_SleepSession> sessions,
  ) {
    if (sessions.isEmpty) {
      return _SleepNightAggregate.empty(day);
    }

    final ordered = [...sessions]
      ..sort((a, b) => a.sleepTime.compareTo(b.sleepTime));

    var total = 0;
    var deep = 0;
    var light = 0;
    var rem = 0;
    var awake = 0;
    var latestWake = ordered.first.wakeTime;
    var latestCreatedAt = ordered.first.createdAt;

    for (final session in ordered) {
      total += session.totalSleepMinutes;
      deep += session.deepMinutes;
      light += session.lightMinutes;
      rem += session.remMinutes;
      awake += session.awakeMinutes;

      if (session.wakeTime.isAfter(latestWake)) {
        latestWake = session.wakeTime;
      }
      if (session.createdAt.isAfter(latestCreatedAt)) {
        latestCreatedAt = session.createdAt;
      }
    }

    return _SleepNightAggregate(
      day: DateTime(day.year, day.month, day.day),
      sleepTime: ordered.first.sleepTime,
      wakeTime: latestWake,
      totalSleepMinutes: total,
      deepMinutes: deep,
      lightMinutes: light,
      remMinutes: rem,
      awakeMinutes: awake,
      createdAt: latestCreatedAt,
      sessionCount: ordered.length,
      sessions: ordered,
    );
  }
}

/// One line of advice shown under today's sessions.
class _SleepInsight {
  final String message;
  final IconData icon;
  final Color color;

  const _SleepInsight({
    required this.message,
    required this.icon,
    required this.color,
  });
}

/// AlloConnect's `VitalsEmptyState`: a pulsing icon over a title and subtitle.
class _VitalsEmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;

  const _VitalsEmptyState({
    required this.title,
    required this.subtitle,
    this.icon = Icons.favorite_rounded,
    this.iconColor,
  });

  @override
  State<_VitalsEmptyState> createState() => _VitalsEmptyStateState();
}

class _VitalsEmptyStateState extends State<_VitalsEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final color = widget.iconColor ?? const Color(0xFFFF5252);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(widget.icon, color: color, size: 48),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.5),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
