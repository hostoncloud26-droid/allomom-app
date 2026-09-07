import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class SleepDetailPage extends StatefulWidget {
  const SleepDetailPage({super.key});

  @override
  State<SleepDetailPage> createState() => _SleepDetailPageState();
}

class _SleepDetailPageState extends State<SleepDetailPage> {
  String _selectedTab = 'Day';

  void _openLogSheet() async {
    final updated = await VitalLogBottomSheet.show(context, initialKey: 'sleep', lockKey: true);
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
              'Sleep',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3142),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _openLogSheet,
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF8B5CF6)),
                label: const Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLogSheet,
            backgroundColor: const Color(0xFF8B5CF6),
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Log Sleep',
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
                    _buildPeriodTabs(const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
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
      headerTitle = 'LAST NIGHT';
      dateRangeText = DateFormat('EEE, dd MMM yyyy').format(now);
      xLabels = ['10 PM', '1 AM', '4 AM', '7 AM'];
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

    final sleepHours = HealthVitalsController.instance.sleepHoursValue;

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
          const SizedBox(height: 24),

          // Sleep Hypnogram Visual Timeline
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _DetailedSleepHypnogramPainter(
                period: _selectedTab,
                sleepHours: sleepHours,
              ),
            ),
          ),
          const SizedBox(height: 16),

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
    final hasSleep = vitals.hasSleep;
    final periodHistory = vitals.getHistoryForPeriod('sleep', _selectedTab);

    double sleepHours = vitals.sleepHoursValue;
    if (periodHistory.isNotEmpty) {
      if (_selectedTab == 'Day') {
        sleepHours = periodHistory.last.value;
      } else {
        final sum = periodHistory.map((e) => e.value).reduce((a, b) => a + b);
        sleepHours = sum / periodHistory.length;
      }
    }

    final isRecorded = hasSleep || periodHistory.isNotEmpty;
    final totalH = sleepHours.toInt();
    final totalM = ((sleepHours - totalH) * 60).round();
    final deepRatio = sleepHours >= 7.0 ? 0.35 : 0.25;
    final deepTotalM = (sleepHours * 60 * deepRatio).round();
    final deepH = deepTotalM ~/ 60;
    final deepM = deepTotalM % 60;
    final lightTotalM = (sleepHours * 60 * (1 - deepRatio)).round();
    final lightH = lightTotalM ~/ 60;
    final lightM = lightTotalM % 60;

    return Row(
      children: [
        // Total Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: _selectedTab == 'Day' ? 'Total Sleep' : 'Avg Sleep',
            hours: isRecorded ? '$totalH' : '--',
            minutes: isRecorded ? '$totalM' : '--',
          ),
        ),
        const SizedBox(width: 10),

        // Deep Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: 'Deep Sleep',
            hours: isRecorded ? '$deepH' : '--',
            minutes: isRecorded ? '$deepM' : '--',
          ),
        ),
        const SizedBox(width: 10),

        // Light Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: 'Light Sleep',
            hours: isRecorded ? '$lightH' : '--',
            minutes: isRecorded ? '$lightM' : '--',
          ),
        ),
      ],
    );
  }

  Widget _buildSleepMetricCard({
    required String label,
    required String hours,
    required String minutes,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E95A5),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hours,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                ),
              ),
              const Text(
                'h ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E95A5),
                ),
              ),
              Text(
                minutes,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                ),
              ),
              const Text(
                'm',
                style: TextStyle(
                  fontSize: 12,
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

class _DetailedSleepHypnogramPainter extends CustomPainter {
  final String period;
  final double sleepHours;

  const _DetailedSleepHypnogramPainter({
    this.period = 'Day',
    this.sleepHours = 7.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (period == 'Day') {
      // Stage Labels on Left
      final lightLabel = TextPainter(
        text: const TextSpan(text: 'Light', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFC084FC))),
        textDirection: TextDirection.ltr,
      )..layout();
      lightLabel.paint(canvas, const Offset(0, 4));

      final deepLabel = TextPainter(
        text: const TextSpan(text: 'Deep', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
        textDirection: TextDirection.ltr,
      )..layout();
      deepLabel.paint(canvas, const Offset(0, 48));

      const startX = 50.0;
      final usableWidth = size.width - startX;

      // Dashed guide lines
      final guidePaint = Paint()..color = const Color(0xFFF6F7FA)..strokeWidth = 1.0;
      canvas.drawLine(Offset(startX, 18), Offset(size.width, 18), guidePaint);
      canvas.drawLine(Offset(startX, 62), Offset(size.width, 62), guidePaint);

      final lightPaint = Paint()..color = const Color(0xFFC084FC);
      final deepPaint = Paint()..color = const Color(0xFF6366F1);

      // Deep Sleep Segment 1 (10:30 PM - 1:30 AM)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + usableWidth * 0.05, 40, usableWidth * 0.25, 36),
          const Radius.circular(8),
        ),
        deepPaint,
      );

      // Light Sleep Segment 1 (1:30 AM - 3:30 AM)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + usableWidth * 0.30, 0, usableWidth * 0.25, 36),
          const Radius.circular(8),
        ),
        lightPaint,
      );

      // Deep Sleep Segment 2 (3:30 AM - 4:45 AM)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + usableWidth * 0.55, 40, usableWidth * 0.16, 36),
          const Radius.circular(8),
        ),
        deepPaint,
      );

      // Light Sleep Segment 2 (4:45 AM - 6:20 AM)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + usableWidth * 0.71, 0, usableWidth * 0.29, 36),
          const Radius.circular(8),
        ),
        lightPaint,
      );
    } else if (period == 'Week') {
      // 7-day stacked bar chart (Deep on bottom, Light on top)
      final barCount = 7;
      final spacing = size.width / barCount;
      const barWidth = 18.0;
      final lightPaint = Paint()..color = const Color(0xFFC084FC);
      final deepPaint = Paint()..color = const Color(0xFF6366F1);

      final dailyHeights = [0.75, 0.85, 0.65, 0.90, 0.80, 0.70, (sleepHours.clamp(4.0, 10.0) / 10.0)];

      for (int i = 0; i < barCount; i++) {
        final x = (i * spacing) + (spacing - barWidth) / 2;
        final totalH = size.height * dailyHeights[i];
        final deepH = totalH * 0.35;
        final lightH = totalH * 0.65;

        // Draw deep sleep (bottom)
        final deepRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - deepH, barWidth, deepH),
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        );
        canvas.drawRRect(deepRect, deepPaint);

        // Draw light sleep (top)
        final lightRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - deepH - lightH, barWidth, lightH),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(lightRect, lightPaint);
      }
    } else {
      // Monthly 5 intervals stacked bars
      final barCount = 5;
      final spacing = size.width / barCount;
      const barWidth = 26.0;
      final lightPaint = Paint()..color = const Color(0xFFC084FC);
      final deepPaint = Paint()..color = const Color(0xFF6366F1);

      final monthHeights = [0.80, 0.75, 0.85, 0.78, (sleepHours.clamp(4.0, 10.0) / 10.0)];

      for (int i = 0; i < barCount; i++) {
        final x = (i * spacing) + (spacing - barWidth) / 2;
        final totalH = size.height * monthHeights[i];
        final deepH = totalH * 0.35;
        final lightH = totalH * 0.65;

        final deepRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - deepH, barWidth, deepH),
          bottomLeft: const Radius.circular(8),
          bottomRight: const Radius.circular(8),
        );
        canvas.drawRRect(deepRect, deepPaint);

        final lightRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - deepH - lightH, barWidth, lightH),
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        );
        canvas.drawRRect(lightRect, lightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DetailedSleepHypnogramPainter oldDelegate) =>
      oldDelegate.period != period || oldDelegate.sleepHours != sleepHours;
}
