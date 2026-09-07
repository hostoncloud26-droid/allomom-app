import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class BmiTrackerDetailPage extends StatefulWidget {
  const BmiTrackerDetailPage({super.key});

  @override
  State<BmiTrackerDetailPage> createState() => _BmiTrackerDetailPageState();
}

class _BmiTrackerDetailPageState extends State<BmiTrackerDetailPage> {
  String _selectedTab = 'Month';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'weight', lockKey: true);
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
              'Weight & BMI',
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
              'Log Weight',
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
                    _buildPeriodTabs(const Color(0xFFE6F9F0), const Color(0xFF10B981)),
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
    String dateRangeText;
    List<String> xLabels;
    final now = DateTime.now();

    if (_selectedTab == 'Day') {
      dateRangeText = DateFormat('EEE, dd MMM yyyy').format(now);
      xLabels = ['6 AM', '9 AM', '12 PM', '3 PM', '6 PM', 'Now'];
    } else if (_selectedTab == 'Week') {
      final start = now.subtract(const Duration(days: 6));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
      xLabels = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return i == 6 ? 'Today' : DateFormat('E').format(d);
      });
    } else {
      final start = now.subtract(const Duration(days: 28));
      dateRangeText = '${DateFormat('dd MMM').format(start)} - Today';
      xLabels = ['4 Wks Ago', '3 Wks Ago', '2 Wks Ago', 'Last Wk', 'Today'];
    }

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
                _selectedTab == 'Day' ? 'TODAY\'S LOG' : 'PREGNANCY GAIN',
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
              painter: _BmiWeightChartPainter(
                period: _selectedTab,
                currentWeight: HealthVitalsController.instance.hasWeight
                    ? HealthVitalsController.instance.weightValue.toStringAsFixed(1)
                    : '--',
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
                fontSize: 9.5,
                color: const Color(0xFF8E95A5),
                fontWeight: lbl == 'Today' || lbl == 'Now' ? FontWeight.w700 : FontWeight.w500,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    final vitals = HealthVitalsController.instance;
    final hasWeight = vitals.hasWeight;
    final periodHistory = vitals.getHistoryForPeriod('weight', _selectedTab);

    final wt = hasWeight ? vitals.weightValue.toStringAsFixed(1) : '--';
    final bmi = hasWeight ? vitals.bmiValue.toStringAsFixed(1) : '--';
    String gainSubtitle = hasWeight ? '+0.0 kg period' : 'No records';

    if (periodHistory.length >= 2) {
      final diff = periodHistory.last.value - periodHistory.first.value;
      gainSubtitle = diff >= 0 ? '+${diff.toStringAsFixed(1)} kg period' : '${diff.toStringAsFixed(1)} kg period';
    } else if (hasWeight) {
      final allHistory = vitals.getHistory('weight');
      if (allHistory.length >= 2) {
        final sorted = List<VitalsStreamResponse>.from(allHistory)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final diff = sorted.last.value - sorted.first.value;
        gainSubtitle = diff >= 0 ? '+${diff.toStringAsFixed(1)} kg total' : '${diff.toStringAsFixed(1)} kg total';
      }
    }

    return Row(
      children: [
        // Current Weight
        Expanded(
          child: _buildMetricCard(
            icon: Icons.scale_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFE6F9F0),
            label: 'Weight',
            value: wt,
            unit: 'kg',
            subtitle: gainSubtitle,
          ),
        ),
        const SizedBox(width: 10),

        // BMI
        Expanded(
          child: _buildMetricCard(
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF3898EC),
            iconBg: const Color(0xFFEDF6FF),
            label: 'BMI',
            value: bmi,
            unit: '',
            subtitle: hasWeight ? 'Normal range' : 'Not recorded',
          ),
        ),
        const SizedBox(width: 10),

        // Est Gain
        Expanded(
          child: _buildMetricCard(
            icon: Icons.auto_graph_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF3E8FF),
            label: 'Est. Gain',
            value: '11-15',
            unit: 'kg',
            subtitle: 'On Track',
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
                  fontSize: 18,
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

class _BmiWeightChartPainter extends CustomPainter {
  final String currentWeight;
  final String period;

  const _BmiWeightChartPainter({
    this.currentWeight = '66.5',
    this.period = 'Month',
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rightPadding = 24.0;
    final chartWidth = size.width - rightPadding;
    final chartHeight = size.height;

    // Y-Axis Scale Labels on right (70, 67, 64, 61)
    final scales = ['70', '67', '64', '61'];
    for (int i = 0; i < scales.length; i++) {
      final textP = TextPainter(
        text: TextSpan(text: scales[i], style: const TextStyle(fontSize: 9.5, color: Color(0xFFBDC3CE))),
        textDirection: TextDirection.ltr,
      )..layout();
      textP.paint(canvas, Offset(chartWidth + 4, chartHeight * (i / (scales.length - 1)) * 0.85 + 6));
    }

    // Recommended Healthy Weight Corridor Band (Green Shaded Tunnel)
    final tunnelPath = Path();
    if (period == 'Day') {
      tunnelPath.moveTo(0, chartHeight * 0.30);
      tunnelPath.lineTo(chartWidth, chartHeight * 0.30);
      tunnelPath.lineTo(chartWidth, chartHeight * 0.45);
      tunnelPath.lineTo(0, chartHeight * 0.45);
    } else if (period == 'Week') {
      tunnelPath.moveTo(0, chartHeight * 0.55);
      tunnelPath.lineTo(chartWidth, chartHeight * 0.30);
      tunnelPath.lineTo(chartWidth, chartHeight * 0.45);
      tunnelPath.lineTo(0, chartHeight * 0.65);
    } else {
      tunnelPath.moveTo(0, chartHeight * 0.75);
      tunnelPath.lineTo(chartWidth, chartHeight * 0.30);
      tunnelPath.lineTo(chartWidth, chartHeight * 0.45);
      tunnelPath.lineTo(0, chartHeight * 0.85);
    }
    tunnelPath.close();
    canvas.drawPath(tunnelPath, Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.07));

    // Weight Progression Curve adapts to Day / Week / Month
    final path = Path();
    if (period == 'Day') {
      path.moveTo(0, chartHeight * 0.40);
      path.cubicTo(
        chartWidth * 0.35, chartHeight * 0.42,
        chartWidth * 0.70, chartHeight * 0.37,
        chartWidth, chartHeight * 0.35,
      );
    } else if (period == 'Week') {
      path.moveTo(0, chartHeight * 0.58);
      path.cubicTo(
        chartWidth * 0.30, chartHeight * 0.50,
        chartWidth * 0.65, chartHeight * 0.42,
        chartWidth, chartHeight * 0.35,
      );
    } else {
      path.moveTo(0, chartHeight * 0.80);
      path.cubicTo(
        chartWidth * 0.25, chartHeight * 0.77,
        chartWidth * 0.50, chartHeight * 0.65,
        chartWidth * 0.75, chartHeight * 0.50,
      );
      path.cubicTo(
        chartWidth * 0.85, chartHeight * 0.44,
        chartWidth * 0.95, chartHeight * 0.37,
        chartWidth, chartHeight * 0.35,
      );
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
          const Color(0xFF10B981).withValues(alpha: 0.16),
          const Color(0xFF10B981).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Emerald stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Dotted vertical line at Today (x = chartWidth)
    final dotX = chartWidth;
    final dotY = chartHeight * 0.35;

    final verticalLinePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(dotX, dotY), Offset(dotX, chartHeight), verticalLinePaint);

    // Dot at current point
    canvas.drawCircle(Offset(dotX, dotY), 4.5, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(Offset(dotX, dotY), 2.0, Paint()..color = Colors.white);

    // Tooltip Card
    const tooltipW = 75.0;
    const tooltipH = 48.0;
    final tooltipRect = Rect.fromLTWH(dotX - tooltipW + 4, dotY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.10), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tTime = TextPainter(
      text: const TextSpan(text: 'Today', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5), fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 5));

    final tVal = TextPainter(
      text: TextSpan(text: '$currentWeight kg', style: const TextStyle(fontSize: 12, color: Color(0xFF1E2024), fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tVal.paint(canvas, Offset(tooltipRect.left + (tooltipW - tVal.width) / 2, tooltipRect.top + 18));

    final tSub = TextPainter(
      text: const TextSpan(text: 'Tracking', style: TextStyle(fontSize: 8, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tSub.paint(canvas, Offset(tooltipRect.left + (tooltipW - tSub.width) / 2, tooltipRect.top + 32));
  }

  @override
  bool shouldRepaint(covariant _BmiWeightChartPainter oldDelegate) =>
      oldDelegate.currentWeight != currentWeight || oldDelegate.period != period;
}
