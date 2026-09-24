import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';

class BmiTrackerDetailPage extends StatefulWidget {
  const BmiTrackerDetailPage({super.key});

  @override
  State<BmiTrackerDetailPage> createState() => _BmiTrackerDetailPageState();
}

class _BmiTrackerDetailPageState extends State<BmiTrackerDetailPage> {
  String _selectedTab = 'Month';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'weight', lockKey: true);
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
              'Weight & BMI',
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
              'Log Weight',
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
                    _buildPeriodTabs(const Color(0xFFE6F9F0), const Color(0xFF10B981)),
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
    String dateRangeText;
    final now = DateTime.now();

    if (_selectedTab == 'Day') {
      dateRangeText = DateFormat('EEE, dd MMM yyyy').format(now);
    } else if (_selectedTab == 'Week') {
      final start = now.subtract(const Duration(days: 6));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
    } else {
      final start = now.subtract(const Duration(days: 28));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
    }

    final history =
        HealthVitalsController.instance.getHistoryForPeriod('weight', _selectedTab);

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
                _selectedTab == 'Day' ? 'TODAY\'S LOG' : 'PREGNANCY GAIN',
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
            unit: 'kg',
            decimals: 1,
            emptyTitle: 'No weight entries',
            emptySubtitle: 'Log your weight to track pregnancy gain',
            series: [
              VitalSeries.fromHistory(
                label: 'Weight',
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
    final hasWeight = vitals.hasWeight;
    final periodHistory = vitals.getHistoryForPeriod('weight', _selectedTab);

    final wt = hasWeight ? vitals.weightValue.toStringAsFixed(1) : '--';
    final bmi = hasWeight ? vitals.bmiValue.toStringAsFixed(1) : '--';
    String gainSubtitle = hasWeight ? '+0.0 kg period' : 'No records';

    if (periodHistory.length >= 2) {
      final diff = periodHistory.last.value - periodHistory.first.value;
      gainSubtitle = diff >= 0 ? '+${diff.toStringAsFixed(1)} kg period' : '${diff.toStringAsFixed(1)} kg period';
    } else if (hasWeight) {
      final allHistory = vitals.getHistory('weight');
      if (allHistory.length >= 2) {
        final sorted = List<VitalsStreamResponse>.from(allHistory)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final diff = sorted.last.value - sorted.first.value;
        gainSubtitle = diff >= 0 ? '+${diff.toStringAsFixed(1)} kg total' : '${diff.toStringAsFixed(1)} kg total';
      }
    }

    return Row(
      children: [
        // Current Weight
        Expanded(
          child: _buildMetricCard(
            icon: Icons.scale_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Weight',
            value: wt,
            unit: 'kg',
            subtitle: gainSubtitle,
          ),
        ),
        const SizedBox(width: 10),

        // BMI
        Expanded(
          child: _buildMetricCard(
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF3898EC),
            iconBg: const Color(0xFFEDF6FF),
            label: 'BMI',
            value: bmi,
            unit: '',
            subtitle: hasWeight ? 'Normal range' : 'Not recorded',
          ),
        ),
        const SizedBox(width: 10),

        // Est Gain
        Expanded(
          child: _buildMetricCard(
            icon: Icons.auto_graph_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF3E8FF),
            label: 'Est. Gain',
            value: '11-15',
            unit: 'kg',
            subtitle: 'On Track',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: context.palette.tint(iconColor, iconBg),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 14),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
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
              color: context.palette.pick(const Color(0xFF8E95A5), context.palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
