import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class StepsDetailPage extends StatefulWidget {
  const StepsDetailPage({super.key});

  @override
  State<StepsDetailPage> createState() => _StepsDetailPageState();
}

class _StepsDetailPageState extends State<StepsDetailPage> {
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
              'Steps',
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
                  bubblePosition: SpeechBubblePosition.topCenter,
                  height: 270,
                  greetingText: "",
                ),
                const SizedBox(height: 18),

                // ─── PERIOD TABS (Day / Week / Month) ───
                _buildPeriodTabs(const Color(0xFFD1FAE5), const Color(0xFF10B981)),
                const SizedBox(height: 16),

                // ─── MAIN CHART CARD ───
                _buildMainChartCard(),
                const SizedBox(height: 16),

                // ─── 3 BOTTOM STAT CARDS (Distance, Calories, Active) ───
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
                '26 Aug 2026',
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
              painter: _StepsChartPainter(),
            ),
          ),
          const SizedBox(height: 14),

          // X-Axis Time Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('6 AM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('12 PM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('6 PM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('12 AM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    return Row(
      children: [
        // Distance
        Expanded(
          child: _buildMetricCard(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF3898EC),
            iconBg: const Color(0xFFEDF6FF),
            label: 'Distance',
            value: '6.2',
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
            value: '240',
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
            value: '92',
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

    // Cumulative Step Curve
    final path = Path();
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

    // Dotted vertical line at 12:30 PM (x = chartWidth * 0.52)
    final dotX = chartWidth * 0.52;
    final dotY = chartHeight * 0.58;

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
    const tooltipW = 75.0;
    const tooltipH = 50.0;
    final tooltipRect = Rect.fromLTWH(dotX - tooltipW / 2, dotY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.12), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tTime = TextPainter(
      text: const TextSpan(text: '12:30 PM', style: TextStyle(fontSize: 9, color: Color(0xFF8E95A5), fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 6));

    final tVal = TextPainter(
      text: const TextSpan(text: '5,680', style: TextStyle(fontSize: 13, color: Color(0xFF1E2024), fontWeight: FontWeight.w800)),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
