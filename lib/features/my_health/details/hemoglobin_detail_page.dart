import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';

class HemoglobinDetailPage extends StatefulWidget {
  const HemoglobinDetailPage({super.key});

  @override
  State<HemoglobinDetailPage> createState() => _HemoglobinDetailPageState();
}

class _HemoglobinDetailPageState extends State<HemoglobinDetailPage> {
  String _selectedTab = 'Month';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'hemoglobin', lockKey: true);
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
              'Hemoglobin',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFE11D48)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFFE11D48),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Hemoglobin',
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
                      narrationKey: NarrationKeys.pgVitalsHb,
                      bindNarrationText: false,
                      speechText: "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 250,
                      greetingText: "",
                    ),
                    const SizedBox(height: 14),
                    _buildPeriodTabs(const Color(0xFFFFECEF), const Color(0xFFE11D48)),
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
      headerTitle = 'MONTHLY TREND';
      final start = now.subtract(const Duration(days: 28));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
    }

    final history =
        HealthVitalsController.instance.getHistoryForPeriod('hemoglobin', _selectedTab);

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
            accent: const Color(0xFFE11D48),
            unit: 'g/dL',
            decimals: 1,
            minY: 8,
            maxY: 16,
            bands: const [
              VitalBand(min: 11, max: 14, color: Color(0x0A10B981)),
            ],
            emptyTitle: 'No hemoglobin readings',
            emptySubtitle: 'Add your latest lab result to track it',
            series: [
              VitalSeries.fromHistory(
                label: 'Hemoglobin',
                color: const Color(0xFFE11D48),
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
    final hasHb = vitals.hasHemoglobin;
    final periodHistory = vitals.getHistoryForPeriod('hemoglobin', _selectedTab);

    double hb = vitals.hemoglobinValue;
    if (periodHistory.isNotEmpty) {
      if (_selectedTab == 'Day') {
        hb = periodHistory.last.value;
      } else {
        final sum = periodHistory.map((e) => e.value).reduce((a, b) => a + b);
        hb = sum / periodHistory.length;
      }
    }

    final isRecorded = hasHb || periodHistory.isNotEmpty;

    return Row(
      children: [
        // Latest
        Expanded(
          child: _buildMetricCard(
            icon: Icons.bloodtype_rounded,
            iconColor: const Color(0xFFE11D48),
            iconBg: const Color(0xFFFFECEF),
            label: 'Average',
            value: isRecorded ? hb.toStringAsFixed(1) : '--',
            unit: 'g/dL',
            subtitle: 'Target > 10.5',
          ),
        ),
        const SizedBox(width: 10),

        // Status
        Expanded(
          child: _buildMetricCard(
            icon: Icons.verified_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Status',
            value: isRecorded ? (hb >= 11.0 ? 'Normal' : 'Watch') : 'No record',
            unit: '',
            subtitle: isRecorded ? (hb >= 11.0 ? 'Optimal range' : 'Mild watch') : '',
          ),
        ),
        const SizedBox(width: 10),

        // Iron Care
        Expanded(
          child: _buildMetricCard(
            icon: Icons.medication_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            label: 'Iron Care',
            value: 'Daily',
            unit: '',
            subtitle: '1 tab / day',
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
              const SizedBox(width: 5),
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
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E95A5),
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
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF8E95A5),
            ),
          ),
        ],
      ),
    );
  }
}
