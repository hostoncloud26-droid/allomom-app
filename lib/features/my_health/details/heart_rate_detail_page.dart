import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class HeartRateDetailPage extends StatefulWidget {
  const HeartRateDetailPage({super.key});

  @override
  State<HeartRateDetailPage> createState() => _HeartRateDetailPageState();
}

class _HeartRateDetailPageState extends State<HeartRateDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'heart_rate', lockKey: true);
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
              'Heart Rate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFFF3B5C)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B5C),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFFFF3B5C),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Heart Rate',
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
                    _buildPeriodTabs(const Color(0xFFFFECEF), const Color(0xFFFF3B5C)),
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

    final currentHr = HealthVitalsController.instance.hasHeartRate
        ? HealthVitalsController.instance.heartRateValue.toString()
        : '--';

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
              painter: _DetailedHeartRateChartPainter(
                period: _selectedTab,
                currentHr: currentHr,
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
    final hasHr = vitals.hasHeartRate;
    final avg = vitals.getAverageForVitalPeriod('heart_rate', _selectedTab);
    final min = vitals.getMinForVitalPeriod('heart_rate', _selectedTab);
    final max = vitals.getMaxForVitalPeriod('heart_rate', _selectedTab);

    return Row(
      children: [
        // Average
        Expanded(
          child: _buildMetricCard(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF3898EC),
            iconBg: const Color(0xFFEDF6FF),
            label: 'Average',
            value: (hasHr || avg > 0) ? avg.toInt().toString() : '--',
            unit: 'bpm',
            subtitle: (hasHr || avg > 0) ? '$_selectedTab avg' : '',
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
            value: (hasHr || min > 0) ? min.toInt().toString() : '--',
            unit: 'bpm',
            subtitle: (hasHr || min > 0) ? '$_selectedTab min' : '',
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
            value: (hasHr || max > 0) ? max.toInt().toString() : '--',
            unit: 'bpm',
            subtitle: (hasHr || max > 0) ? '$_selectedTab max' : '',
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
  final String period;
  final String currentHr;

  const _DetailedHeartRateChartPainter({
    this.period = 'Day',
    this.currentHr = '--',
  });

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

    // Heart Rate Curve adapts to Day, Week, Month
    final path = Path();
    if (period == 'Day') {
      path.moveTo(leftPadding, chartHeight * 0.80);
      path.lineTo(leftPadding + chartWidth * 0.20, chartHeight * 0.80);
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
    } else if (period == 'Week') {
      // 7-day variation wave
      path.moveTo(leftPadding, chartHeight * 0.65);
      path.cubicTo(
        leftPadding + chartWidth * 0.18, chartHeight * 0.55,
        leftPadding + chartWidth * 0.35, chartHeight * 0.72,
        leftPadding + chartWidth * 0.50, chartHeight * 0.48,
      );
      path.cubicTo(
        leftPadding + chartWidth * 0.68, chartHeight * 0.35,
        leftPadding + chartWidth * 0.82, chartHeight * 0.60,
        leftPadding + chartWidth * 0.98, chartHeight * 0.42,
      );
    } else {
      // Month trend curve
      path.moveTo(leftPadding, chartHeight * 0.70);
      path.cubicTo(
        leftPadding + chartWidth * 0.25, chartHeight * 0.62,
        leftPadding + chartWidth * 0.50, chartHeight * 0.58,
        leftPadding + chartWidth * 0.75, chartHeight * 0.45,
      );
      path.cubicTo(
        leftPadding + chartWidth * 0.88, chartHeight * 0.40,
        leftPadding + chartWidth * 0.94, chartHeight * 0.36,
        leftPadding + chartWidth * 0.98, chartHeight * 0.35,
      );
    }

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

    // Indicator Dot
    final peakX = leftPadding + chartWidth * 0.98;
    final peakY = period == 'Day' ? chartHeight * 0.22 : (period == 'Week' ? chartHeight * 0.42 : chartHeight * 0.35);
    canvas.drawCircle(Offset(peakX, peakY), 5.5, Paint()..color = const Color(0xFFFF4E6A));
    canvas.drawCircle(Offset(peakX, peakY), 2.5, Paint()..color = Colors.white);

    // Tooltip Badge
    final tipX = leftPadding + chartWidth * 0.60;
    const tooltipW = 104.0;
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

    String displayVal = currentHr != '--' ? '$currentHr bpm' : '78 bpm';
    String displaySub = period == 'Day' ? ' • Today' : (period == 'Week' ? ' • 7D Avg' : ' • Monthly');

    final tText = TextPainter(
      text: TextSpan(
        text: displayVal,
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
        children: [
          TextSpan(text: displaySub, style: const TextStyle(fontSize: 8.5, color: Color(0xFFA0AEC0), fontWeight: FontWeight.normal)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tText.paint(canvas, Offset(tooltipRect.left + (tooltipW - tText.width) / 2, tooltipRect.top + 6));
  }

  @override
  bool shouldRepaint(covariant _DetailedHeartRateChartPainter oldDelegate) =>
      oldDelegate.period != period || oldDelegate.currentHr != currentHr;
}
