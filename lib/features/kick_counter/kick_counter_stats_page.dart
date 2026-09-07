import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';

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
        List<String> xLabels = ['12 AM', '6 AM', '12 PM', '6 PM', '12 AM'];
        List<double> barValues = [1.0, 3.0, 7.0, 5.0, 9.0, 3.0, 2.0, 11.0, 3.0, 2.0];

        if (_selectedFilter == 1) {
          periodLabel = 'this week';
          final start = DateTime.now().subtract(const Duration(days: 6));
          dateSubheader = '${DateFormat('dd MMM').format(start)} - Today';
          xLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          barValues = [12.0, 15.0, 9.0, 14.0, 18.0, 10.0, totalMovements.toDouble()];
        } else if (_selectedFilter == 2) {
          periodLabel = 'this month';
          dateSubheader = DateFormat('MMMM yyyy').format(DateTime.now());
          xLabels = ['W1', 'W2', 'W3', 'W4', 'Today'];
          barValues = [45.0, 52.0, 48.0, 60.0, totalMovements.toDouble()];
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: BabyHeroBanner(
                    speechText: "Week 24, Amma!\nWe're growing together. Can you feel the kicks?",
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
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dateSubheader,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8C93A3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Bar Chart Display
                            SizedBox(
                              height: 160,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Y-Axis Labels
                                  const SizedBox(
                                    width: 28,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('20', style: TextStyle(fontSize: 11, color: Color(0xFF8C93A3))),
                                        Text('10', style: TextStyle(fontSize: 11, color: Color(0xFF8C93A3))),
                                        Text('0', style: TextStyle(fontSize: 11, color: Color(0xFF8C93A3))),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Bars Area
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: List.generate(barValues.length, (index) {
                                              final val = barValues[index];
                                              final isPeak = index == (barValues.length ~/ 2);
                                              final maxVal = barValues.fold<double>(20.0, (m, e) => e > m ? e : m);
                                              final heightFactor = (val / maxVal).clamp(0.08, 1.0);

                                              return FractionallySizedBox(
                                                heightFactor: heightFactor,
                                                child: Container(
                                                  width: _selectedFilter == 2 ? 18 : 12,
                                                  decoration: BoxDecoration(
                                                    color: isPeak
                                                        ? const Color(0xFFFF4E6A)
                                                        : const Color(0xFFFFE0E6),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Baseline
                                        Container(
                                          height: 1,
                                          color: const Color(0xFFF3F4F6),
                                        ),
                                        const SizedBox(height: 8),
                                        // X-Axis Labels
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: xLabels.map((lbl) => Text(
                                            lbl,
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8C93A3)),
                                          )).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                        child: const Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF4E6A),
                              size: 24,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Your baby's movements are\nwithin your usual range.",
                                style: TextStyle(
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
