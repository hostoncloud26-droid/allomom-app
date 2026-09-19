import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';
import 'package:allomom/features/my_health/widgets/vital_trend_chart.dart';
import 'package:allomom/controllers/main_controller.dart';

class KickCounterStatsPage extends StatefulWidget {
  const KickCounterStatsPage({super.key});

  @override
  State<KickCounterStatsPage> createState() => _KickCounterStatsPageState();
}

class _KickCounterStatsPageState extends State<KickCounterStatsPage> {
  int _selectedFilter = 0; // 0: Day, 1: Week, 2: Month

  String get _periodKey {
    switch (_selectedFilter) {
      case 0:
        return 'day';
      case 1:
        return 'week';
      case 2:
      default:
        return 'month';
    }
  }

  void _logMovement() async {
    final logged = await VitalLogBottomSheet.show(
      context,
      initialKey: 'kick_count',
      lockKey: true,
    );
    if (logged == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HealthVitalsController.instance,
      builder: (context, _) {
        final vitals = HealthVitalsController.instance;
        final periodHistory = vitals.getHistoryForPeriod('kick_count', _periodKey);
        final totalMovements = periodHistory.isNotEmpty
            ? periodHistory.map((e) => e.value.toInt()).fold<int>(0, (a, b) => a + b)
            : (vitals.hasKickCount ? vitals.kickCountValue : 0);

        String periodLabel = 'today';
        String dateSubheader = 'Today, ${DateFormat('dd MMM').format(DateTime.now())}';

        if (_selectedFilter == 1) {
          periodLabel = 'this week';
          final start = DateTime.now().subtract(const Duration(days: 6));
          dateSubheader = '${DateFormat('dd MMM').format(start)} - Today';
        } else if (_selectedFilter == 2) {
          periodLabel = 'this month';
          dateSubheader = DateFormat('MMMM yyyy').format(DateTime.now());
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAF6F7),
          body: SafeArea(
            child: Column(
              children: [
                // ─── TOP APP BAR ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1E2024),
                          size: 24,
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Kick Counter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2024),
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _logMovement,
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF4E6A)),
                        label: const Text(
                          'Log',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF4E6A),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEBF0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── FIXED TOP: Baby Hero Banner, Summary Card & Filter Tabs ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: BabyHeroBanner(
                    speechText:
                        "Week ${MainController.instance.currentGestationalWeek}, Amma!\nWe're growing together. Can you feel the kicks?",
                    bubblePosition: SpeechBubblePosition.topCenter,
                    height: 220,
                  ),
                ),

                // ─── SUMMARY CARD ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KickCounterPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
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
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE4E6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Color(0xFFFF4E6A),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$totalMovements',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E2024),
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'movements',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E2024),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                periodLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8C93A3),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF8C93A3),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ─── FILTER TABS (Day / Week / Month) ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildFilterTab(0, 'Day'),
                        _buildFilterTab(1, 'Week'),
                        _buildFilterTab(2, 'Month'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ─── SCROLLABLE BODY (After the tab) ───
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ─── CHART CARD ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              dateSubheader,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8C93A3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),

                            VitalTrendChart(
                              period: _periodKey,
                              accent: const Color(0xFFFF4E6A),
                              unit: 'kicks',
                              bars: true,
                              minY: 0,
                              height: 176,
                              emptyTitle: 'No movements logged',
                              emptySubtitle: 'Tap Log to count your first kicks',
                              series: [
                                VitalSeries.fromHistory(
                                  label: 'Kicks',
                                  color: const Color(0xFFFF4E6A),
                                  history: periodHistory,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── MOTIVATIONAL CARD ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF4E6A),
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                // Reassurance only means something once there is
                                // something to be reassured about.
                                totalMovements > 0
                                    ? "Your baby's movements are\nwithin your usual range."
                                    : "No movements counted $periodLabel.\nTap Log when you feel a kick.",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E2024),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ─── LOG MOVEMENT BUTTON ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: _logMovement,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFFFF4E6A),
                              width: 1.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: Color(0xFFFF4E6A),
                                size: 22,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Log movement',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF4E6A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFE4E6) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
