import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
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
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/kick_counter/kick_counter_stats_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_stats_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';

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
        content: Text('Syncing with Allowear device & cloud...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await HealthVitalsController.instance.syncAllVitals();

    if (mounted) {
      setState(() => _isSyncingAllowear = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitals synced and stored successfully!'),
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
              await HealthVitalsController.instance.syncAllVitals();
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

            // ─── BABY CARE & TRACKING (KICK COUNTER & FEEDING) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildBabyTrackingSection(context),
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
    final hasHr = HealthVitalsController.instance.hasHeartRate;
    final hr = HealthVitalsController.instance.heartRateValue;
    final hrInt = int.tryParse(hr) ?? 72;
    final statusText = !hasHr
        ? 'No record'
        : (hrInt >= 60 && hrInt <= 100)
            ? 'Normal'
            : (hrInt < 60 ? 'Low' : 'Elevated');
    final statusColor = !hasHr
        ? const Color(0xFF8E95A5)
        : (hrInt >= 60 && hrInt <= 100)
            ? const Color(0xFF10B981)
            : const Color(0xFFFF5252);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    GestureDetector(
                      onTap: () => VitalLogBottomSheet.show(context, initialKey: 'heart_rate', lockKey: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 12, color: Color(0xFFFF3B5C)),
                            SizedBox(width: 2),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 10.5,
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
                  statusText,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    GestureDetector(
                      onTap: () => VitalLogBottomSheet.show(context, initialKey: 'steps', lockKey: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F9F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 2),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    final hasHrv = HealthVitalsController.instance.hasHrv;
    final hrv = HealthVitalsController.instance.hrvValue;
    final hrvInt = int.tryParse(hrv) ?? 50;
    final statusText = !hasHrv
        ? 'No record'
        : (hrvInt >= 50)
            ? 'Good'
            : (hrvInt >= 35 ? 'Balanced' : 'Low');
    final statusColor = !hasHrv
        ? const Color(0xFF8E95A5)
        : (hrvInt >= 35 ? const Color(0xFF10B981) : const Color(0xFFF59E0B));

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    GestureDetector(
                      onTap: () => VitalLogBottomSheet.show(context, initialKey: 'hrv', lockKey: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 12, color: Color(0xFF9333EA)),
                            SizedBox(width: 2),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF9333EA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  statusText,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
    final hasSpo2 = HealthVitalsController.instance.hasBloodOxygen;
    final spo2 = HealthVitalsController.instance.bloodOxygenValue;
    final spo2Int = int.tryParse(spo2) ?? 98;
    final statusText = !hasSpo2
        ? 'No record'
        : (spo2Int >= 95 ? 'Optimal' : 'Attention');
    final statusColor = !hasSpo2
        ? const Color(0xFF8E95A5)
        : (spo2Int >= 95 ? const Color(0xFF10B981) : const Color(0xFFFF5252));

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    GestureDetector(
                      onTap: () => VitalLogBottomSheet.show(context, initialKey: 'blood_oxygen', lockKey: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 12, color: Color(0xFF0284C7)),
                            SizedBox(width: 2),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  statusText,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
    final hasStress = HealthVitalsController.instance.hasStress;
    final stressVital = HealthVitalsController.instance.stressVital;
    final stressScore = stressVital != null ? stressVital.value.toInt() : 0;
    final stressBadge = hasStress ? HealthVitalsController.instance.stressLevel : 'No record';
    final progress = hasStress ? (stressScore / 100.0).clamp(0.0, 1.0) : 0.0;
    final subtitle = hasStress
        ? (stressScore <= 30
            ? 'Low stress ($stressScore/100)'
            : stressScore <= 60
                ? 'Moderate stress ($stressScore/100)'
                : 'High stress ($stressScore/100)')
        : 'Not recorded yet';
    final statusText = hasStress
        ? (stressScore <= 30
            ? 'Well rested'
            : stressScore <= 60
                ? 'Normal load'
                : 'Take a rest')
        : 'Sync to track';
    final badgeColor = hasStress
        ? (stressScore <= 30
            ? const Color(0xFF10B981)
            : stressScore <= 60
                ? const Color(0xFFF59E0B)
                : const Color(0xFFFF3B5C))
        : const Color(0xFF8E95A5);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stressBadge,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => VitalLogBottomSheet.show(context, initialKey: 'stress', lockKey: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 12, color: Color(0xFF0284C7)),
                            SizedBox(width: 2),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFF0F1F5),
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
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
    final hasSleep = HealthVitalsController.instance.hasSleep;
    final sleepHours = HealthVitalsController.instance.sleepHoursValue;
    final sleepH = sleepHours.toInt();
    final sleepM = ((sleepHours - sleepH) * 60).round();
    final sleepDate = HealthVitalsController.instance.sleepDate;
    final sleepScore = hasSleep ? ((sleepHours / 8.0) * 100).clamp(30, 99).toInt() : null;

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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bedtime_rounded,
                            color: Color(0xFF4F46E5),
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sleep',
                              style: GoogleFonts.manrope(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E2024),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              hasSleep ? sleepDate : 'No record',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: const Color(0xFF8E95A5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            sleepScore != null ? 'Score $sleepScore' : 'No record',
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => VitalLogBottomSheet.show(context, initialKey: 'sleep', lockKey: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 12, color: Color(0xFF4F46E5)),
                            SizedBox(width: 2),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hasSleep ? '${sleepH}h ${sleepM}m' : '-- h -- m',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hasSleep
                      ? (sleepHours >= 7.0
                          ? '• Optimal rest'
                          : sleepHours >= 5.0
                              ? '• Fair rest'
                              : '• Need more rest')
                      : '• Tap to log',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasSleep ? const Color(0xFF10B981) : const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              width: double.infinity,
              child: CustomPaint(
                painter: _SleepHypnogramPainter(hasSleep: hasSleep, sleepHours: sleepHours),
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
                status: HealthVitalsController.instance.hasBloodPressure ? 'Recorded' : 'No record',
                statusColor: HealthVitalsController.instance.hasBloodPressure ? const Color(0xFF10B981) : const Color(0xFF8E95A5),
                accentColor: const Color(0xFFFF3B5C),
                icon: Icons.favorite_border_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BloodPressureDetailPage()),
                  );
                },
                onLog: () => VitalLogBottomSheet.show(context, initialKey: 'blood_pressure', lockKey: true),
              ),
              const SizedBox(width: 12),

              _buildReadingCard(
                title: 'Hemoglobin',
                value: HealthVitalsController.instance.hasHemoglobin
                    ? HealthVitalsController.instance.hemoglobinValue.toStringAsFixed(1)
                    : '--',
                unit: 'g/dL',
                date: HealthVitalsController.instance.hemoglobinDate,
                status: HealthVitalsController.instance.hasHemoglobin
                    ? (HealthVitalsController.instance.hemoglobinValue >= 11.0 ? 'Adequate' : 'Low')
                    : 'No record',
                statusColor: HealthVitalsController.instance.hasHemoglobin ? const Color(0xFF10B981) : const Color(0xFF8E95A5),
                accentColor: const Color(0xFF9333EA),
                icon: Icons.water_drop_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HemoglobinDetailPage()),
                  );
                },
                onLog: () => VitalLogBottomSheet.show(context, initialKey: 'hemoglobin', lockKey: true),
              ),
              const SizedBox(width: 12),

              _buildReadingCard(
                title: 'Blood Glucose',
                value: HealthVitalsController.instance.hasBloodGlucose
                    ? HealthVitalsController.instance.bloodGlucoseValue.toStringAsFixed(0)
                    : '--',
                unit: 'mg/dL',
                date: HealthVitalsController.instance.bloodGlucoseDate,
                status: HealthVitalsController.instance.hasBloodGlucose
                    ? (HealthVitalsController.instance.bloodGlucoseValue <= 100 ? 'Normal' : 'Elevated')
                    : 'No record',
                statusColor: HealthVitalsController.instance.hasBloodGlucose ? const Color(0xFF3898EC) : const Color(0xFF8E95A5),
                accentColor: const Color(0xFFF59E0B),
                icon: Icons.bloodtype_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BloodGlucoseDetailPage()),
                  );
                },
                onLog: () => VitalLogBottomSheet.show(context, initialKey: 'glucose', lockKey: true),
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
    VoidCallback? onLog,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 164,
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
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                if (onLog != null)
                  GestureDetector(
                    onTap: onLog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 12, color: accentColor),
                          const SizedBox(width: 2),
                          Text(
                            'Log',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
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

  // ─── WEIGHT & BMI TRACKER CARD ───────────────────────────────
  Widget _buildWeightAndBmiTrackerCard(BuildContext context) {
    final hasWeight = HealthVitalsController.instance.hasWeight;
    final wt = hasWeight ? HealthVitalsController.instance.weightValue.toStringAsFixed(1) : '--';
    final wtDate = hasWeight ? HealthVitalsController.instance.weightDate : 'No record';
    final bmi = hasWeight ? HealthVitalsController.instance.bmiValue.toStringAsFixed(1) : '--';

    final weightHistory = HealthVitalsController.instance.getHistory('weight');
    String gestationalGainStr = '--';
    Color gainColor = const Color(0xFF10B981);
    if (weightHistory.length >= 2) {
      final sortedAsc = List<VitalsStreamResponse>.from(weightHistory)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final initialWt = sortedAsc.first.value;
      final currentWt = sortedAsc.last.value;
      final diff = currentWt - initialWt;
      gestationalGainStr = diff >= 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1);
      gainColor = diff >= 0 ? const Color(0xFF10B981) : const Color(0xFF3898EC);
    } else if (hasWeight) {
      gestationalGainStr = '+0.0';
    }

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
                          hasWeight ? 'Recorded $wtDate' : 'No weight logged yet',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: const Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => VitalLogBottomSheet.show(context, initialKey: 'weight', lockKey: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 12, color: Color(0xFFFF3B5C)),
                            SizedBox(width: 2),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF3B5C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF8E95A5),
                    ),
                  ],
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
                          gestationalGainStr,
                          style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: gainColor),
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
                painter: _WeightTrendPainter(history: weightHistory),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BABY TRACKING SECTION (KICK COUNTER & FEEDING) ─────────
  Widget _buildBabyTrackingSection(BuildContext context) {
    final vitals = HealthVitalsController.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Baby Care & Tracking',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2024),
              ),
            ),
            GestureDetector(
              onTap: () => _showAddReadingSheet(context),
              child: Text(
                'View All',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF3B5C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Kick Counter Card
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KickCounterStatsPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE4E6),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.pets_rounded,
                                color: Color(0xFFFF4E6A),
                                size: 19,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => VitalLogBottomSheet.show(context, initialKey: 'kick_count', lockKey: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE4E6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 12, color: Color(0xFFFF4E6A)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Log',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFF4E6A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Kick Counter',
                        style: GoogleFonts.manrope(
                          fontSize: 13.5,
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
                            vitals.hasKickCount ? '${vitals.kickCountValue}' : '7',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kicks',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E95A5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vitals.hasKickCount ? vitals.kickCountDate : 'Today, 12:45 PM',
                        style: GoogleFonts.manrope(
                          fontSize: 10.5,
                          color: const Color(0xFF8E95A5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Feeding Tracker Card
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedingTrackerStatsPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDE9FE),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_drink_rounded,
                                color: Color(0xFF8B5CF6),
                                size: 19,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => VitalLogBottomSheet.show(context, initialKey: 'feeding', lockKey: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 12, color: Color(0xFF8B5CF6)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Log',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Feeding Tracker',
                        style: GoogleFonts.manrope(
                          fontSize: 13.5,
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
                            vitals.hasFeeding
                                ? (vitals.feedingValue > 0 ? '${vitals.feedingValue.toInt()}' : '20')
                                : '20',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vitals.hasFeeding ? vitals.feedingUnit : 'mins',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8E95A5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vitals.hasFeeding ? '${vitals.feedingType} · ${vitals.feedingDate}' : 'Breast · Today',
                        style: GoogleFonts.manrope(
                          fontSize: 10.5,
                          color: const Color(0xFF8E95A5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── ADD READING BOTTOM SHEET ────────────────────────────────
  void _showAddReadingSheet(BuildContext context, [String? initialKey]) {
    VitalLogBottomSheet.show(context, initialKey: initialKey);
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
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => true;
}

// ─── SLEEP HYPNOGRAM PAINTER ─────────────────────────────────
class _SleepHypnogramPainter extends CustomPainter {
  final bool hasSleep;
  final double sleepHours;

  const _SleepHypnogramPainter({
    this.hasSleep = false,
    this.sleepHours = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasSleep || sleepHours <= 0) {
      final dashedPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), dashedPaint);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Wear your Allowear watch or tap above to track sleep',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));
      return;
    }

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
    final deepPaint = Paint()..color = const Color(0xFF6366F1);

    final deepRatio = (sleepHours >= 7.0 ? 0.35 : 0.25);
    final lightRatio = 1.0 - deepRatio;

    // Block 1 (Light)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX + usableWidth * 0.15, 0, usableWidth * (lightRatio * 0.4), 16),
        const Radius.circular(5),
      ),
      lightPaint,
    );

    // Block 2 (Light)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX + usableWidth * 0.55, 0, usableWidth * (lightRatio * 0.45), 16),
        const Radius.circular(5),
      ),
      lightPaint,
    );

    // Block 1 (Deep)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX, 24, usableWidth * (deepRatio * 0.5), 16),
        const Radius.circular(5),
      ),
      deepPaint,
    );

    // Block 2 (Deep)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barStartX + usableWidth * 0.35, 24, usableWidth * (deepRatio * 0.5), 16),
        const Radius.circular(5),
      ),
      deepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SleepHypnogramPainter oldDelegate) =>
      oldDelegate.hasSleep != hasSleep || oldDelegate.sleepHours != sleepHours;
}

// ─── WEIGHT TREND PAINTER ────────────────────────────────────
class _WeightTrendPainter extends CustomPainter {
  final List<VitalsStreamResponse> history;

  const _WeightTrendPainter({this.history = const []});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) {
      final basePaint = Paint()
        ..color = const Color(0xFFF1F5F9)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), basePaint);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'No weight entries logged yet',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));
      return;
    }

    final sortedAsc = List<VitalsStreamResponse>.from(history)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final startX = size.width * 0.12;
    final endX = size.width * 0.88;

    final firstVal = sortedAsc.first.value;
    final lastVal = sortedAsc.last.value;

    final startY = size.height * 0.70;
    final endY = sortedAsc.length > 1
        ? (firstVal <= lastVal ? size.height * 0.40 : size.height * 0.80)
        : size.height * 0.70;

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
      text: TextSpan(
        text: '${firstVal.toStringAsFixed(1)} kg',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8E95A5)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    startText.paint(canvas, Offset(startX - startText.width / 2, startY - 16));

    final endDotPaint = Paint()
      ..color = const Color(0xFFFF3B5C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(endX, endY), 5.5, endDotPaint);

    final endText = TextPainter(
      text: TextSpan(
        text: '${lastVal.toStringAsFixed(1)} kg',
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFFF3B5C)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    endText.paint(canvas, Offset(endX - endText.width / 2, endY - 18));
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) => true;
}
