import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

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
              'Steps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
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

    final steps = HealthVitalsController.instance.stepsValue;

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
              painter: _StepsChartPainter(
                period: _selectedTab,
                steps: steps,
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E95A5),
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
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepsChartPainter extends CustomPainter {
  final String period;
  final int steps;

  const _StepsChartPainter({
    this.period = 'Day',
    this.steps = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rightPadding = 24.0;
    final chartWidth = size.width - rightPadding;
    final chartHeight = size.height;

    // Y-Axis Scale Labels on right
    final y12k = TextPainter(text: const TextSpan(text: '12k', style: TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y12k.paint(canvas, Offset(chartWidth + 4, 15));

    final y9k = TextPainter(text: const TextSpan(text: '9k', style: TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y9k.paint(canvas, Offset(chartWidth + 4, chartHeight * 0.40));

    final y6k = TextPainter(text: const TextSpan(text: '6k', style: TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y6k.paint(canvas, Offset(chartWidth + 4, chartHeight * 0.70));

    // Horizontal dashed lines
    final dashPaint = Paint()..color = const Color(0xFFF0F1F5)..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, chartHeight * 0.40 + 6), Offset(chartWidth, chartHeight * 0.40 + 6), dashPaint);
    canvas.drawLine(Offset(0, chartHeight * 0.70 + 6), Offset(chartWidth, chartHeight * 0.70 + 6), dashPaint);

    // Step Curve adapts to Day, Week, Month
    final path = Path();
    if (period == 'Day') {
      path.moveTo(0, chartHeight * 0.85);
      path.cubicTo(
        chartWidth * 0.25, chartHeight * 0.80,
        chartWidth * 0.35, chartHeight * 0.72,
        chartWidth * 0.50, chartHeight * 0.60,
      );
      path.cubicTo(
        chartWidth * 0.65, chartHeight * 0.48,
        chartWidth * 0.80, chartHeight * 0.30,
        chartWidth, chartHeight * 0.15,
      );
    } else if (period == 'Week') {
      path.moveTo(0, chartHeight * 0.75);
      path.cubicTo(
        chartWidth * 0.18, chartHeight * 0.45,
        chartWidth * 0.35, chartHeight * 0.65,
        chartWidth * 0.50, chartHeight * 0.35,
      );
      path.cubicTo(
        chartWidth * 0.68, chartHeight * 0.55,
        chartWidth * 0.85, chartHeight * 0.25,
        chartWidth, chartHeight * 0.20,
      );
    } else {
      path.moveTo(0, chartHeight * 0.70);
      path.cubicTo(
        chartWidth * 0.25, chartHeight * 0.60,
        chartWidth * 0.50, chartHeight * 0.45,
        chartWidth * 0.75, chartHeight * 0.35,
      );
      path.cubicTo(
        chartWidth * 0.85, chartHeight * 0.30,
        chartWidth * 0.95, chartHeight * 0.22,
        chartWidth, chartHeight * 0.18,
      );
    }

    // Fill Gradient under curve
    final fillPath = Path.from(path)
      ..lineTo(chartWidth, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.18),
          const Color(0xFF10B981).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Green stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Dotted vertical line
    final dotX = chartWidth * 0.52;
    final dotY = period == 'Day' ? chartHeight * 0.58 : (period == 'Week' ? chartHeight * 0.42 : chartHeight * 0.45);

    final verticalLinePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double curY = dotY;
    while (curY < chartHeight) {
      canvas.drawLine(Offset(dotX, curY), Offset(dotX, curY + 3), verticalLinePaint);
      curY += 6;
    }

    // Dot at current point
    canvas.drawCircle(Offset(dotX, dotY), 4.5, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(Offset(dotX, dotY), 2.0, Paint()..color = Colors.white);

    // Tooltip Card above point
    const tooltipW = 78.0;
    const tooltipH = 50.0;
    final tooltipRect = Rect.fromLTWH(dotX - tooltipW / 2, dotY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.12), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tipTitle = period == 'Day' ? 'Today' : (period == 'Week' ? '7D Avg' : 'Monthly');
    final tTime = TextPainter(
      text: TextSpan(text: tipTitle, style: const TextStyle(fontSize: 9, color: Color(0xFF8E95A5), fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 6));

    final displayStepStr = steps > 0 ? NumberFormat('#,###').format(steps) : '5,680';
    final tVal = TextPainter(
      text: TextSpan(text: displayStepStr, style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E2024), fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tVal.paint(canvas, Offset(tooltipRect.left + (tooltipW - tVal.width) / 2, tooltipRect.top + 18));

    final tUnit = TextPainter(
      text: const TextSpan(text: 'steps', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5))),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tUnit.paint(canvas, Offset(tooltipRect.left + (tooltipW - tUnit.width) / 2, tooltipRect.top + 33));
  }

  @override
  bool shouldRepaint(covariant _StepsChartPainter oldDelegate) =>
      oldDelegate.period != period || oldDelegate.steps != steps;
}
