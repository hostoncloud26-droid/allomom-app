import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';

class StepsDetailPage extends StatefulWidget {
  const StepsDetailPage({super.key});

  @override
  State<StepsDetailPage> createState() => _StepsDetailPageState();
}

class _StepsDetailPageState extends State<StepsDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'steps', lockKey: true);
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
              'Steps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.palette.pick(const Color(0xFF2D3142), context.palette.textPrimary),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF10B981)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFF10B981),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Steps',
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
                    _buildPeriodTabs(const Color(0xFFD1FAE5), const Color(0xFF10B981)),
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
        HealthVitalsController.instance.getHistoryForPeriod('steps', _selectedTab);

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
          const SizedBox(height: 20),

          VitalTrendChart(
            period: _selectedTab,
            accent: const Color(0xFF10B981),
            unit: 'steps',
            bars: true,
            minY: 0,
            emptyTitle: 'No steps recorded',
            emptySubtitle: 'Sync your Allowear or log your walk',
            series: [
              VitalSeries.fromHistory(
                label: 'Steps',
                color: const Color(0xFF10B981),
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
    final periodHistory = vitals.getHistoryForPeriod('steps', _selectedTab);
    int displaySteps = vitals.stepsValue;

    if (periodHistory.isNotEmpty) {
      if (_selectedTab == 'Day') {
        displaySteps = periodHistory.last.value.toInt();
      } else {
        final sum = periodHistory.map((e) => e.value).reduce((a, b) => a + b);
        displaySteps = (sum / periodHistory.length).round();
      }
    }

    final dist = (displaySteps * 0.00075).toStringAsFixed(1);
    final cals = (displaySteps * 0.04).toInt().toString();
    final active = (displaySteps / 100).clamp(0, 300).toInt().toString();

    return Row(
      children: [
        // Distance
        Expanded(
          child: _buildMetricCard(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF3898EC),
            iconBg: const Color(0xFFEDF6FF),
            label: 'Distance',
            value: dist,
            unit: 'km',
          ),
        ),
        const SizedBox(width: 10),

        // Calories
        Expanded(
          child: _buildMetricCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            label: 'Calories',
            value: cals,
            unit: 'kcal',
          ),
        ),
        const SizedBox(width: 10),

        // Active
        Expanded(
          child: _buildMetricCard(
            icon: Icons.timer_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Active',
            value: active,
            unit: 'min',
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.palette.tint(iconColor, iconBg),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 15),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
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
