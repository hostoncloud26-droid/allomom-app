import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class StressDetailPage extends StatefulWidget {
  const StressDetailPage({super.key});

  @override
  State<StressDetailPage> createState() => _StressDetailPageState();
}

class _StressDetailPageState extends State<StressDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'stress', lockKey: true);
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([UserSessionManager.instance, HealthVitalsController.instance]),
      builder: (context, child) {
        final session = UserSessionManager.instance;
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
              'Stress Load',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
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
                    _buildPeriodTabs(const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
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
    List<String> xLabels;
    final now = DateTime.now();

    if (_selectedTab == 'Day') {
      headerTitle = 'TODAY';
      dateRangeText = DateFormat('EEE, dd MMM yyyy').format(now);
      xLabels = ['12 AM', '6 AM', '12 PM', '6 PM', '12 AM'];
    } else if (_selectedTab == 'Week') {
      headerTitle = 'THIS WEEK';
      final start = now.subtract(const Duration(days: 6));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
      xLabels = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return i == 6 ? 'Today' : DateFormat('E').format(d);
      });
    } else {
      headerTitle = 'THIS MONTH';
      final start = now.subtract(const Duration(days: 28));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
      xLabels = ['W1', 'W2', 'W3', 'W4', 'Today'];
    }

    final stressVal = HealthVitalsController.instance.stressVital?.value.toInt() ?? 24;

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

          // Chart Graphic
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _StressChartPainter(
                period: _selectedTab,
                stressScore: stressVal,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // X-Axis Time Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: xLabels.map((lbl) => Text(
              lbl,
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFF8E95A5),
                fontWeight: lbl == 'Today' ? FontWeight.w700 : FontWeight.w500,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    final vitals = HealthVitalsController.instance;
    final hasStress = vitals.hasStress;
    final avg = vitals.getAverageForVitalPeriod('stress', _selectedTab);
    final peak = vitals.getMaxForVitalPeriod('stress', _selectedTab);
    final sleepHours = vitals.sleepHoursValue;

    final isRecorded = hasStress || avg > 0;
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
            iconBg: const Color(0xFFE0F2FE),
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
            iconBg: const Color(0xFFFEF3C7),
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
            iconBg: const Color(0xFFE6F9F0),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                ),
              ),
              if (unit.isNotEmpty) ...[
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

class _StressChartPainter extends CustomPainter {
  final String period;
  final int stressScore;

  const _StressChartPainter({
    this.period = 'Day',
    this.stressScore = 24,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rightPadding = 28.0;
    final chartWidth = size.width - rightPadding;
    final chartHeight = size.height;

    // Y-Axis Scale Labels on right (High, Mod, Low, Rest)
    final scales = ['High', 'Mod', 'Low', 'Rest'];
    for (int i = 0; i < scales.length; i++) {
      final textP = TextPainter(
        text: TextSpan(text: scales[i], style: const TextStyle(fontSize: 8.5, color: Color(0xFFBDC3CE))),
        textDirection: TextDirection.ltr,
      )..layout();
      textP.paint(canvas, Offset(chartWidth + 4, chartHeight * (i / (scales.length - 1)) * 0.85 + 6));
    }

    // Stress Curve adapts to Day, Week, Month
    final path = Path();
    if (period == 'Day') {
      path.moveTo(0, chartHeight * 0.78);
      path.cubicTo(
        chartWidth * 0.20, chartHeight * 0.75,
        chartWidth * 0.35, chartHeight * 0.65,
        chartWidth * 0.52, chartHeight * 0.62,
      );
      path.cubicTo(
        chartWidth * 0.65, chartHeight * 0.58,
        chartWidth * 0.75, chartHeight * 0.40,
        chartWidth * 0.85, chartHeight * 0.45,
      );
      path.cubicTo(
        chartWidth * 0.92, chartHeight * 0.50,
        chartWidth * 0.98, chartHeight * 0.70,
        chartWidth, chartHeight * 0.72,
      );
    } else if (period == 'Week') {
      path.moveTo(0, chartHeight * 0.65);
      path.cubicTo(
        chartWidth * 0.25, chartHeight * 0.55,
        chartWidth * 0.50, chartHeight * 0.72,
        chartWidth * 0.75, chartHeight * 0.48,
      );
      path.cubicTo(
        chartWidth * 0.88, chartHeight * 0.50,
        chartWidth * 0.95, chartHeight * 0.62,
        chartWidth, chartHeight * 0.60,
      );
    } else {
      path.moveTo(0, chartHeight * 0.60);
      path.cubicTo(
        chartWidth * 0.30, chartHeight * 0.65,
        chartWidth * 0.60, chartHeight * 0.55,
        chartWidth * 0.85, chartHeight * 0.62,
      );
      path.lineTo(chartWidth, chartHeight * 0.58);
    }

    // Fill Gradient
    final fillPath = Path.from(path)
      ..lineTo(chartWidth, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.18),
          const Color(0xFF0284C7).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Cyan/Blue stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Dotted vertical line
    final dotX = chartWidth * 0.52;
    final dotY = period == 'Day' ? chartHeight * 0.62 : (period == 'Week' ? chartHeight * 0.72 : chartHeight * 0.58);

    final verticalLinePaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(dotX, dotY), Offset(dotX, chartHeight), verticalLinePaint);

    // Dot at current point
    canvas.drawCircle(Offset(dotX, dotY), 4.5, Paint()..color = const Color(0xFF0284C7));
    canvas.drawCircle(Offset(dotX, dotY), 2.0, Paint()..color = Colors.white);

    // Tooltip Card
    const tooltipW = 75.0;
    const tooltipH = 46.0;
    final tooltipRect = Rect.fromLTWH(dotX - tooltipW / 2, dotY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.10), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tipTimeStr = period == 'Day' ? 'Today' : (period == 'Week' ? '7D Avg' : 'Monthly');
    final tTime = TextPainter(
      text: TextSpan(text: tipTimeStr, style: const TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5), fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 5));

    final scoreLevel = stressScore > 70 ? 'High' : (stressScore > 40 ? 'Mod' : 'Low');
    final scoreColor = stressScore > 70 ? const Color(0xFFFF4E6A) : (stressScore > 40 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    final tVal = TextPainter(
      text: TextSpan(text: scoreLevel, style: TextStyle(fontSize: 13, color: scoreColor, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tVal.paint(canvas, Offset(tooltipRect.left + (tooltipW - tVal.width) / 2, tooltipRect.top + 18));

    final tSub = TextPainter(
      text: TextSpan(text: '$stressScore score', style: const TextStyle(fontSize: 8, color: Color(0xFF8E95A5))),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tSub.paint(canvas, Offset(tooltipRect.left + (tooltipW - tSub.width) / 2, tooltipRect.top + 32));
  }

  @override
  bool shouldRepaint(covariant _StressChartPainter oldDelegate) =>
      oldDelegate.period != period || oldDelegate.stressScore != stressScore;
}
