import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';

class FeedingTrackerStatsPage extends StatefulWidget {
  const FeedingTrackerStatsPage({super.key});

  @override
  State<FeedingTrackerStatsPage> createState() => _FeedingTrackerStatsPageState();
}

class _FeedingTrackerStatsPageState extends State<FeedingTrackerStatsPage> {
  int _selectedFilter = 0; // 0: Day, 1: Week, 2: Month

  final List<Map<String, dynamic>> _feeds = [
    {
      'time': '1:45 PM',
      'type': 'Breastfeeding',
      'amount': '18',
      'unit': 'min',
      'icon': Icons.water_drop_rounded,
      'isBreastfeeding': true,
    },
    {
      'time': '11:20 AM',
      'type': 'Bottle',
      'amount': '90',
      'unit': 'ml',
      'icon': Icons.local_drink_rounded,
      'isBreastfeeding': false,
    },
    {
      'time': '8:10 AM',
      'type': 'Breastfeeding',
      'amount': '22',
      'unit': 'min',
      'icon': Icons.water_drop_rounded,
      'isBreastfeeding': true,
    },
  ];

  void _showAllFeedsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Feeds History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 16),
              ..._feeds.map((feed) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildFeedRow(feed),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
                        'Feeding Tracker',
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
                        bubblePosition: SpeechBubblePosition.left,
                        height: 320,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── TOP SUMMARY CARD ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FeedingTrackerPage()),
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
                                  color: Color(0xFFEDE9FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_drink_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '6',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E2024),
                                          height: 1.0,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'feeds today',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E2024),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Total feeding time',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF8C93A3),
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    '128 min',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E2024),
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

                    // ─── TODAY'S FEEDS CARD ───
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
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Today's feeds",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E2024),
                                  ),
                                ),
                                Text(
                                  '26 Aug',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8C93A3),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // List of Feeds
                            for (int i = 0; i < _feeds.length; i++) ...[
                              _buildFeedRow(_feeds[i]),
                              if (i < _feeds.length - 1) const SizedBox(height: 14),
                            ],

                            const SizedBox(height: 18),

                            // View All Action
                            GestureDetector(
                              onTap: _showAllFeedsSheet,
                              child: const Text(
                                'View all',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── MOTIVATIONAL MESSAGE CONTAINER ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 24,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "You're doing a great job!\nKeep listening to your baby's needs.",
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

  Widget _buildFeedRow(Map<String, dynamic> feed) {
    final isBreastfeeding = feed['isBreastfeeding'] as bool;
    final icon = feed['icon'] as IconData;
    final time = feed['time'] as String;
    final type = feed['type'] as String;
    final amount = feed['amount'] as String;
    final unit = feed['unit'] as String;

    final iconBg = isBreastfeeding ? const Color(0xFFEDE9FE) : const Color(0xFFFFE4E6);
    final iconColor = isBreastfeeding ? const Color(0xFF8B5CF6) : const Color(0xFFFF4E6A);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2024),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            type,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2024),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9CA3AF),
          size: 20,
        ),
      ],
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
            color: isSelected ? const Color(0xFFEDE9FE) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
