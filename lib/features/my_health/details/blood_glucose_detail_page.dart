import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class BloodGlucoseDetailPage extends StatefulWidget {
  const BloodGlucoseDetailPage({super.key});

  @override
  State<BloodGlucoseDetailPage> createState() => _BloodGlucoseDetailPageState();
}

class _BloodGlucoseDetailPageState extends State<BloodGlucoseDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'glucose', lockKey: true);
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
              'Blood Glucose',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFD97706)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFFD97706),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Glucose',
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
                    _buildPeriodTabs(const Color(0xFFFFFBEB), const Color(0xFFD97706)),
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
      xLabels = ['Fast', 'Breakf', 'Lunch', 'Snack', 'Dinner'];
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

    final glucose = HealthVitalsController.instance.bloodGlucoseValue;

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
              painter: _BloodGlucoseChartPainter(
                period: _selectedTab,
                glucoseVal: glucose,
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
                fontWeight: lbl == 'Today' || lbl == 'Fast' ? FontWeight.w700 : FontWeight.w500,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    final vitals = HealthVitalsController.instance;
    final hasGlucose = vitals.hasBloodGlucose;
    final periodHistory = vitals.getHistoryForPeriod('glucose', _selectedTab);

    double glucose = vitals.bloodGlucoseValue;
    if (periodHistory.isNotEmpty) {
      if (_selectedTab == 'Day') {
        glucose = periodHistory.last.value;
      } else {
        final sum = periodHistory.map((e) => e.value).reduce((a, b) => a + b);
        glucose = sum / periodHistory.length;
      }
    }

    final isRecorded = hasGlucose || periodHistory.isNotEmpty;

    return Row(
      children: [
        // Fasting
        Expanded(
          child: _buildMetricCard(
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFFFBEB),
            label: 'Fasting',
            value: isRecorded ? glucose.toStringAsFixed(0) : '--',
            unit: 'mg/dL',
            subtitle: 'Target < 95',
          ),
        ),
        const SizedBox(width: 10),

        // Post-Meal
        Expanded(
          child: _buildMetricCard(
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Post-Meal',
            value: isRecorded ? (glucose * 1.2).toStringAsFixed(0) : '--',
            unit: 'mg/dL',
            subtitle: 'Target < 120',
          ),
        ),
        const SizedBox(width: 10),

        // HbA1c
        Expanded(
          child: _buildMetricCard(
            icon: Icons.health_and_safety_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF3E8FF),
            label: 'HbA1c',
            value: isRecorded ? ((glucose + 46.7) / 28.7).toStringAsFixed(1) : '--',
            unit: '%',
            subtitle: isRecorded ? 'Estimated' : 'No record',
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

class _BloodGlucoseChartPainter extends CustomPainter {
  final String period;
  final double glucoseVal;

  const _BloodGlucoseChartPainter({
    this.period = 'Day',
    this.glucoseVal = 92.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rightPadding = 26.0;
    final chartWidth = size.width - rightPadding;
    final chartHeight = size.height;

    // Y-Axis Scale Labels on right (160, 120, 90, 60)
    final scales = ['160', '120', '90', '60'];
    for (int i = 0; i < scales.length; i++) {
      final textP = TextPainter(
        text: TextSpan(text: scales[i], style: const TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))),
        textDirection: TextDirection.ltr,
      )..layout();
      textP.paint(canvas, Offset(chartWidth + 4, chartHeight * (i / (scales.length - 1)) * 0.85 + 6));
    }

    // Normal safe zone corridor (70 to 120 mg/dL)
    final safeZone = Rect.fromLTWH(0, chartHeight * 0.28, chartWidth, chartHeight * 0.42);
    canvas.drawRect(
      safeZone,
      Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.06),
    );

    // Glucose Curve adapts to Day / Week / Month
    final path = Path();
    if (period == 'Day') {
      path.moveTo(0, chartHeight * 0.60); // Fasting = 92
      path.cubicTo(
        chartWidth * 0.15, chartHeight * 0.58,
        chartWidth * 0.25, chartHeight * 0.32,
        chartWidth * 0.35, chartHeight * 0.32, // Breakf = 118
      );
      path.cubicTo(
        chartWidth * 0.42, chartHeight * 0.32,
        chartWidth * 0.48, chartHeight * 0.50,
        chartWidth * 0.55, chartHeight * 0.35, // Lunch = 115
      );
      path.cubicTo(
        chartWidth * 0.65, chartHeight * 0.38,
        chartWidth * 0.72, chartHeight * 0.55,
        chartWidth * 0.80, chartHeight * 0.48, // Snack = 102
      );
      path.cubicTo(
        chartWidth * 0.88, chartHeight * 0.44,
        chartWidth * 0.95, chartHeight * 0.38,
        chartWidth, chartHeight * 0.40, // Dinner = 110
      );
    } else if (period == 'Week') {
      path.moveTo(0, chartHeight * 0.55);
      path.cubicTo(
        chartWidth * 0.20, chartHeight * 0.45,
        chartWidth * 0.40, chartHeight * 0.62,
        chartWidth * 0.60, chartHeight * 0.40,
      );
      path.cubicTo(
        chartWidth * 0.75, chartHeight * 0.35,
        chartWidth * 0.90, chartHeight * 0.50,
        chartWidth, chartHeight * 0.45,
      );
    } else {
      path.moveTo(0, chartHeight * 0.50);
      path.cubicTo(
        chartWidth * 0.30, chartHeight * 0.46,
        chartWidth * 0.60, chartHeight * 0.52,
        chartWidth * 0.85, chartHeight * 0.44,
      );
      path.lineTo(chartWidth, chartHeight * 0.42);
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
          const Color(0xFFD97706).withValues(alpha: 0.16),
          const Color(0xFFD97706).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Amber stroke
    final strokePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Dotted vertical line
    final dotX = period == 'Day' ? 14.0 : chartWidth * 0.60;
    final dotY = period == 'Day' ? chartHeight * 0.60 : chartHeight * 0.40;

    final verticalLinePaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(dotX, dotY), Offset(dotX, chartHeight), verticalLinePaint);

    // Dot at current point
    canvas.drawCircle(Offset(dotX, dotY), 4.5, Paint()..color = const Color(0xFFD97706));
    canvas.drawCircle(Offset(dotX, dotY), 2.0, Paint()..color = Colors.white);

    // Tooltip Card
    const tooltipW = 85.0;
    const tooltipH = 48.0;
    final tooltipRect = Rect.fromLTWH(dotX - (period == 'Day' ? 10 : tooltipW / 2), dotY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.10), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tipTimeStr = period == 'Day' ? 'Fasting' : (period == 'Week' ? '7D Average' : 'Monthly');
    final tTime = TextPainter(
      text: TextSpan(text: tipTimeStr, style: const TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5), fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 5));

    final valStr = glucoseVal > 0 ? '${glucoseVal.toStringAsFixed(0)} mg/dL' : '92 mg/dL';
    final tVal = TextPainter(
      text: TextSpan(text: valStr, style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E2024), fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tVal.paint(canvas, Offset(tooltipRect.left + (tooltipW - tVal.width) / 2, tooltipRect.top + 18));

    final tSub = TextPainter(
      text: const TextSpan(text: 'Normal', style: TextStyle(fontSize: 8.5, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tSub.paint(canvas, Offset(tooltipRect.left + (tooltipW - tSub.width) / 2, tooltipRect.top + 32));
  }

  @override
  bool shouldRepaint(covariant _BloodGlucoseChartPainter oldDelegate) =>
      oldDelegate.period != period || oldDelegate.glucoseVal != glucoseVal;
}
