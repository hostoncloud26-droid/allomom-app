import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';

class KickCounterStatsPage extends StatefulWidget {
  const KickCounterStatsPage({super.key});

  @override
  State<KickCounterStatsPage> createState() => _KickCounterStatsPageState();
}

class _KickCounterStatsPageState extends State<KickCounterStatsPage> {
  int _selectedFilter = 0; // 0: Day, 1: Week, 2: Month
  int _movementCount = 7;

  final List<double> _hourlyMovements = [
    0.0, // 12 AM
    3.0, // 3 AM
    7.0, // 6 AM
    5.0, // 9 AM
    9.0, // 11 AM
    3.0, // 1 PM
    2.0, // 3 PM
    11.0, // 6 PM (peak)
    3.0, // 8 PM
    2.0, // 10 PM
  ];

  void _logMovement() {
    setState(() {
      _movementCount++;
      _hourlyMovements[7] += 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Movement logged successfully! 👶'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF4E6A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  IconButton(
                    onPressed: () {
                      showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now(),
                      );
                    },
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF1E2024),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // ─── SCROLLABLE BODY ───
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Baby Hero Banner
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: BabyHeroBanner(
                        speechText: "Week 24, Amma!\nWe're growing together. Can you feel the kicks?",
                        bubblePosition: SpeechBubblePosition.topCenter,
                        height: 270,
                      ),
                    ),

                    const SizedBox(height: 16),

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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFE4E6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pets_rounded,
                                  color: Color(0xFFFF4E6A),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$_movementCount',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E2024),
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'movements',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E2024),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'today',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8C93A3),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF8C93A3),
                                size: 26,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── FILTER TABS (Day / Week / Month) ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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

                    const SizedBox(height: 16),

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
                            const Text(
                              'Today, 26 Aug',
                              style: TextStyle(
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
                                            children: List.generate(_hourlyMovements.length, (index) {
                                              final val = _hourlyMovements[index];
                                              final isPeak = index == 7; // 6 PM peak
                                              final heightFactor = (val / 20.0).clamp(0.05, 1.0);

                                              return FractionallySizedBox(
                                                heightFactor: heightFactor,
                                                child: Container(
                                                  width: 10,
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
                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('12 AM', style: TextStyle(fontSize: 10.5, color: Color(0xFF8C93A3))),
                                            Text('6 AM', style: TextStyle(fontSize: 10.5, color: Color(0xFF8C93A3))),
                                            Text('12 PM', style: TextStyle(fontSize: 10.5, color: Color(0xFF8C93A3))),
                                            Text('6 PM', style: TextStyle(fontSize: 10.5, color: Color(0xFF8C93A3))),
                                            Text('12 AM', style: TextStyle(fontSize: 10.5, color: Color(0xFF8C93A3))),
                                          ],
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
