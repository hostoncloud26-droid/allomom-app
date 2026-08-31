import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class SleepDetailPage extends StatefulWidget {
  const SleepDetailPage({super.key});

  @override
  State<SleepDetailPage> createState() => _SleepDetailPageState();
}

class _SleepDetailPageState extends State<SleepDetailPage> {
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
              'Sleep',
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
                _buildPeriodTabs(const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
                const SizedBox(height: 16),

                // ─── MAIN CHART CARD (HYPNOGRAM) ───
                _buildMainChartCard(),
                const SizedBox(height: 16),

                // ─── 3 BOTTOM STAT CARDS (Total Sleep, Deep Sleep, Light Sleep) ───
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
                'LAST NIGHT',
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
          const SizedBox(height: 24),

          // Sleep Hypnogram Visual Timeline
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _DetailedSleepHypnogramPainter(),
            ),
          ),
          const SizedBox(height: 16),

          // X-Axis Time Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10:30 PM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('2:00 AM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('5:00 AM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
              Text('6:20 AM', style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatsRow() {
    return Row(
      children: [
        // Total Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: 'Total Sleep',
            hours: '7',
            minutes: '20',
          ),
        ),
        const SizedBox(width: 10),

        // Deep Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: 'Deep Sleep',
            hours: '2',
            minutes: '10',
          ),
        ),
        const SizedBox(width: 10),

        // Light Sleep
        Expanded(
          child: _buildSleepMetricCard(
            label: 'Light Sleep',
            hours: '6',
            minutes: '15',
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
  @override
  void paint(Canvas canvas, Size size) {
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
