import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/kick_counter/kick_counter_stats_page.dart';
import 'package:allomom/controllers/health_vital_controller.dart';

class KickCounterPage extends StatefulWidget {
  const KickCounterPage({super.key});

  @override
  State<KickCounterPage> createState() => _KickCounterPageState();
}

class _KickCounterPageState extends State<KickCounterPage>
    with SingleTickerProviderStateMixin {
  int _kickCount = 0;
  final int _kickGoal = 10;
  int _bestCount = 10;
  String _startTime = '--';
  final List<String> _kickTimestamps = [];

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final vitals = HealthVitalsController.instance;
    if (vitals.hasKickCount && vitals.kickCountValue > _bestCount) {
      _bestCount = vitals.kickCountValue;
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveKickSession() async {
    if (_kickCount == 0) return;
    await HealthVitalsController.instance.addKickCountEntry(
      count: _kickCount,
      extraData: {
        'count': _kickCount,
        'timestamps': _kickTimestamps,
        'startTime': _startTime,
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$_kickCount kicks saved to Vitals Stream! 👶'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF4E6A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onKickPressed() {
    _animController.forward().then((_) => _animController.reverse());
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';

    setState(() {
      if (_startTime == '--' || _startTime.isEmpty) {
        _startTime = timeStr;
      }
      _kickCount++;
      _kickTimestamps.insert(0, timeStr);
      if (_kickCount > _bestCount) {
        _bestCount = _kickCount;
      }
    });

    if (_kickCount == _kickGoal) {
      _saveKickSession();
      _showGoalReachedDialog();
    }
  }

  void _resetKicks() {
    setState(() {
      _kickCount = 0;
      _startTime = '--';
      _kickTimestamps.clear();
    });
  }

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBF0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFFFF4E6A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Goal Achieved! 🎉',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2022),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You reached 10 kicks today! Your baby is active and healthy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4E6A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),

              // Baby Hero Card
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: BabyHeroBanner(
                  speechText: "Let's count\ntogether! ❤️",
                  bubblePosition: SpeechBubblePosition.topCenter,
                  height: 270,
                ),
              ),

              const SizedBox(height: 28),

              // "Today's kicks" Title
              const Text(
                "Today's kicks",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2229),
                ),
              ),

              const SizedBox(height: 10),

              // Speed Lines + Large Pink Kick Count
              _buildKickCountDisplay(),

              const SizedBox(height: 24),

              // Big Pink Glowing Kick Button
              _buildGlowingKickButton(),

              const SizedBox(height: 14),

              // Subtitle
              const Text(
                'Tap when you feel a kick',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF8B92A2),
                ),
              ),

              const SizedBox(height: 18),

              // Save Session Button & Reset
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveKickSession,
                        icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Save Session',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4E6A),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _resetKicks,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        side: const BorderSide(color: Color(0xFFFF4E6A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFFFF4E6A), size: 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Bottom Stats Row Card
              _buildBottomStatsCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── APP BAR HEADER ───────────────────────────────────────
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFFFF4E6A),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'Kick Counter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF4E6A),
                  ),
                ),
                Text(
                  "Count and track your baby's kicks",
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
                MaterialPageRoute(builder: (_) => const KickCounterStatsPage()),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(
              Icons.bar_chart_rounded,
              size: 22,
              color: Color(0xFFFF4E6A),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Kick Session Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.bar_chart_rounded,
                            color: Color(0xFFFF4E6A),
                          ),
                          title: const Text('View Statistics & Trends'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const KickCounterStatsPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.restart_alt_rounded,
                            color: Color(0xFFFF4E6A),
                          ),
                          title: const Text('Reset Counter'),
                          onTap: () {
                            Navigator.pop(context);
                            _resetKicks();
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF7E57C2),
                          ),
                          title: Text(
                            'View Timestamps (${_kickTimestamps.length})',
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showTimestampsDialog();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 20,
              color: Color(0xFF8C93A3),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimestampsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Recorded Kicks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (_kickTimestamps.isEmpty)
                const Text(
                  'No kicks recorded yet today.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _kickTimestamps.length,
                    itemBuilder: (context, idx) {
                      return ListTile(
                        leading: const Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFFFF4E6A),
                        ),
                        title: Text(
                          'Kick #${_kickTimestamps.length - idx}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Text(
                          _kickTimestamps[idx],
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── KICK COUNT DISPLAY ───────────────────────────────────
  Widget _buildKickCountDisplay() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left speed lines
            CustomPaint(
              size: const Size(30, 20),
              painter: _SpeedLinesPainter(isLeft: true),
            ),
            const SizedBox(width: 14),
            // Huge Pink Number
            Text(
              '$_kickCount',
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF3B5C),
                height: 1.0,
              ),
            ),
            const SizedBox(width: 14),
            // Right speed lines
            CustomPaint(
              size: const Size(30, 20),
              painter: _SpeedLinesPainter(isLeft: false),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'KICKS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Color(0xFF8B92A2),
          ),
        ),
      ],
    );
  }

  // ─── GLOWING KICK BUTTON ──────────────────────────────────
  Widget _buildGlowingKickButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _onKickPressed,
        child: Container(
          width: 136,
          height: 136,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF4E6A).withValues(alpha: 0.18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4E6A).withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF627C),
                    Color(0xFFFF3B5C),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3B5C).withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'KICK',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── BOTTOM STATS CARD ────────────────────────────────────
  Widget _buildBottomStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9FA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFEDF0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Started At
            Expanded(
              child: _buildStatColumn(
                icon: Icons.access_time_rounded,
                label: 'STARTED AT',
                value: _startTime,
              ),
            ),
            Container(width: 1, height: 36, color: const Color(0xFFFFE0E6)),
            // Goal
            Expanded(
              child: _buildStatColumn(
                icon: Icons.bolt_rounded,
                label: 'GOAL',
                value: '$_kickGoal kicks',
              ),
            ),
            Container(width: 1, height: 36, color: const Color(0xFFFFE0E6)),
            // Best Count
            Expanded(
              child: _buildStatColumn(
                icon: Icons.groups_rounded,
                label: 'BEST COUNT',
                value: '$_bestCount kicks',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBF0),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFFFF4E6A)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B92A2),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2229),
          ),
        ),
      ],
    );
  }
}

class _SpeedLinesPainter extends CustomPainter {
  final bool isLeft;
  _SpeedLinesPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB3C1)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (isLeft) {
      canvas.drawLine(
        Offset(size.width, size.height * 0.2),
        Offset(0, size.height * 0.05),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, size.height * 0.5),
        Offset(size.width * 0.2, size.height * 0.5),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, size.height * 0.8),
        Offset(0, size.height * 0.95),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(0, size.height * 0.2),
        Offset(size.width, size.height * 0.05),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * 0.5),
        Offset(size.width * 0.8, size.height * 0.5),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * 0.8),
        Offset(size.width, size.height * 0.95),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
