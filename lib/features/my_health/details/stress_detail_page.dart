import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';

class StressDetailPage extends StatefulWidget {
  const StressDetailPage({super.key});

  @override
  State<StressDetailPage> createState() => _StressDetailPageState();
}

class _StressDetailPageState extends State<StressDetailPage> {
  String _selectedTab = 'Day';

  // Accent colours stay fixed; surfaces and neutral text follow light / dark.
  AppPalette get _p => context.palette;
  Color get _titleColor => _p.pick(const Color(0xFF2D3142), _p.textPrimary);
  Color get _textStrong => _p.pick(const Color(0xFF1E2024), _p.textPrimary);
  Color get _textSoft => _p.pick(const Color(0xFF8E95A5), _p.textMuted);
  Color get _tabInactive => _p.pick(const Color(0xFF6B7280), _p.textSecondary);
  Color get _cardBorder => _p.pick(const Color(0xFFF0F1F5), _p.border);
  Color get _cardShadow =>
      _p.pick(Colors.black.withValues(alpha: 0.03), _p.shadow);

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'stress', lockKey: true);
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
          backgroundColor: _p.scaffoldSoft,
          appBar: AppBar(
            backgroundColor: _p.scaffoldSoft,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _titleColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Stress Load',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _titleColor,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF0284C7)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFF0284C7),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Stress',
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
                    _buildPeriodTabs(_p.tint(const Color(0xFF0284C7), const Color(0xFFE0F2FE)), const Color(0xFF0284C7)),
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
        color: _p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.2),
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
                  color: isSelected ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeText : _tabInactive,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainChartCard() {
    String headerTitle;
    String dateRangeText;
    final now = DateTime.now();

    if (_selectedTab == 'Day') {
      headerTitle = 'TODAY';
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
        HealthVitalsController.instance.getHistoryForPeriod('stress', _selectedTab);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _cardShadow,
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
                  color: _textStrong,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                dateRangeText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          VitalTrendChart(
            period: _selectedTab,
            accent: const Color(0xFF0284C7),
            minY: 0,
            maxY: 100,
            bands: const [
              VitalBand(min: 0, max: 40, color: Color(0x0A10B981)),
            ],
            emptyTitle: 'No stress readings',
            emptySubtitle: 'Sync your Allowear to see stress load',
            series: [
              VitalSeries.fromHistory(
                label: 'Stress',
                color: const Color(0xFF0284C7),
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
    final avg = vitals.getAverageForVitalPeriod('stress', _selectedTab);
    final peak = vitals.getMaxForVitalPeriod('stress', _selectedTab);
    final sleepHours = vitals.sleepHoursValue;

    final isRecorded = avg > 0;
    final score = isRecorded ? avg.toInt() : 0;
    String scoreLevel = 'Low';
    if (score > 70) {
      scoreLevel = 'High';
    } else if (score > 40) {
      scoreLevel = 'Moderate';
    }

    return Row(
      children: [
        // Average
        Expanded(
          child: _buildMetricCard(
            icon: Icons.spa_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBg: _p.tint(const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
            label: 'Average',
            value: isRecorded ? scoreLevel : '--',
            unit: '',
            subtitle: isRecorded ? 'Score: $score' : '',
          ),
        ),
        const SizedBox(width: 10),

        // Peak
        Expanded(
          child: _buildMetricCard(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: _p.tint(const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
            label: 'Peak',
            value: (isRecorded && peak > 0) ? peak.toInt().toString() : (isRecorded ? score.toString() : '--'),
            unit: 'pts',
            subtitle: isRecorded ? '$_selectedTab peak' : '',
          ),
        ),
        const SizedBox(width: 10),

        // Rested
        Expanded(
          child: _buildMetricCard(
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF10B981),
            iconBg: _p.tint(const Color(0xFF10B981), const Color(0xFFE6F9F0)),
            label: 'Rested',
            value: sleepHours > 0 ? sleepHours.toStringAsFixed(1) : '--',
            unit: 'hrs',
            subtitle: sleepHours >= 7 ? 'Managing well' : 'Take rest',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String unit,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _cardShadow,
            blurRadius: 12,
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
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 14),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _textSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textStrong,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSoft,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: _textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
