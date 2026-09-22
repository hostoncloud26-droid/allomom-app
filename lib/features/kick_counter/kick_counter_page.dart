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
    with TickerProviderStateMixin {
  int _kickCount = 0;
  int _bestCount = 10;
  String _startTime = '--';
  final List<String> _kickTimestamps = [];

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  /// The ring that travels out from the button on every tap, so a kick leaves
  /// a mark on the screen instead of only bumping a number.
  late AnimationController _rippleController;

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _saveKickSession() async {
    if (_kickCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No kicks counted yet — tap the button first'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF8B92A2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
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
    _rippleController.forward(from: 0);
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
  }

  void _resetKicks() {
    setState(() {
      _kickCount = 0;
      _startTime = '--';
      _kickTimestamps.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            // The baby takes whatever the counter below does not need, so the
            // whole screen fits without scrolling on a short phone and still
            // fills a tall one.
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: BabyHeroBanner(
                  speechText: "Let's count\ntogether! ❤️",
                  bubblePosition: SpeechBubblePosition.topCenter,
                  expand: true,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildCounterSection(),
          ],
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
  // ─── THE TALLY ────────────────────────────────────────────
  //
  // The number carries the screen, so it gets the size and the only warm
  // colour above the button. The unit sits under it in plain grey rather than
  // being flanked by decoration.
  Widget _buildKickCountDisplay() {
    return Column(
      children: [
        Text(
          '$_kickCount',
          style: const TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFF3B5C),
            height: 1.0,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _kickCount == 1 ? 'kick counted today' : 'kicks counted today',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9AA1AE),
          ),
        ),
      ],
    );
  }

  // ─── KICK BUTTON ──────────────────────────────────────────
  //
  // Two hairline rings and a solid core, instead of the blurred halo that used
  // to sit behind it — a wide blur over a translucent disc left a visible edge
  // partway through the glow. Each tap sends one ring outwards and fades it.
  Widget _buildKickButton() {
    const accent = Color(0xFFFF3B5C);

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(142, accent.withValues(alpha: 0.10)),
          _ring(121, accent.withValues(alpha: 0.18)),

          // The ring a tap sends out.
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, _) {
              final t = _rippleController.value;
              if (t == 0 || t == 1) return const SizedBox.shrink();
              final eased = Curves.easeOutCubic.transform(t);
              return _ring(
                100 + 50 * eased,
                accent.withValues(alpha: 0.5 * (1 - t)),
                width: 2,
              );
            },
          ),

          // The core.
          ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _onKickPressed,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF7189), accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'KICK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, Color color, {double width = 1}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: width),
      ),
    );
  }

  // ─── COUNTER SECTION ──────────────────────────────────────
  //
  // Flat on the page: a quiet section label, the tally, the button, the two
  // actions and the three numbers. The pink is spent on the count and the
  // button alone, so everything else can be grey and let those two carry it.
  Widget _buildCounterSection() {
    final hasKicks = _kickCount > 0;
    final lastKick = _kickTimestamps.isEmpty ? '--' : _kickTimestamps.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section label and the live state of the session.
          Row(
            children: [
              const Expanded(
                child: Text(
                  "TODAY'S KICKS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Color(0xFF9AA1AE),
                  ),
                ),
              ),
              _buildSessionPill(hasKicks),
            ],
          ),

          const SizedBox(height: 12),

          _buildKickCountDisplay(),

          const SizedBox(height: 10),

          _buildKickButton(),

          const SizedBox(height: 6),

          const Text(
            'Tap when you feel a kick',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF9AA1AE)),
          ),

          const SizedBox(height: 16),

          // Save & Reset — one filled action, one quiet one.
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveKickSession,
                    icon: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B5C),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                width: 48,
                child: OutlinedButton(
                  onPressed: _resetKicks,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Color(0xFFE6E8EE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF6B7280),
                    size: 19,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(height: 1, color: const Color(0xFFF0F1F5)),

          const SizedBox(height: 14),

          // ─── SESSION STATS ───
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatColumn(label: 'STARTED', value: _startTime),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFF0F1F5),
                ),
                Expanded(
                  child: _buildStatColumn(label: 'LAST KICK', value: lastKick),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFF0F1F5),
                ),
                Expanded(
                  child: _buildStatColumn(
                    label: 'BEST',
                    value: '$_bestCount kicks',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Says what the session is doing right now, next to its title.
  Widget _buildSessionPill(bool hasKicks) {
    final label = hasKicks ? 'Counting' : 'Ready';
    final color =
        hasKicks ? const Color(0xFFFF4E6A) : const Color(0xFF8B92A2);
    final background =
        hasKicks ? const Color(0xFFFFE4E9) : const Color(0xFFF1F3F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({required String label, required String value}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: Color(0xFFA7ADBA),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2229),
          ),
        ),
      ],
    );
  }
}
