import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';

class SleepDetailPage extends StatefulWidget {
  const SleepDetailPage({super.key});

  @override
  State<SleepDetailPage> createState() => _SleepDetailPageState();
}

class _SleepDetailPageState extends State<SleepDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'sleep', lockKey: true);
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([MainController.instance, HealthVitalsController.instance]),
      builder: (context, child) {
        final session = MainController.instance;
        final week = session.currentGestationalWeek;

        return Scaffold(
          backgroundColor: context.palette.pick(const Color(0xFFFBFBFC), context.palette.scaffoldSoft),
          appBar: AppBar(
            backgroundColor: context.palette.pick(const Color(0xFFFBFBFC), context.palette.scaffoldSoft),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: context.palette.pick(const Color(0xFF2D3142), context.palette.textPrimary),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Sleep',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.palette.pick(const Color(0xFF2D3142), context.palette.textPrimary),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF8B5CF6)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFF8B5CF6),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Sleep',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── FIXED TOP SECTION (Baby Hero Card & Period Tabs) ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Column(
                  children: [
                    BabyHeroBanner(
                      speechText: "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 250,
                      greetingText: "",
                    ),
                    const SizedBox(height: 14),
                    _buildPeriodTabs(const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ─── SCROLLABLE BOTTOM SECTION (After the tab) ───
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainChartCard(),
                      const SizedBox(height: 16),
                      _buildBottomStatsRow(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodTabs(Color activeBg, Color activeText) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.pick(const Color(0xFFF0F1F5), context.palette.border), width: 1.2),
      ),
      child: Row(
        children: ['Day', 'Week', 'Month'].map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? context.palette.tint(activeText, activeBg) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeText : context.palette.pick(const Color(0xFF6B7280), context.palette.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Renders decimal hours the way a night's sleep is read: `7h 20m`.
  static String _formatSleep(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Widget _buildMainChartCard() {
    String headerTitle;
    String dateRangeText;
    final now = DateTime.now();

    if (_selectedTab == 'Day') {
      headerTitle = 'LAST NIGHT';
      dateRangeText = DateFormat('EEE, dd MMM yyyy').format(now);
    } else if (_selectedTab == 'Week') {
      headerTitle = 'THIS WEEK';
      final start = now.subtract(const Duration(days: 6));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
    } else {
      headerTitle = 'THIS MONTH';
      final start = now.subtract(const Duration(days: 28));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
    }

    final history =
        HealthVitalsController.instance.getHistoryForPeriod('sleep', _selectedTab);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.palette.pick(const Color(0xFFF0F1F5), context.palette.border), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.palette.pick(Colors.black.withValues(alpha: 0.03), context.palette.shadow),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                headerTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                dateRangeText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          VitalTrendChart(
            period: _selectedTab,
            accent: const Color(0xFF8B5CF6),
            unit: 'hrs',
            decimals: 1,
            bars: true,
            minY: 0,
            maxY: 10,
            valueFormatter: _formatSleep,
            emptyTitle: 'No sleep recorded',
            emptySubtitle: 'Log a night to see your sleep trend',
            series: [
              VitalSeries.fromHistory(
                label: 'Sleep',
                color: const Color(0xFF8B5CF6),
                history: history,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    final vitals = HealthVitalsController.instance;
    final hasSleep = vitals.hasSleep;
    final periodHistory = vitals.getHistoryForPeriod('sleep', _selectedTab);

    double sleepHours = vitals.sleepHoursValue;
    if (periodHistory.isNotEmpty) {
      if (_selectedTab == 'Day') {
        sleepHours = periodHistory.last.value;
      } else {
        final sum = periodHistory.map((e) => e.value).reduce((a, b) => a + b);
        sleepHours = sum / periodHistory.length;
      }
    }

    final isRecorded = hasSleep || periodHistory.isNotEmpty;
    final totalH = sleepHours.toInt();
    final totalM = ((sleepHours - totalH) * 60).round();
    final deepRatio = sleepHours >= 7.0 ? 0.35 : 0.25;
    final deepTotalM = (sleepHours * 60 * deepRatio).round();
    final deepH = deepTotalM ~/ 60;
    final deepM = deepTotalM % 60;
    final lightTotalM = (sleepHours * 60 * (1 - deepRatio)).round();
    final lightH = lightTotalM ~/ 60;
    final lightM = lightTotalM % 60;

    return Row(
      children: [
        // Total Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: _selectedTab == 'Day' ? 'Total Sleep' : 'Avg Sleep',
            hours: isRecorded ? '$totalH' : '--',
            minutes: isRecorded ? '$totalM' : '--',
          ),
        ),
        const SizedBox(width: 10),

        // Deep Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: 'Deep Sleep',
            hours: isRecorded ? '$deepH' : '--',
            minutes: isRecorded ? '$deepM' : '--',
          ),
        ),
        const SizedBox(width: 10),

        // Light Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: 'Light Sleep',
            hours: isRecorded ? '$lightH' : '--',
            minutes: isRecorded ? '$lightM' : '--',
          ),
        ),
      ],
    );
  }

  Widget _buildSleepMetricCard({
    required String label,
    required String hours,
    required String minutes,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.palette.pick(const Color(0xFFF0F1F5), context.palette.border), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.palette.pick(Colors.black.withValues(alpha: 0.03), context.palette.shadow),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hours,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary),
                ),
              ),
              Text(
                'h ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
                ),
              ),
              Text(
                minutes,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary),
                ),
              ),
              Text(
                'm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
