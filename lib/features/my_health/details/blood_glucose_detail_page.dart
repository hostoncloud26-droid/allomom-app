import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class BloodGlucoseDetailPage extends StatefulWidget {
  const BloodGlucoseDetailPage({super.key});

  @override
  State<BloodGlucoseDetailPage> createState() => _BloodGlucoseDetailPageState();
}

class _BloodGlucoseDetailPageState extends State<BloodGlucoseDetailPage> {
  String _selectedTab = 'Day';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserSessionManager.instance,
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
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── BABY HERO CARD ───
                BabyHeroBanner(
                  speechText: "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                  bubblePosition: SpeechBubblePosition.left,
                  height: 320,
                  greetingText: "",
                ),
                const SizedBox(height: 18),

                // ─── PERIOD TABS (Day / Week / Month) ───
                _buildPeriodTabs(const Color(0xFFFFFBEB), const Color(0xFFD97706)),
                const SizedBox(height: 16),

                // ─── MAIN CHART CARD ───
                _buildMainChartCard(),
                const SizedBox(height: 16),

                // ─── 3 BOTTOM STAT CARDS ───
                _buildBottomStatsRow(),
                const SizedBox(height: 40),
              ],
            ),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '25 Aug 2026',
                style: TextStyle(
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
              painter: _BloodGlucoseChartPainter(),
            ),
          ),
          const SizedBox(height: 14),

          // X-Axis Time Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fast', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Breakf', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Lunch', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Snack', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Dinner', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    return Row(
      children: [
        // Fasting
        Expanded(
          child: _buildMetricCard(
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFFFBEB),
            label: 'Fasting',
            value: '92',
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
            value: '115',
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
            value: '5.2',
            unit: '%',
            subtitle: 'Excellent',
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

    // Glucose Curve
    final path = Path();
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

    // Dotted vertical line at Fasting (x = 0)
    const dotX = 14.0;
    final dotY = chartHeight * 0.60;

    final verticalLinePaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(dotX, dotY), Offset(dotX, chartHeight), verticalLinePaint);

    // Dot at current point
    canvas.drawCircle(Offset(dotX, dotY), 4.5, Paint()..color = const Color(0xFFD97706));
    canvas.drawCircle(Offset(dotX, dotY), 2.0, Paint()..color = Colors.white);

    // Tooltip Card
    const tooltipW = 75.0;
    const tooltipH = 48.0;
    final tooltipRect = Rect.fromLTWH(dotX - 10, dotY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.10), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tTime = TextPainter(
      text: const TextSpan(text: 'Fasting', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5), fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 5));

    final tVal = TextPainter(
      text: const TextSpan(text: '92 mg/dL', style: TextStyle(fontSize: 11.5, color: Color(0xFF1E2024), fontWeight: FontWeight.w800)),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
