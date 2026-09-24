import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';

class BloodPressureDetailPage extends StatefulWidget {
  const BloodPressureDetailPage({super.key});

  @override
  State<BloodPressureDetailPage> createState() => _BloodPressureDetailPageState();
}

class _BloodPressureDetailPageState extends State<BloodPressureDetailPage> {
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
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'blood_pressure', lockKey: true);
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
              'Blood Pressure',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _titleColor,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFFF4E6A)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF4E6A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFFFF4E6A),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Blood Pressure',
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
                      narrationKey: NarrationKeys.pgVitalsBp,
                      bindNarrationText: false,
                      speechText: "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 250,
                      greetingText: "",
                    ),
                    const SizedBox(height: 14),
                    _buildPeriodTabs(_p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F4)), const Color(0xFFFF4E6A)),
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

  /// Pulls a number out of a vitals `data` map, which may hold it as a num or
  /// as a string depending on where the reading came from.
  static double? _numOf(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
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
        HealthVitalsController.instance.getHistoryForPeriod('blood_pressure', _selectedTab);

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
            accent: const Color(0xFFFF4E6A),
            unit: 'mmHg',
            minY: 50,
            maxY: 150,
            bands: const [
              VitalBand(min: 70, max: 120, color: Color(0x0A10B981)),
            ],
            emptyTitle: 'No blood pressure readings',
            emptySubtitle: 'Tap "Log Blood Pressure" to add one',
            series: [
              VitalSeries.fromHistory(
                label: 'Systolic',
                color: const Color(0xFFFF4E6A),
                history: history,
                value: (row) =>
                    _numOf(row.data?['systolic']) ?? (row.value > 0 ? row.value : null),
              ),
              VitalSeries.fromHistory(
                label: 'Diastolic',
                color: const Color(0xFF3898EC),
                history: history,
                value: (row) => _numOf(row.data?['diastolic']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    final vitals = HealthVitalsController.instance;
    final hasBp = vitals.hasBloodPressure;
    final periodHistory = vitals.getHistoryForPeriod('blood_pressure', _selectedTab);

    String sys = '--';
    String dia = '--';
    if (periodHistory.isNotEmpty) {
      final latest = periodHistory.last;
      if (latest.data != null && latest.data!['systolic'] != null && latest.data!['diastolic'] != null) {
        sys = latest.data!['systolic'].toString();
        dia = latest.data!['diastolic'].toString();
      } else {
        sys = latest.value.toInt().toString();
        dia = '80';
      }
    } else if (hasBp) {
      final parts = vitals.bloodPressureValue.split('/');
      sys = parts.isNotEmpty ? parts[0] : '--';
      dia = parts.length > 1 ? parts[1] : '--';
    }

    final pulse = vitals.hasHeartRate ? vitals.heartRateValue : '--';

    return Row(
      children: [
        // Systolic
        Expanded(
          child: _buildMetricCard(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFFF4E6A),
            iconBg: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F4)),
            label: 'Systolic',
            value: sys,
            unit: 'mmHg',
            subtitle: 'Target < 120',
          ),
        ),
        const SizedBox(width: 10),

        // Diastolic
        Expanded(
          child: _buildMetricCard(
            icon: Icons.monitor_heart_rounded,
            iconColor: const Color(0xFF3898EC),
            iconBg: _p.tint(const Color(0xFF3898EC), const Color(0xFFEDF6FF)),
            label: 'Diastolic',
            value: dia,
            unit: 'mmHg',
            subtitle: 'Target < 80',
          ),
        ),
        const SizedBox(width: 10),

        // Pulse
        Expanded(
          child: _buildMetricCard(
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: _p.tint(const Color(0xFF10B981), const Color(0xFFE6F9F0)),
            label: 'Pulse',
            value: pulse,
            unit: 'bpm',
            subtitle: 'Heart rate',
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
              const SizedBox(width: 5),
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
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: _textSoft,
                ),
              ),
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
