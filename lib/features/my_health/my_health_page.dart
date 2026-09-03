import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/reports/reports_page.dart';
import 'package:allomom/features/prescriptions/prescriptions_page.dart';
import 'package:allomom/features/my_health/health_profile_page.dart';
import 'package:allomom/features/my_health/widgets/my_health_profile_card.dart';
import 'package:allomom/features/my_health/widgets/advanced_health_summary_card.dart';
import 'package:allomom/features/my_health/widgets/step_target_tile.dart';
import 'package:allomom/features/my_health/widgets/fitness_summary_card.dart';
import 'package:allomom/features/my_health/widgets/calories_tracker_tile.dart';
import 'package:allomom/features/my_health/widgets/nutrition_tiles.dart';
import 'package:allomom/features/my_health/widgets/fitness_tiles.dart';
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

class _HealthTabItem {
  final IconData icon;
  final String label;

  const _HealthTabItem({
    required this.icon,
    required this.label,
  });
}

class MyHealthPage extends StatefulWidget {
  final int initialTab;
  const MyHealthPage({super.key, this.initialTab = 0});

  @override
  State<MyHealthPage> createState() => _MyHealthPageState();
}

class _MyHealthPageState extends State<MyHealthPage> {
  late int _currentIndex;
  late final PageController _pageController;
  bool _isSyncingAllowear = false;

  final List<_HealthTabItem> _tabs = const [
    _HealthTabItem(icon: Icons.health_and_safety_rounded, label: 'Health'),
    _HealthTabItem(icon: Icons.description_rounded, label: 'Reports'),
    _HealthTabItem(icon: Icons.medication_rounded, label: 'Prescription'),
    _HealthTabItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncAllowearDevice() async {
    setState(() => _isSyncingAllowear = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing with Allowear device...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Future.wait([
      HealthVitalsController.instance.refreshAndSyncLast30Days(),
      HealthVitalsController.instance.fetchLatestVitals(),
    ]);

    if (mounted) {
      setState(() => _isSyncingAllowear = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allowear vitals synced successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
        title: Text(
          _currentIndex == 0
              ? 'My Health'
              : _currentIndex == 1
                  ? 'My Reports'
                  : _currentIndex == 2
                      ? 'My Prescriptions'
                      : 'My Profile',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2D3142),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'my_health_allowear_fab',
        onPressed: _isSyncingAllowear ? null : _syncAllowearDevice,
        backgroundColor: const Color(0xFFFF3B5C),
        elevation: 6,
        shape: const CircleBorder(),
        child: _isSyncingAllowear
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(
                Icons.watch_rounded,
                color: Colors.white,
                size: 28,
              ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabButton(0, _tabs[0]),
              _buildTabButton(1, _tabs[1]),
              const SizedBox(width: 48), // Notch space for FAB
              _buildTabButton(2, _tabs[2]),
              _buildTabButton(3, _tabs[3]),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) {
          if (_currentIndex != idx) {
            setState(() => _currentIndex = idx);
          }
        },
        children: [
          // Tab 0: Health Section
          RefreshIndicator(
            color: const Color(0xFFFF3B5C),
            onRefresh: () async {
              await Future.wait([
                HealthVitalsController.instance.refreshAndSyncLast30Days(),
                HealthVitalsController.instance.fetchLatestVitals(),
              ]);
            },
            child: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: MyHealthSection(showBabyHero: true),
            ),
          ),

          // Tab 1: Reports
          const ReportsPage(showAppBar: false),

          // Tab 2: Prescriptions
          const PrescriptionsPage(),

          // Tab 3: Profile
          const HealthProfilePage(),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, _HealthTabItem tab) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFFFF3B5C);
    const inactiveColor = Color(0xFF8E95A5);

    return InkWell(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HealthVitalsController.instance.fetchLatestVitals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([UserSessionManager.instance, HealthVitalsController.instance]),
      builder: (context, child) {
        final session = UserSessionManager.instance;
        final week = session.currentGestationalWeek;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional Section Header (for home overview integration)
            if (widget.showSectionHeader) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Health',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyHealthPage()),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View all',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF3B5C),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: Color(0xFFFF3B5C),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ─── COLLAPSIBLE USER PROFILE BANNER ───
            const MyHealthProfileCard(),
            const SizedBox(height: 12),

            // ─── BABY HERO CARD (OPTIONAL) ───
            if (widget.showBabyHero) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BabyHeroBanner(
                  speechText: "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                  bubblePosition: SpeechBubblePosition.topCenter,
                  height: 270,
                  greetingText: "",
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ─── ADVANCED READINESS & VITAL SCORING ENGINE ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AdvancedHealthSummaryCard(),
            ),
            const SizedBox(height: 14),

            // ─── DAILY STEP TARGET CARD ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: StepTargetTile(),
            ),
            const SizedBox(height: 14),

            // ─── FITNESS & MOVEMENT SUMMARY ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: FitnessSummaryCard(),
            ),
            const SizedBox(height: 14),

            // ─── CALORIES & DIET TRACKER ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CaloriesTrackerTile(),
            ),
            const SizedBox(height: 14),

            // ─── SLEEP CARD (1ST VITAL) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSleepCard(),
            ),
            const SizedBox(height: 14),

            // ─── VITALS GRID (STEPS, HR, HRV, BLOOD OXYGEN, STRESS) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildVitalsGrid(),
            ),
            const SizedBox(height: 20),

            // ─── HEALTH READINGS (WITH + ADD) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHealthReadingsSection(context),
            ),
            const SizedBox(height: 14),

            // ─── WEIGHT & BMI TRACKER ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildWeightAndBmiTrackerCard(context),
            ),
            const SizedBox(height: 20),

            // ─── NUTRITION MEAL TILES ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: NutritionTiles(),
            ),
            const SizedBox(height: 20),

            // ─── GENTLE PREGNANCY FITNESS TILES ───
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: FitnessTiles(),
            ),

            const SizedBox(height: 60),
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

  // ─── HEART RATE TILE ─────────────────────────────────────────
  Widget _buildHeartRateTile() {
    final hr = HealthVitalsController.instance.heartRateValue;

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

                Text(
                  'Heart Rate',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hr,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'bpm',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Normal',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 18,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(
                      color: const Color(0xFFFF3B5C),
                      dataPoints: HealthVitalsController.instance
                          .getHistory('heart_rate')
                          .map((e) => e.value)
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEPS TILE ───────────────────────────────────────────────
  Widget _buildStepsTile() {
    final steps = HealthVitalsController.instance.stepsValue;
    final goal = HealthVitalsController.instance.currentStepTarget;
    final pct = ((steps / (goal > 0 ? goal : 6000)) * 100).clamp(0, 100).toInt();

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

                Text(
                  'Steps',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),

                Text(
                  steps.toString(),
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$pct% of goal',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                    Text(
                      '$goal',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF0F1F5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── HRV TILE ────────────────────────────────────────────────
  Widget _buildHrvTile() {
    final hrv = HealthVitalsController.instance.hrvValue;

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
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF9333EA),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'HRV',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hrv,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'ms',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Good',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 18,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(
                      color: const Color(0xFF9333EA),
                      dataPoints: HealthVitalsController.instance
                          .getHistory('hrv')
                          .map((e) => e.value)
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── BLOOD OXYGEN TILE ───────────────────────────────────────
  Widget _buildBloodOxygenTile() {
    final spo2 = HealthVitalsController.instance.bloodOxygenValue;

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
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.air_rounded,
                      color: Color(0xFF0284C7),
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'Blood Oxygen',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      spo2,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '%',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF8E95A5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Optimal',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 18,
                  child: CustomPaint(
                    painter: _MiniSparklinePainter(
                      color: const Color(0xFF0284C7),
                      dataPoints: HealthVitalsController.instance
                          .getHistory('blood_oxygen')
                          .map((e) => e.value)
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── STRESS LOAD TILE ────────────────────────────────────────
  Widget _buildStressLoadTile() {
    final stress = HealthVitalsController.instance.stressLevel;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StressDetailPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.spa_rounded,
                          color: Color(0xFFD97706),
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Stress Load',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F9F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stress,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: const LinearProgressIndicator(
                value: 0.28,
                minHeight: 6,
                backgroundColor: Color(0xFFF0F1F5),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Low stress (28/100)',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
                Text(
                  'Well rested',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SLEEP CARD ──────────────────────────────────────────────
  Widget _buildSleepCard() {
    final sleepHours = HealthVitalsController.instance.sleepHoursValue;
    final sleepH = sleepHours.toInt();
    final sleepM = ((sleepHours - sleepH) * 60).round();
    final sleepDate = HealthVitalsController.instance.sleepDate;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SleepDetailPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bedtime_rounded,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sleep Duration',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                        Text(
                          sleepDate,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: const Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 3),
                      Text(
                        'Score 88',
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${sleepH}h ${sleepM}m',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Optimal rest',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              width: double.infinity,
              child: CustomPaint(
                painter: _SleepHypnogramPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEALTH READINGS SECTION ─────────────────────────────────
  Widget _buildHealthReadingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Readings',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2024),
              ),
            ),
            GestureDetector(
              onTap: () => _showAddReadingSheet(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 15,
                    color: Color(0xFFFF3B5C),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF3B5C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 Cards Row: BP, Hemoglobin, Blood Glucose
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildReadingCard(
                title: 'Blood Pressure',
                value: HealthVitalsController.instance.bloodPressureValue,
                unit: 'mmHg',
                date: HealthVitalsController.instance.bloodPressureDate,
                status: 'Optimal',
                statusColor: const Color(0xFF10B981),
                accentColor: const Color(0xFFFF3B5C),
                icon: Icons.favorite_border_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BloodPressureDetailPage()),
                  );
                },
              ),
              const SizedBox(width: 12),

              _buildReadingCard(
                title: 'Hemoglobin',
                value: HealthVitalsController.instance.hemoglobinValue.toStringAsFixed(1),
                unit: 'g/dL',
                date: HealthVitalsController.instance.hemoglobinDate,
                status: 'Adequate',
                statusColor: const Color(0xFF10B981),
                accentColor: const Color(0xFF9333EA),
                icon: Icons.water_drop_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HemoglobinDetailPage()),
                  );
                },
              ),
              const SizedBox(width: 12),

              _buildReadingCard(
                title: 'Blood Glucose',
                value: HealthVitalsController.instance.bloodGlucoseValue.toStringAsFixed(0),
                unit: 'mg/dL',
                date: HealthVitalsController.instance.bloodGlucoseDate,
                status: 'Fasting',
                statusColor: const Color(0xFF3898EC),
                accentColor: const Color(0xFFF59E0B),
                icon: Icons.bloodtype_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BloodGlucoseDetailPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadingCard({
    required String title,
    required String value,
    required String unit,
    required String date,
    required String status,
    required Color statusColor,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: accentColor, size: 17),
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8E95A5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: GoogleFonts.manrope(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WEIGHT & BMI TRACKER CARD ───────────────────────────────
  Widget _buildWeightAndBmiTrackerCard(BuildContext context) {
    final wt = HealthVitalsController.instance.weightValue.toStringAsFixed(1);
    final wtDate = HealthVitalsController.instance.weightDate;
    final bmi = HealthVitalsController.instance.bmiValue.toStringAsFixed(1);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BmiTrackerDetailPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.monitor_weight_outlined,
                          color: Color(0xFFFF3B5C),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight & BMI Tracker',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                        Text(
                          'Recorded $wtDate',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: const Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF8E95A5),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Weight',
                      style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF8E95A5), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          wt,
                          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1E2024)),
                        ),
                        const SizedBox(width: 3),
                        Text('kg', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF8E95A5))),
                      ],
                    ),
                  ],
                ),
                Container(height: 36, width: 1, color: const Color(0xFFF0F1F5)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestational Gain',
                      style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF8E95A5), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '+3.3',
                          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 3),
                        Text('kg', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF8E95A5))),
                      ],
                    ),
                  ],
                ),
                Container(height: 36, width: 1, color: const Color(0xFFF0F1F5)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI',
                      style: GoogleFonts.manrope(fontSize: 11.5, color: const Color(0xFF8E95A5), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bmi,
                      style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF1E2024)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            SizedBox(
              height: 48,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightTrendPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD READING BOTTOM SHEET ────────────────────────────────
  void _showAddReadingSheet(BuildContext context) {
    String selectedType = 'Blood Pressure';
    final val1Ctrl = TextEditingController();
    final val2Ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Log Health Reading',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reading Type Selector Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Blood Pressure', 'Hemoglobin', 'Glucose', 'Weight'].map((type) {
                        final isSel = selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSel,
                            selectedColor: const Color(0xFFFF3B5C),
                            labelStyle: GoogleFonts.manrope(
                              color: isSel ? Colors.white : const Color(0xFF1E2024),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            backgroundColor: const Color(0xFFF8FAFC),
                            onSelected: (_) => setModalState(() => selectedType = type),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input fields
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
                      onPressed: () async {
                        if (selectedType == 'Blood Pressure') {
                          final s = int.tryParse(val1Ctrl.text) ?? 120;
                          final d = int.tryParse(val2Ctrl.text) ?? 80;
                          await HealthVitalsController.instance.addBloodPressureEntry(
                            systolic: s,
                            diastolic: d,
                          );
                        } else if (selectedType == 'Hemoglobin') {
                          final hb = double.tryParse(val1Ctrl.text) ?? 10.8;
                          await HealthVitalsController.instance.addVitalEntry(
                            key: 'hemoglobin',
                            value: hb,
                            unit: 'g/dL',
                          );
                        } else if (selectedType == 'Glucose') {
                          final g = double.tryParse(val1Ctrl.text) ?? 92.0;
                          await HealthVitalsController.instance.addVitalEntry(
                            key: 'glucose',
                            value: g,
                            unit: 'mg/dL',
                          );
                        } else if (selectedType == 'Weight') {
                          final w = double.tryParse(val1Ctrl.text) ?? 62.5;
                          await HealthVitalsController.instance.addVitalEntry(
                            key: 'weight',
                            value: w,
                            unit: 'kg',
                          );
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$selectedType logged successfully!'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B5C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Reading',
                        style: GoogleFonts.manrope(
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
  final List<double>? dataPoints;

  _MiniSparklinePainter({required this.color, this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints != null && dataPoints!.length >= 2) {
      final pts = dataPoints!;
      final minVal = pts.reduce(math.min);
      final maxVal = pts.reduce(math.max);
      final range = maxVal - minVal == 0 ? 10.0 : maxVal - minVal;

      final stepX = size.width / (pts.length - 1);
      final points = <Offset>[];
      for (int i = 0; i < pts.length; i++) {
        final normY = (pts[i] - minVal) / range;
        final y = size.height - (normY * (size.height - 8)) - 4;
        points.add(Offset(i * stepX, y));
      }

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);
      return;
    }

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
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => true;
}

// ─── SLEEP HYPNOGRAM PAINTER ─────────────────────────────────
class _SleepHypnogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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

    final linePaint = Paint()
      ..color = const Color(0xFFFFD1DC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);

    final startDotPaint = Paint()
      ..color = const Color(0xFFFF6584)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(startX, startY), 4.5, startDotPaint);

    final startText = TextPainter(
      text: const TextSpan(text: '63.2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E95A5))),
      textDirection: TextDirection.ltr,
    )..layout();
    startText.paint(canvas, Offset(startX - startText.width / 2, startY - 16));

    final endDotPaint = Paint()
      ..color = const Color(0xFFFF3B5C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(endX, endY), 5.5, endDotPaint);

    final endText = TextPainter(
      text: const TextSpan(text: '66.5', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFFF3B5C))),
      textDirection: TextDirection.ltr,
    )..layout();
    endText.paint(canvas, Offset(endX - endText.width / 2, endY - 18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
