import 'dart:async';
import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_stats_page.dart';

class FeedingTrackerPage extends StatefulWidget {
  const FeedingTrackerPage({super.key});

  @override
  State<FeedingTrackerPage> createState() => _FeedingTrackerPageState();
}

class _FeedingTrackerPageState extends State<FeedingTrackerPage> {
  int _selectedFeedType = 0; // 0: Breast, 1: Bottle, 2: Solids
  bool _isLeftTimerRunning = false;
  bool _isRightTimerRunning = false;
  int _leftSeconds = 0;
  int _rightSeconds = 0;
  Timer? _timer;

  int _bottleAmountMl = 120;

  final List<Map<String, dynamic>> _recentFeeds = [
    {
      'type': 'Breastfeeding',
      'detail': 'Left: 12 min · Right: 8 min',
      'time': 'Today, 1:30 PM',
      'icon': Icons.child_care_rounded,
      'color': const Color(0xFFFF4E6A),
      'amount': '20 min',
    },
    {
      'type': 'Bottle (Expressed)',
      'detail': 'Warm breastmilk',
      'time': 'Today, 10:15 AM',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF3898EC),
      'amount': '120 ml',
    },
    {
      'type': 'Breastfeeding',
      'detail': 'Left: 15 min',
      'time': 'Today, 6:45 AM',
      'icon': Icons.child_care_rounded,
      'color': const Color(0xFFFF4E6A),
      'amount': '15 min',
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer({required bool isLeft}) {
    _timer?.cancel();
    setState(() {
      if (isLeft) {
        _isLeftTimerRunning = true;
        _isRightTimerRunning = false;
      } else {
        _isRightTimerRunning = true;
        _isLeftTimerRunning = false;
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_isLeftTimerRunning) _leftSeconds++;
        if (_isRightTimerRunning) _rightSeconds++;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isLeftTimerRunning = false;
      _isRightTimerRunning = false;
    });
  }

  void _saveFeedSession() {
    _pauseTimer();
    final totalMin = ((_leftSeconds + _rightSeconds) / 60).ceil();
    if (totalMin > 0 || _selectedFeedType == 1) {
      final now = TimeOfDay.now();
      final timeStr = 'Today, ${now.format(context)}';

      setState(() {
        if (_selectedFeedType == 0) {
          _recentFeeds.insert(0, {
            'type': 'Breastfeeding',
            'detail': 'Left: ${(_leftSeconds / 60).ceil()} min · Right: ${(_rightSeconds / 60).ceil()} min',
            'time': timeStr,
            'icon': Icons.child_care_rounded,
            'color': const Color(0xFFFF4E6A),
            'amount': '$totalMin min',
          });
          _leftSeconds = 0;
          _rightSeconds = 0;
        } else if (_selectedFeedType == 1) {
          _recentFeeds.insert(0, {
            'type': 'Bottle Feed',
            'detail': 'Formula / Milk',
            'time': timeStr,
            'icon': Icons.water_drop_rounded,
            'color': const Color(0xFF3898EC),
            'amount': '$_bottleAmountMl ml',
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feed recorded successfully! 🍼')),
      );
    }
  }

  String _formatTime(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),

              // Hero Baby Card
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: BabyHeroBanner(
                  speechText: "Time for\nbaby's feed! 🍼",
                  bubblePosition: SpeechBubblePosition.topCenter,
                  height: 270,
                ),
              ),

              const SizedBox(height: 20),

              // Type Selector Tabs
              _buildTypeSelector(),

              const SizedBox(height: 20),

              // Active Tracker Component
              if (_selectedFeedType == 0)
                _buildBreastfeedingTracker()
              else if (_selectedFeedType == 1)
                _buildBottleTracker()
              else
                _buildSolidsTracker(),

              const SizedBox(height: 28),

              // Recent Feeds List
              _buildRecentFeedsSection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFFFF4E6A)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Feeding Tracker',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF4E6A),
                  ),
                ),
                Text(
                  'Log breast, bottle & solid feeds',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C93A3),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedingTrackerStatsPage()),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.bar_chart_rounded, size: 22, color: Color(0xFFFF4E6A)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = ['Breast', 'Bottle', 'Solids'];
    final icons = [Icons.child_care_rounded, Icons.water_drop_rounded, Icons.restaurant_rounded];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(types.length, (i) {
            final isSelected = _selectedFeedType == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFeedType = i;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF4E6A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[i],
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF8C93A3),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        types[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF4A4E5A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBreastfeedingTracker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSideTimerCard(
                    side: 'Left',
                    seconds: _leftSeconds,
                    isRunning: _isLeftTimerRunning,
                    onTap: () {
                      if (_isLeftTimerRunning) {
                        _pauseTimer();
                      } else {
                        _startTimer(isLeft: true);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSideTimerCard(
                    side: 'Right',
                    seconds: _rightSeconds,
                    isRunning: _isRightTimerRunning,
                    onTap: () {
                      if (_isRightTimerRunning) {
                        _pauseTimer();
                      } else {
                        _startTimer(isLeft: false);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_isLeftTimerRunning || _isRightTimerRunning)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFFF4E6A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _pauseTimer,
                      icon: const Icon(Icons.pause_rounded, color: Color(0xFFFF4E6A)),
                      label: const Text('Pause', style: TextStyle(color: Color(0xFFFF4E6A), fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (_isLeftTimerRunning || _isRightTimerRunning) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFFF4E6A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveFeedSession,
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: const Text('Save Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideTimerCard({
    required String side,
    required int seconds,
    required bool isRunning,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isRunning ? const Color(0xFFFFF0F3) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRunning ? const Color(0xFFFF4E6A) : const Color(0xFFF0F1F5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              side,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isRunning ? const Color(0xFFFF4E6A) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(seconds),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isRunning ? const Color(0xFFFF4E6A) : const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isRunning ? const Color(0xFFFF4E6A) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isRunning)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Icon(
                isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isRunning ? Colors.white : const Color(0xFFFF4E6A),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottleTracker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            const Text(
              'Amount Fed',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            Text(
              '$_bottleAmountMl ml',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFFFF4E6A)),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _bottleAmountMl.toDouble(),
              min: 30,
              max: 300,
              divisions: 27,
              activeColor: const Color(0xFFFF4E6A),
              inactiveColor: const Color(0xFFFFE0E6),
              onChanged: (v) {
                setState(() {
                  _bottleAmountMl = v.round();
                });
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFFF4E6A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _saveFeedSession,
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                label: const Text('Log Bottle Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolidsTracker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 48, color: Color(0xFFFF4E6A)),
            const SizedBox(height: 12),
            const Text(
              'Solid Foods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E2024)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fruit purees, mashed veggies, oats porridge',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF8C93A3)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFFF4E6A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solid feed recorded! 🥣')),
                  );
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Log Meal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFeedsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Feeds',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E2024)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedingTrackerStatsPage()),
                  );
                },
                child: const Text(
                  'View Stats >',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF4E6A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._recentFeeds.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (f['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['type'] as String,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF1E2024)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f['detail'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8C93A3)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          f['amount'] as String,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF4E6A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f['time'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8C93A3)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
