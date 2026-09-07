import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class BloodPressureDetailPage extends StatefulWidget {
  const BloodPressureDetailPage({super.key});

  @override
  State<BloodPressureDetailPage> createState() => _BloodPressureDetailPageState();
}

class _BloodPressureDetailPageState extends State<BloodPressureDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'blood_pressure', lockKey: true);
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
              'Blood Pressure',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
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
                      speechText: "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 250,
                      greetingText: "",
                    ),
                    const SizedBox(height: 14),
                    _buildPeriodTabs(const Color(0xFFFFF0F4), const Color(0xFFFF4E6A)),
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

    final bpStr = HealthVitalsController.instance.bloodPressureValue;

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
              painter: _BloodPressureChartPainter(
                period: _selectedTab,
                bpStr: bpStr,
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
            iconBg: const Color(0xFFFFF0F4),
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
            iconBg: const Color(0xFFEDF6FF),
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
            iconBg: const Color(0xFFE6F9F0),
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
                  fontSize: 20,
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

class _BloodPressureChartPainter extends CustomPainter {
  final String period;
  final String bpStr;

  const _BloodPressureChartPainter({
    this.period = 'Day',
    this.bpStr = '120/80',
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 26.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height;

    // Y-Axis Scale Labels on left (160, 120, 80, 40)
    final y160 = TextPainter(text: const TextSpan(text: '160', style: TextStyle(fontSize: 9, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y160.paint(canvas, const Offset(0, 10));

    final y120 = TextPainter(text: const TextSpan(text: '120', style: TextStyle(fontSize: 9, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y120.paint(canvas, Offset(0, chartHeight * 0.35));

    final y80 = TextPainter(text: const TextSpan(text: '80', style: TextStyle(fontSize: 9, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y80.paint(canvas, Offset(0, chartHeight * 0.65));

    final y40 = TextPainter(text: const TextSpan(text: '40', style: TextStyle(fontSize: 9, color: Color(0xFFBDC3CE))), textDirection: TextDirection.ltr)..layout();
    y40.paint(canvas, Offset(0, chartHeight * 0.90));

    // Horizontal dashed lines
    final gridPaint = Paint()..color = const Color(0xFFF0F1F5)..strokeWidth = 1.0;
    canvas.drawLine(Offset(leftPadding, 16), Offset(size.width, 16), gridPaint);
    canvas.drawLine(Offset(leftPadding, chartHeight * 0.35 + 6), Offset(size.width, chartHeight * 0.35 + 6), gridPaint);
    canvas.drawLine(Offset(leftPadding, chartHeight * 0.65 + 6), Offset(size.width, chartHeight * 0.65 + 6), gridPaint);

    // Curves adapt to Day / Week / Month
    final sysPath = Path();
    final diaPath = Path();

    if (period == 'Day') {
      sysPath.moveTo(leftPadding, chartHeight * 0.40);
      sysPath.cubicTo(
        leftPadding + chartWidth * 0.25, chartHeight * 0.36,
        leftPadding + chartWidth * 0.50, chartHeight * 0.38,
        leftPadding + chartWidth * 0.75, chartHeight * 0.34,
      );
      sysPath.cubicTo(
        leftPadding + chartWidth * 0.85, chartHeight * 0.34,
        leftPadding + chartWidth * 0.95, chartHeight * 0.38,
        leftPadding + chartWidth, chartHeight * 0.36,
      );

      diaPath.moveTo(leftPadding, chartHeight * 0.70);
      diaPath.cubicTo(
        leftPadding + chartWidth * 0.25, chartHeight * 0.67,
        leftPadding + chartWidth * 0.50, chartHeight * 0.69,
        leftPadding + chartWidth * 0.75, chartHeight * 0.66,
      );
      diaPath.cubicTo(
        leftPadding + chartWidth * 0.85, chartHeight * 0.66,
        leftPadding + chartWidth * 0.95, chartHeight * 0.68,
        leftPadding + chartWidth, chartHeight * 0.67,
      );
    } else if (period == 'Week') {
      sysPath.moveTo(leftPadding, chartHeight * 0.38);
      sysPath.cubicTo(
        leftPadding + chartWidth * 0.20, chartHeight * 0.32,
        leftPadding + chartWidth * 0.45, chartHeight * 0.42,
        leftPadding + chartWidth * 0.70, chartHeight * 0.35,
      );
      sysPath.cubicTo(
        leftPadding + chartWidth * 0.85, chartHeight * 0.30,
        leftPadding + chartWidth * 0.95, chartHeight * 0.36,
        leftPadding + chartWidth, chartHeight * 0.34,
      );

      diaPath.moveTo(leftPadding, chartHeight * 0.68);
      diaPath.cubicTo(
        leftPadding + chartWidth * 0.20, chartHeight * 0.64,
        leftPadding + chartWidth * 0.45, chartHeight * 0.72,
        leftPadding + chartWidth * 0.70, chartHeight * 0.67,
      );
      diaPath.cubicTo(
        leftPadding + chartWidth * 0.85, chartHeight * 0.62,
        leftPadding + chartWidth * 0.95, chartHeight * 0.66,
        leftPadding + chartWidth, chartHeight * 0.65,
      );
    } else {
      sysPath.moveTo(leftPadding, chartHeight * 0.36);
      sysPath.cubicTo(
        leftPadding + chartWidth * 0.30, chartHeight * 0.38,
        leftPadding + chartWidth * 0.60, chartHeight * 0.35,
        leftPadding + chartWidth * 0.85, chartHeight * 0.37,
      );
      sysPath.lineTo(leftPadding + chartWidth, chartHeight * 0.36);

      diaPath.moveTo(leftPadding, chartHeight * 0.67);
      diaPath.cubicTo(
        leftPadding + chartWidth * 0.30, chartHeight * 0.69,
        leftPadding + chartWidth * 0.60, chartHeight * 0.66,
        leftPadding + chartWidth * 0.85, chartHeight * 0.68,
      );
      diaPath.lineTo(leftPadding + chartWidth, chartHeight * 0.67);
    }

    // Shaded Normal Range Band between curves
    final bandPath = Path.from(sysPath);
    bandPath.lineTo(leftPadding + chartWidth, chartHeight * 0.67);
    bandPath.cubicTo(
      leftPadding + chartWidth * 0.95, chartHeight * 0.68,
      leftPadding + chartWidth * 0.85, chartHeight * 0.66,
      leftPadding + chartWidth * 0.75, chartHeight * 0.66,
    );
    bandPath.cubicTo(
      leftPadding + chartWidth * 0.50, chartHeight * 0.69,
      leftPadding + chartWidth * 0.25, chartHeight * 0.67,
      leftPadding, chartHeight * 0.70,
    );
    bandPath.close();

    canvas.drawPath(bandPath, Paint()..color = const Color(0xFFFF4E6A).withValues(alpha: 0.08));

    // Stroke for Systolic (Red)
    canvas.drawPath(
      sysPath,
      Paint()
        ..color = const Color(0xFFFF4E6A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Stroke for Diastolic (Blue)
    canvas.drawPath(
      diaPath,
      Paint()
        ..color = const Color(0xFF3898EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Point indicator
    final dotX = leftPadding + chartWidth * 0.52;
    final sysY = chartHeight * 0.36;
    final diaY = chartHeight * 0.67;

    // Vertical line connecting points
    canvas.drawLine(
      Offset(dotX, sysY),
      Offset(dotX, diaY),
      Paint()..color = const Color(0xFF2D3142).withValues(alpha: 0.3)..strokeWidth = 1.2,
    );

    canvas.drawCircle(Offset(dotX, sysY), 4.5, Paint()..color = const Color(0xFFFF4E6A));
    canvas.drawCircle(Offset(dotX, sysY), 2.0, Paint()..color = Colors.white);

    canvas.drawCircle(Offset(dotX, diaY), 4.5, Paint()..color = const Color(0xFF3898EC));
    canvas.drawCircle(Offset(dotX, diaY), 2.0, Paint()..color = Colors.white);

    // Tooltip Badge
    const tooltipW = 90.0;
    const tooltipH = 46.0;
    final tooltipRect = Rect.fromLTWH(dotX - tooltipW / 2, sysY - tooltipH - 8, tooltipW, tooltipH);

    final tooltipRRect = RRect.fromRectAndRadius(tooltipRect, const Radius.circular(10));
    canvas.drawShadow(Path()..addRRect(tooltipRRect), Colors.black.withValues(alpha: 0.10), 4.0, true);
    canvas.drawRRect(tooltipRRect, Paint()..color = Colors.white);

    final tipTimeStr = period == 'Day' ? 'Today' : (period == 'Week' ? '7D Average' : 'Monthly');
    final tTime = TextPainter(
      text: TextSpan(text: tipTimeStr, style: const TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5), fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tTime.paint(canvas, Offset(tooltipRect.left + (tooltipW - tTime.width) / 2, tooltipRect.top + 4));

    final displayBp = bpStr.isNotEmpty && bpStr != '--' ? bpStr : '118/76';
    final tVal = TextPainter(
      text: TextSpan(text: displayBp, style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E2024), fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tVal.paint(canvas, Offset(tooltipRect.left + (tooltipW - tVal.width) / 2, tooltipRect.top + 17));

    final tSub = TextPainter(
      text: const TextSpan(text: 'Normal', style: TextStyle(fontSize: 8.5, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: tooltipW);
    tSub.paint(canvas, Offset(tooltipRect.left + (tooltipW - tSub.width) / 2, tooltipRect.top + 31));
  }

  @override
  bool shouldRepaint(covariant _BloodPressureChartPainter oldDelegate) =>
      oldDelegate.period != period || oldDelegate.bpStr != bpStr;
}
