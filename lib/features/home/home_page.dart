import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/overview_section/overview_section_page.dart';
import 'package:allomom/features/prescriptions/prescriptions_page.dart';
import 'package:allomom/features/reports/reports_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_journey_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Interactive state
  int _waterGlasses = 5;
  bool _ironTabletDone = false;
  bool _eveningWalkDone = false;

  late final PageController _carouselController;
  int _currentCarouselPage = 0;

  static const List<String> _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserSessionManager.instance,
      builder: (context, child) {
        final session = UserSessionManager.instance;
        final name = session.userName;
        final week = session.currentGestationalWeek;
        final trimester = session.currentTrimester;
        final edd = session.eddDate ?? DateTime.now().add(const Duration(days: 112));
        final dueDay = edd.day.toString();
        final dueMonth = _shortMonths[edd.month - 1].toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFC),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, name, week, trimester, dueDay, dueMonth),
                      const SizedBox(height: 10),

                      // ─── HERO BABY CARD ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BabyHeroBanner(
                          speechText: "Good Morning, $name ❤️",
                          greetingText: "",
                          bubblePosition: SpeechBubblePosition.topCenter,
                          height: 270,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KickCounterPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── SWIPEABLE CAROUSEL (DAILY SUMMARY & QUICK ACTIONS) ───
                      _buildSummaryCarousel(context),
                      const SizedBox(height: 20),

                      // ─── TODAY'S CARE ───
                      _buildTodaysCareSection(context),
                      const SizedBox(height: 24),

                      // ─── OVERVIEW (VITALS & NUTRITION TILES) ───
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: OverviewSectionPage(),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── HEADER / APP BAR ─────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    String userName,
    int week,
    String trimester,
    String dueDay,
    String dueMonth,
  ) {
    final firstName = userName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Profile Avatar with green online dot
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0E1013),
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // User Name & Trimester in one line
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PregnancyConfirmationPage()),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Week $week · $trimester',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E95A5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Due Date Badge Card (Centered on top & bottom date)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PregnancyJourneyPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'DUE DATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E95A5),
                      letterSpacing: 0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dueDay $dueMonth',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF3B5C),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SWIPEABLE SUMMARY CAROUSEL ────────────────────────────
  Widget _buildSummaryCarousel(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 345,
          child: PageView(
            controller: _carouselController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            children: [
              _buildDailySummaryCard(),
              _buildQuickActionsCard(context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Carousel Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = _currentCarouselPage == index;
            return GestureDetector(
              onTap: () {
                _carouselController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isActive ? 24 : 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF3B5C)
                      : const Color(0xFFE2E4E9),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── DAILY SUMMARY CARD ────────────────────────────────────
  Widget _buildDailySummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
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
                // Header with Red Star
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFF3B5C),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'DAILY SUMMARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF3B5C),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title & Subtitle
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're doing well today.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Your vitals are stable and you've completed 5/8 glasses of water.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3 Rounded Stat Cards Row
                Row(
                  children: [
                    // 3/5 Care tasks
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PregnancyConfirmationPage()),
                          );
                        },
                        child: _buildSummaryMetricChip(
                          bg: const Color(0xFFFFF0F4),
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFFF4E6A),
                          value: '3/5',
                          label: 'Care tasks',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 5/8 Water
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _waterGlasses = (_waterGlasses + 1).clamp(0, 12);
                          });
                        },
                        child: _buildSummaryMetricChip(
                          bg: const Color(0xFFEDF6FF),
                          icon: Icons.water_drop_rounded,
                          iconColor: const Color(0xFF3898EC),
                          value: '$_waterGlasses/8',
                          label: 'Water',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 2/3 Medicines
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrescriptionsPage()),
                          );
                        },
                        child: _buildSummaryMetricChip(
                          bg: const Color(0xFFFFF6ED),
                          icon: Icons.medication_rounded,
                          iconColor: const Color(0xFFFF9438),
                          value: '2/3',
                          label: 'Medicines',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Bottom CTA Button: My Pregnancy Journey
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PregnancyJourneyPage()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFF4E6A),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Pregnancy Journey',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF4E6A),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetricChip({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8A90A0),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── QUICK ACTIONS CARD (GRID OF ALL FEATURES) ─────────────
  Widget _buildQuickActionsCard(BuildContext context) {
    final features = [
      {
        'title': 'AlloCry',
        'subtitle': 'Cry Analyzer',
        'icon': Icons.graphic_eq_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF7F4FF),
        'page': const AlloCryPage(),
      },
      {
        'title': 'Kick Count',
        'subtitle': 'Fetal Tracker',
        'icon': Icons.pets_rounded,
        'color': const Color(0xFFFF4E6A),
        'bg': const Color(0xFFFFF0F4),
        'page': const KickCounterPage(),
      },
      {
        'title': 'Prescription',
        'subtitle': 'Medications',
        'icon': Icons.medication_rounded,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
        'page': const PrescriptionsPage(),
      },
      {
        'title': 'Reports',
        'subtitle': 'Lab & Scans',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'page': const ReportsPage(),
      },
      {
        'title': 'Feeding',
        'subtitle': 'Baby Nutrition',
        'icon': Icons.child_care_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFF7ED),
        'page': const FeedingTrackerPage(),
      },
      {
        'title': 'My Health',
        'subtitle': 'Vitals & Care',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFFF3B5C),
        'bg': const Color(0xFFFFF0F4),
        'page': const MyHealthPage(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Grid Icon
            Row(
              children: [
                const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFF6366F1),
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3-column x 2-row Grid
            Expanded(
              child: Column(
                children: [
                  for (int row = 0; row < 2; row++) ...[
                    if (row > 0) const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          for (int col = 0; col < 3; col++) ...[
                            if (col > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _buildFullGridFeatureItem(
                                context,
                                features[row * 3 + col],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullGridFeatureItem(BuildContext context, Map<String, dynamic> f) {
    final title = f['title'] as String;
    final subtitle = f['subtitle'] as String;
    final icon = f['icon'] as IconData;
    final color = f['color'] as Color;
    final bg = f['bg'] as Color;
    final page = f['page'] as Widget?;

    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        }
      },
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bg, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TODAY'S CARE ─────────────────────────────────────────
  Widget _buildTodaysCareSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.menu_rounded,
                    color: Color(0xFFFF4071),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "TODAY'S CARE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Color(0xFFFF4071),
                    ),
                  ),
                ],
              ),
              Text(
                '${(_ironTabletDone ? 1 : 0) + (_eveningWalkDone ? 1 : 0) + (_waterGlasses >= 8 ? 1 : 0)} of 3 completed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF4071),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Care List Card Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Item 1: Iron Tablet
                _buildCareListItem(
                  icon: Icons.medication_rounded,
                  iconBg: const Color(0xFFFFF0F3),
                  iconColor: const Color(0xFFFF4E6A),
                  title: 'Iron Tablet',
                  subtitle: 'Due after lunch',
                  trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        _ironTabletDone = !_ironTabletDone;
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ironTabletDone ? const Color(0xFFFF4E6A) : Colors.transparent,
                        border: Border.all(
                          color: const Color(0xFFFF4E6A),
                          width: 2,
                        ),
                      ),
                      child: _ironTabletDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ),
                const Divider(height: 20, color: Color(0xFFF6F7FA)),

                // Item 2: Hydration
                _buildCareListItem(
                  icon: Icons.water_drop_rounded,
                  iconBg: const Color(0xFFEDF6FF),
                  iconColor: const Color(0xFF3898EC),
                  title: 'Hydration',
                  subtitle: '$_waterGlasses / 8 glasses',
                  trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        _waterGlasses = (_waterGlasses + 1).clamp(0, 12);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('+250 ml logged! Keep drinking water.'),
                          duration: Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '+250 ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3898EC),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 20, color: Color(0xFFF6F7FA)),

                // Item 3: Evening Walk
                _buildCareListItem(
                  icon: Icons.directions_walk_rounded,
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF22C55E),
                  title: 'Evening Walk',
                  subtitle: '30 minutes',
                  trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        _eveningWalkDone = !_eveningWalkDone;
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _eveningWalkDone ? const Color(0xFFFF4E6A) : Colors.transparent,
                        border: Border.all(
                          color: const Color(0xFFFF4E6A),
                          width: 2,
                        ),
                      ),
                      child: _eveningWalkDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareListItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2024),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
