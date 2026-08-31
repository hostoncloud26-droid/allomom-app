import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/features/my_health/details/steps_detail_page.dart';
import 'package:allomom/features/my_health/details/blood_oxygen_detail_page.dart';
import 'package:allomom/features/my_health/details/heart_rate_detail_page.dart';
import 'package:allomom/features/my_health/details/sleep_detail_page.dart';
import 'package:allomom/features/my_health/details/hrv_detail_page.dart';
import 'package:allomom/features/my_health/details/stress_detail_page.dart';
import 'package:allomom/features/my_health/details/blood_pressure_detail_page.dart';
import 'package:allomom/features/my_health/details/hemoglobin_detail_page.dart';
import 'package:allomom/features/my_health/details/blood_glucose_detail_page.dart';
import 'package:allomom/features/my_health/details/bmi_tracker_detail_page.dart';

class MyHealthPage extends StatelessWidget {
  const MyHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          'My Health',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3142),
          ),
        ),
      ),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: MyHealthSection(showBabyHero: true),
      ),
    );
  }
}

class MyHealthSection extends StatefulWidget {
  final bool showBabyHero;
  final bool showSectionHeader;

  const MyHealthSection({
    super.key,
    this.showBabyHero = false,
    this.showSectionHeader = false,
  });

  @override
  State<MyHealthSection> createState() => _MyHealthSectionState();
}

class _MyHealthSectionState extends State<MyHealthSection> {
  // Interactive readings state
  String _bloodPressure = '118/76';
  String _bloodPressureDate = '26 Aug';
  
  String _hemoglobin = '10.8';
  String _hemoglobinDate = '26 Aug';
  
  String _glucose = '92';
  String _glucoseDate = '25 Aug';
  
  String _weight = '62.5';
  String _weightDate = '25 Aug';
  
  double _bmi = 24.1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserSessionManager.instance,
      builder: (context, child) {
        final session = UserSessionManager.instance;
        final week = session.currentGestationalWeek;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional Section Header (for home overview integration)
            if (widget.showSectionHeader) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Health',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyHealthPage()),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF3B5C),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFFFF3B5C),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ─── BABY HERO CARD (OPTIONAL) ───
            if (widget.showBabyHero) ...[
              BabyHeroBanner(
                speechText: "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                bubblePosition: SpeechBubblePosition.topCenter,
                height: 270,
                greetingText: "",
              ),
              const SizedBox(height: 18),
            ],

            // ─── SLEEP CARD (1ST) ───
            _buildSleepCard(),
            const SizedBox(height: 14),

            // ─── VITALS GRID (STEPS, HR, HRV, BLOOD OXYGEN, STRESS) ───
            _buildVitalsGrid(),
            const SizedBox(height: 20),

            // ─── HEALTH READINGS (WITH + ADD) ───
            _buildHealthReadingsSection(context),
            const SizedBox(height: 14),

            // ─── WEIGHT & BMI TRACKER ───
            _buildWeightAndBmiTrackerCard(context),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // ─── VITALS GRID (STEPS, HEART RATE, HRV, BLOOD OXYGEN, STRESS) ───
  Widget _buildVitalsGrid() {
    return Column(
      children: [
        // Row 1: Steps & Heart Rate
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStepsTile(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeartRateTile(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 2: HRV & Blood Oxygen
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildHrvTile(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBloodOxygenTile(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Row 3: Stress Load Tile
        _buildStressLoadTile(),
      ],
    );
  }

  // ─── HEART RATE TILE (COMPACT LIKE HRV) ────────────────────
  Widget _buildHeartRateTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HeartRateDetailPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pink Heart Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECEF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFF3B5C),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'Heart Rate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),

                const Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '78',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'bpm',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E95A5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status and Pink Wave Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Normal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 18,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(color: const Color(0xFFFF3B5C)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEPS TILE ───────────────────────────────────────────
  Widget _buildStepsTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StepsDetailPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F9F0),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.directions_walk_rounded,
                    color: Color(0xFF10B981),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 2),

              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '4,280',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    'steps',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Goal & Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goal: 6,000',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E95A5),
                    ),
                  ),
                  Text(
                    '71%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.71,
                  minHeight: 5,
                  backgroundColor: Color(0xFFF0FDF4),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ─── HRV TILE ─────────────────────────────────────────────
  Widget _buildHrvTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HrvDetailPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purple Heart/Pulse Icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.monitor_heart_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'HRV',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 2),

              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '52',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    'ms',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status and Purple Wave Line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Balanced',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              SizedBox(
                width: 48,
                height: 18,
                child: CustomPaint(
                  painter: _MiniSparklinePainter(color: const Color(0xFF8B5CF6)),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ─── BLOOD OXYGEN TILE ────────────────────────────────────
  Widget _buildBloodOxygenTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BloodOxygenDetailPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blue Droplet Icon
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF3898EC),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Blood Oxygen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 2),

              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '98',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    '%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E95A5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status and Blue Wave Line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Normal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              SizedBox(
                width: 48,
                height: 18,
                child: CustomPaint(
                  painter: _MiniSparklinePainter(color: const Color(0xFF3898EC)),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ─── STRESS LOAD TILE ─────────────────────────────────────
  Widget _buildStressLoadTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StressDetailPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Orange Leaf/Sparkle Icon
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF6ED),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.spa_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Value
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stress Load',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Low',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2024),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // 5-Segment Indicator + Managing Well Subtitle on right
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      _buildStressSegment(const Color(0xFF10B981)), // Active Green
                      const SizedBox(width: 3),
                      _buildStressSegment(const Color(0xFFD1FAE5)), // Light Green
                      const SizedBox(width: 3),
                      _buildStressSegment(const Color(0xFFFEF3C7)), // Light Yellow
                      const SizedBox(width: 3),
                      _buildStressSegment(const Color(0xFFFFEDD5)), // Light Orange
                      const SizedBox(width: 3),
                      _buildStressSegment(const Color(0xFFFFE4E6)), // Light Pink
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Managing well',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressSegment(Color color) {
    return Expanded(
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // ─── SLEEP CARD ───────────────────────────────────────────
  Widget _buildSleepCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SleepDetailPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Sleep Stats
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sleep',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2024),
                ),
              ),
              SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '8',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'hrs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                'Latest • Today',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E95A5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Right: Hypnogram Chart (Light / Deep Sleep Bar Timeline)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sleep Stage Timeline Graphic
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SleepHypnogramPainter(),
                  ),
                ),
                const SizedBox(height: 4),

                // Time Labels
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('10:30 PM', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5))),
                    Text('2:00 AM', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5))),
                    Text('5:00 AM', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5))),
                    Text('6:30 AM', style: TextStyle(fontSize: 8.5, color: Color(0xFF8E95A5))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ─── HEALTH READINGS SECTION (WITH + ADD) ──────────────────
  Widget _buildHealthReadingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Health Readings',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2024),
              ),
            ),
            GestureDetector(
              onTap: () => _showAddReadingModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Color(0xFFFF3B5C)),
                    SizedBox(width: 2),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF3B5C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Readings
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Blood Pressure
              Expanded(
                child: _buildReadingCard(
                  icon: Icons.monitor_heart_rounded,
                  iconColor: const Color(0xFF14B8A6),
                  iconBg: const Color(0xFFCCFBF1),
                  title: 'Blood\nPressure',
                  value: _bloodPressure,
                  unit: 'mmHg',
                  date: _bloodPressureDate,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BloodPressureDetailPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Hemoglobin
              Expanded(
                child: _buildReadingCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFFEF4444),
                  iconBg: const Color(0xFFFEE2E2),
                  title: 'Hemoglobin\n',
                  value: _hemoglobin,
                  unit: 'g/dL',
                  date: _hemoglobinDate,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HemoglobinDetailPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Glucose (Fasting)
              Expanded(
                child: _buildReadingCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFFEF3C7),
                  title: 'Glucose\n(Fasting)',
                  value: _glucose,
                  unit: 'mg/dL',
                  date: _glucoseDate,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BloodGlucoseDetailPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Weight
              Expanded(
                child: _buildReadingCard(
                  icon: Icons.scale_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBg: const Color(0xFFEDE9FE),
                  title: 'Weight\n',
                  value: _weight,
                  unit: 'kg',
                  date: _weightDate,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BmiTrackerDetailPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadingCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required String unit,
    required String date,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                    height: 1.2,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          Text(
            date,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8E95A5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ─── WEIGHT & BMI TRACKER CARD ────────────────────────────
  Widget _buildWeightAndBmiTrackerCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BmiTrackerDetailPage()),
        );
      },
      child: Container(
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
          // Top Row: Title, Large Weight, Trend Line on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Title & Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight & BMI Tracker',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _weight,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2024),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'kg',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Latest • Today',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E95A5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Weight Gain Trend Graphic
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    height: 44,
                    child: CustomPaint(
                      painter: _WeightTrendPainter(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('20 Jul', style: TextStyle(fontSize: 9, color: Color(0xFF8E95A5))),
                      SizedBox(width: 50),
                      Text('Today', style: TextStyle(fontSize: 9, color: Color(0xFF8E95A5), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Inner Pill Card for BMI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F1F5), width: 1),
            ),
            child: Row(
              children: [
                const Text(
                  'BMI',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8E95A5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _bmi.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Normal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ─── ADD READING BOTTOM SHEET MODAL ────────────────────────
  void _showAddReadingModal(BuildContext context) {
    String selectedType = 'Blood Pressure';
    final val1Ctrl = TextEditingController(text: '120');
    final val2Ctrl = TextEditingController(text: '80');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Log Health Reading',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reading Type Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['Blood Pressure', 'Hemoglobin', 'Glucose', 'Weight'].map((type) {
                        final isSelected = selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFF3B5C),
                            backgroundColor: const Color(0xFFF3F4F6),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF4B5563),
                            ),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() => selectedType = type);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Fields
                  if (selectedType == 'Blood Pressure') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: val1Ctrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Systolic (mmHg)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: val2Ctrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Diastolic (mmHg)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextField(
                      controller: val1Ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: selectedType == 'Hemoglobin'
                            ? 'Value (g/dL)'
                            : selectedType == 'Glucose'
                                ? 'Value (mg/dL)'
                                : 'Weight (kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (selectedType == 'Blood Pressure') {
                            _bloodPressure = '${val1Ctrl.text}/${val2Ctrl.text}';
                            _bloodPressureDate = 'Today';
                          } else if (selectedType == 'Hemoglobin') {
                            _hemoglobin = val1Ctrl.text;
                            _hemoglobinDate = 'Today';
                          } else if (selectedType == 'Glucose') {
                            _glucose = val1Ctrl.text;
                            _glucoseDate = 'Today';
                          } else if (selectedType == 'Weight') {
                            _weight = val1Ctrl.text;
                            _weightDate = 'Today';
                            final w = double.tryParse(_weight) ?? 62.5;
                            _bmi = (w / (1.62 * 1.62));
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$selectedType logged successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B5C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Save Reading',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── MINI SPARKLINE PAINTER ──────────────────────────────────
class _MiniSparklinePainter extends CustomPainter {
  final Color color;

  _MiniSparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.cubicTo(
      size.width * 0.25, size.height * 0.1,
      size.width * 0.40, size.height * 0.9,
      size.width * 0.65, size.height * 0.2,
    );
    path.cubicTo(
      size.width * 0.85, size.height * 0.8,
      size.width * 0.95, size.height * 0.3,
      size.width, size.height * 0.4,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── SLEEP HYPNOGRAM PAINTER ─────────────────────────────────
class _SleepHypnogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Legend labels
    final lightTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Light',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFFC084FC)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lightTextPainter.paint(canvas, const Offset(0, 0));

    final deepTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Deep',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    deepTextPainter.paint(canvas, const Offset(0, 24));

    final barStartX = 45.0;
    final usableWidth = size.width - barStartX;

    // Light Sleep Blocks (Top row)
    final lightPaint = Paint()..color = const Color(0xFFC084FC);
    
    // Block 1 (Light)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX + usableWidth * 0.18, 0, usableWidth * 0.20, 16),
        const Radius.circular(5),
      ),
      lightPaint,
    );

    // Block 2 (Light)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX + usableWidth * 0.48, 0, usableWidth * 0.50, 16),
        const Radius.circular(5),
      ),
      lightPaint,
    );

    // Deep Sleep Blocks (Bottom row)
    final deepPaint = Paint()..color = const Color(0xFF6366F1);

    // Block 1 (Deep)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX, 24, usableWidth * 0.20, 16),
        const Radius.circular(5),
      ),
      deepPaint,
    );

    // Block 2 (Deep)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX + usableWidth * 0.36, 24, usableWidth * 0.14, 16),
        const Radius.circular(5),
      ),
      deepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── WEIGHT TREND PAINTER ────────────────────────────────────
class _WeightTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final startX = size.width * 0.12;
    final startY = size.height * 0.70;
    final endX = size.width * 0.88;
    final endY = size.height * 0.65;

    // Connecting line
    final linePaint = Paint()
      ..color = const Color(0xFFFFD1DC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);

    // Start Dot
    final startDotPaint = Paint()
      ..color = const Color(0xFFFF6584)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(startX, startY), 4.5, startDotPaint);

    // Start Text Label "63.2" above dot
    final startText = TextPainter(
      text: const TextSpan(text: '63.2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E95A5))),
      textDirection: TextDirection.ltr,
    )..layout();
    startText.paint(canvas, Offset(startX - startText.width / 2, startY - 16));

    // End Dot
    final endDotPaint = Paint()
      ..color = const Color(0xFFFF3B5C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(endX, endY), 5.5, endDotPaint);

    // End Text Label "66.5" above dot
    final endText = TextPainter(
      text: const TextSpan(text: '66.5', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFFF3B5C))),
      textDirection: TextDirection.ltr,
    )..layout();
    endText.paint(canvas, Offset(endX - endText.width / 2, endY - 18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
