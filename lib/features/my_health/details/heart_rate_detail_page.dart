import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class HeartRateDetailPage extends StatefulWidget {
  const HeartRateDetailPage({super.key});

  @override
  State<HeartRateDetailPage> createState() => _HeartRateDetailPageState();
}

class _HeartRateDetailPageState extends State<HeartRateDetailPage> {
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
              'Heart Rate',
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
                _buildPeriodTabs(const Color(0xFFFFECEF), const Color(0xFFFF3B5C)),
                const SizedBox(height: 16),

                // ─── MAIN CHART CARD ───
                _buildMainChartCard(),
                const SizedBox(height: 16),

                // ─── 3 BOTTOM STAT CARDS (Average, Lowest, Highest) ───
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
                'Wed, Oct 12',
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
              painter: _DetailedHeartRateChartPainter(),
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
        // Average
        Expanded(
          child: _buildMetricCard(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF3898EC),
            iconBg: const Color(0xFFEDF6FF),
            label: 'Average',
            value: '94',
            unit: 'bpm',
            subtitle: '9 AM - 9 PM',
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
            value: '94',
            unit: 'bpm',
            subtitle: '5:50 AM',
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
            value: '99',
            unit: 'bpm',
            subtitle: '2:10 PM',
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

class _DetailedHeartRateChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 26.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height;

    // Y-Axis Scale Labels on left (120, 90, 60)
    final y120 = TextPainter(text: const TextSpan(text: '120', style: TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y120.paint(canvas, const Offset(0, 10));

    final y90 = TextPainter(text: const TextSpan(text: '90', style: TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y90.paint(canvas, Offset(0, chartHeight * 0.45));

    final y60 = TextPainter(text: const TextSpan(text: '60', style: TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y60.paint(canvas, Offset(0, chartHeight * 0.85));

    // Horizontal grid lines
    final gridPaint = Paint()..color = const Color(0xFFF0F1F5)..strokeWidth = 1.0;
    canvas.drawLine(Offset(leftPadding, 16), Offset(size.width, 16), gridPaint);
    canvas.drawLine(Offset(leftPadding, chartHeight * 0.45 + 6), Offset(size.width, chartHeight * 0.45 + 6), gridPaint);
    canvas.drawLine(Offset(leftPadding, chartHeight * 0.85 + 6), Offset(size.width, chartHeight * 0.85 + 6), gridPaint);

    // Heart Rate Curve
    final path = Path();
    path.moveTo(leftPadding, chartHeight * 0.82);
    path.lineTo(leftPadding + chartWidth * 0.20, chartHeight * 0.82);
    path.cubicTo(
      leftPadding + chartWidth * 0.35, chartHeight * 0.78,
      leftPadding + chartWidth * 0.45, chartHeight * 0.50,
      leftPadding + chartWidth * 0.55, chartHeight * 0.50,
    );
    path.cubicTo(
      leftPadding + chartWidth * 0.65, chartHeight * 0.50,
      leftPadding + chartWidth * 0.72, chartHeight * 0.60,
      leftPadding + chartWidth * 0.80, chartHeight * 0.55,
    );
    path.cubicTo(
      leftPadding + chartWidth * 0.88, chartHeight * 0.50,
      leftPadding + chartWidth * 0.94, chartHeight * 0.22,
      leftPadding + chartWidth * 0.98, chartHeight * 0.22,
    );

    // Gradient Fill Underneath
    final fillPath = Path.from(path)
      ..lineTo(leftPadding + chartWidth * 0.98, chartHeight)
      ..lineTo(leftPadding, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF4E6A).withValues(alpha: 0.18),
          const Color(0xFFFF4E6A).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Pink stroke
    final strokePaint = Paint()
      ..color = const Color(0xFFFF4E6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Peak Indicator Dot
    final peakX = leftPadding + chartWidth * 0.98;
    final peakY = chartHeight * 0.22;
    canvas.drawCircle(Offset(peakX, peakY), 5.5, Paint()..color = const Color(0xFFFF4E6A));
    canvas.drawCircle(Offset(peakX, peakY), 2.5, Paint()..color = Colors.white);

    // Dark Tooltip Badge at x = leftPadding + chartWidth * 0.60
    final tipX = leftPadding + chartWidth * 0.60;
    const tooltipW = 100.0;
    const tooltipH = 26.0;
    final tooltipRect = Rect.fromLTWH(tipX - tooltipW / 2, 4, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(8));
    canvas.drawRRect(tooltipRRect, Paint()..color = const Color(0xFF2D3748));

    // Downward arrow pointer
    final pointer = Path()
      ..moveTo(tipX - 4, tooltipH + 4)
      ..lineTo(tipX, tooltipH + 8)
      ..lineTo(tipX + 4, tooltipH + 4)
      ..close();
    canvas.drawPath(pointer, Paint()..color = const Color(0xFF2D3748));

    final tText = TextPainter(
      text: const TextSpan(
        text: '82 bpm',
        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
        children: [
          TextSpan(text: ' 12:30 PM', style: TextStyle(fontSize: 9, color: Color(0xFFA0AEC0), fontWeight: FontWeight.normal)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tText.paint(canvas, Offset(tooltipRect.left + (tooltipW - tText.width) / 2, tooltipRect.top + 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
