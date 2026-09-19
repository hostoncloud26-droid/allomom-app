import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';

class HrvDetailPage extends StatefulWidget {
  const HrvDetailPage({super.key});

  @override
  State<HrvDetailPage> createState() => _HrvDetailPageState();
}

class _HrvDetailPageState extends State<HrvDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'hrv', lockKey: true);
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
          backgroundColor: const Color(0xFFFBFBFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBFBFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF2D3142),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'HRV',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
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
              'Log HRV',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
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
                    color: isSelected ? activeText : const Color(0xFF6B7280),
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
        HealthVitalsController.instance.getHistoryForPeriod('hrv', _selectedTab);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                dateRangeText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          VitalTrendChart(
            period: _selectedTab,
            accent: const Color(0xFF8B5CF6),
            unit: 'ms',
            minY: 20,
            maxY: 80,
            emptyTitle: 'No HRV readings',
            emptySubtitle: 'Sync your Allowear to see recovery trends',
            series: [
              VitalSeries.fromHistory(
                label: 'HRV',
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
    final avg = vitals.getAverageForVitalPeriod('hrv', _selectedTab);
    final min = vitals.getMinForVitalPeriod('hrv', _selectedTab);
    final max = vitals.getMaxForVitalPeriod('hrv', _selectedTab);

    return Row(
      children: [
        // Average
        Expanded(
          child: _buildMetricCard(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF3E8FF),
            label: 'Average',
            value: avg > 0 ? avg.toInt().toString() : '--',
            unit: 'ms',
            subtitle: avg > 0 ? '$_selectedTab avg' : '',
          ),
        ),
        const SizedBox(width: 10),

        // Lowest
        Expanded(
          child: _buildMetricCard(
            icon: Icons.arrow_downward_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Lowest',
            value: min > 0 ? min.toInt().toString() : '--',
            unit: 'ms',
            subtitle: min > 0 ? '$_selectedTab min' : '',
          ),
        ),
        const SizedBox(width: 10),

        // Highest
        Expanded(
          child: _buildMetricCard(
            icon: Icons.arrow_upward_rounded,
            iconColor: const Color(0xFFFF4E6A),
            iconBg: const Color(0xFFFFF0F4),
            label: 'Highest',
            value: max > 0 ? max.toInt().toString() : '--',
            unit: 'ms',
            subtitle: max > 0 ? '$_selectedTab max' : '',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E95A5),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: Color(0xFF8E95A5),
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
