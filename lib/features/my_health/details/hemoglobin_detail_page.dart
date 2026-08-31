import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class HemoglobinDetailPage extends StatefulWidget {
  const HemoglobinDetailPage({super.key});

  @override
  State<HemoglobinDetailPage> createState() => _HemoglobinDetailPageState();
}

class _HemoglobinDetailPageState extends State<HemoglobinDetailPage> {
  String _selectedTab = 'Month';

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
              'Hemoglobin',
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
                _buildPeriodTabs(const Color(0xFFFFECEF), const Color(0xFFE11D48)),
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
                'LATEST TEST',
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
              painter: _HemoglobinChartPainter(),
            ),
          ),
          const SizedBox(height: 14),

          // X-Axis Time Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('May', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Jun', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Jul', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Aug', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('Sep', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    return Row(
      children: [
        // Latest
        Expanded(
          child: _buildMetricCard(
            icon: Icons.bloodtype_rounded,
            iconColor: const Color(0xFFE11D48),
            iconBg: const Color(0xFFFFECEF),
            label: 'Latest',
            value: '10.8',
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
            value: 'Normal',
            unit: '',
            subtitle: 'Mild watch',
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

class _HemoglobinChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const rightPadding = 24.0;
    final chartWidth = size.width - rightPadding;
    final chartHeight = size.height;

    // Y-Axis Scale Labels on right (14, 12, 10, 8)
    final scales = ['14', '12', '10', '8'];
    for (int i = 0; i < scales.length; i++) {
      final textP = TextPainter(
        text: TextSpan(text: scales[i], style: const TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))),
        textDirection: TextDirection.ltr,
      )..layout();
      textP.paint(canvas, Offset(chartWidth + 4, chartHeight * (i / (scales.length - 1)) * 0.85 + 6));
    }

    // Normal safe zone corridor (10.5 to 13.0 g/dL)
    final safeZone = Rect.fromLTWH(0, chartHeight * 0.18, chartWidth, chartHeight * 0.45);
    canvas.drawRect(
      safeZone,
      Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.06),
    );

    // Hb Trend Curve
    final path = Path();
    path.moveTo(0, chartHeight * 0.35);
    path.cubicTo(
      chartWidth * 0.25, chartHeight * 0.37,
      chartWidth * 0.50, chartHeight * 0.45,
      chartWidth * 0.75, chartHeight * 0.50,
    );
    path.cubicTo(
      chartWidth * 0.85, chartHeight * 0.51,
      chartWidth * 0.95, chartHeight * 0.53,
      chartWidth, chartHeight * 0.54,
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
          const Color(0xFFE11D48).withValues(alpha: 0.16),
          const Color(0xFFE11D48).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Crimson stroke
    final strokePaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Dotted vertical line at Aug (x = chartWidth * 0.75)
    final dotX = chartWidth * 0.75;
    final dotY = chartHeight * 0.50;

    final verticalLinePaint = Paint()
      ..color = const Color(0xFFE11D48).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(dotX, dotY), Offset(dotX, chartHeight), verticalLinePaint);

    // Dot at current point
    canvas.drawCircle(Offset(dotX, dotY), 4.5, Paint()..color = const Color(0xFFE11D48));
    canvas.drawCircle(Offset(dotX, dotY), 2.0, Paint()..color = Colors.white);

    // Tooltip Card
    const tooltipW = 75.0;
    const tooltipH = 48.0;
    final tooltipRect = Rect.fromLTWH(dotX - tooltipW / 2, dotY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.10), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tTime = TextPainter(
      text: const TextSpan(text: '26 Aug', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5), fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 5));

    final tVal = TextPainter(
      text: const TextSpan(text: '10.8 g/dL', style: TextStyle(fontSize: 11.5, color: Color(0xFF1E2024), fontWeight: FontWeight.w800)),
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
