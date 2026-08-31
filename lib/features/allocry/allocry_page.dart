import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';

class AlloCryPage extends StatefulWidget {
  const AlloCryPage({super.key});

  @override
  State<AlloCryPage> createState() => _AlloCryPageState();
}

class _AlloCryPageState extends State<AlloCryPage> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  int _listenCountdown = 5;
  Timer? _timer;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _recentChecks = [
    {
      'reason': 'Hungry',
      'time': 'Today, 2:10 PM',
      'badge': 'High',
      'badgeColor': const Color(0xFFFF4E6A),
      'badgeBg': const Color(0xFFFFEBF0),
      'icon': Icons.push_pin_outlined,
      'iconColor': const Color(0xFFFF4E6A),
      'confidence': '92%',
      'tip': 'Offer feed. Baby shows hunger cue signs.',
    },
    {
      'reason': 'Sleepy',
      'time': 'Today, 11:40 AM',
      'badge': 'Medium',
      'badgeColor': const Color(0xFFFF9800),
      'badgeBg': const Color(0xFFFFF3E0),
      'icon': Icons.nightlight_round_outlined,
      'iconColor': const Color(0xFF7E57C2),
      'confidence': '84%',
      'tip': 'Dim lights and swaddle for comfort.',
    },
    {
      'reason': 'Needs comfort',
      'time': 'Yesterday, 8:15 PM',
      'badge': 'Low',
      'badgeColor': const Color(0xFF2E7D32),
      'badgeBg': const Color(0xFFE8F5E9),
      'icon': Icons.favorite_border_rounded,
      'iconColor': const Color(0xFF26A69A),
      'confidence': '68%',
      'tip': 'Gentle rocking and skin-to-skin touch.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening(detected: false);
    } else {
      setState(() {
        _isListening = true;
        _listenCountdown = 4;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_listenCountdown <= 1) {
          timer.cancel();
          _stopListening(detected: true);
        } else {
          setState(() {
            _listenCountdown--;
          });
        }
      });
    }
  }

  void _stopListening({required bool detected}) {
    _timer?.cancel();
    setState(() {
      _isListening = false;
    });

    if (detected) {
      final newCheck = {
        'reason': 'Hungry',
        'time': 'Just now',
        'badge': 'High',
        'badgeColor': const Color(0xFFFF4E6A),
        'badgeBg': const Color(0xFFFFEBF0),
        'icon': Icons.restaurant_outlined,
        'iconColor': const Color(0xFFFF4E6A),
        'confidence': '94%',
        'tip': 'Rhythmic crying pattern matched hunger cries.',
      };

      setState(() {
        _recentChecks.insert(0, newCheck);
      });

      _showCryAnalysisResultDialog(newCheck);
    }
  }

  void _showCryAnalysisResultDialog(Map<String, dynamic> check) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBF0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFFFF4E6A), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Cry Identified: ${check['reason']}',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E2022)),
              ),
              const SizedBox(height: 6),
              Text(
                'Confidence: ${check['confidence']} match',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  check['tip'] as String,
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF4A4E5A), height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4E6A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Got it, thanks!',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
                  speechText: "I'm listening,\nAmma. ❤️",
                  bubblePosition: SpeechBubblePosition.right,
                  height: 230,
                ),
              ),

              const SizedBox(height: 28),

              // Title Section
              Text(
                'Understand the cry',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2229),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isListening ? 'Listening to baby ($_listenCountdown s)...' : 'Tap the mic to listen to your baby',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF8B92A2),
                ),
              ),

              const SizedBox(height: 24),

              // Big Pulsating Glowing Mic Button
              _buildGlowingMicButton(),

              const SizedBox(height: 32),

              // Recent Checks Section Card
              _buildRecentChecksCard(),

              const SizedBox(height: 16),

              // Bottom Learn More Card
              _buildWhyDoBabiesCryBanner(),

              const SizedBox(height: 36),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFFFF4E6A)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  'AlloCry',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
                Text(
                  "Understand your baby's cry",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF8C93A3),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AlloCry AI is calibrated for 0-12 months babies.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF8C93A3)),
          ),
        ],
      ),
    );
  }

  // ─── GLOWING MIC BUTTON ────────────────────────────────────
  Widget _buildGlowingMicButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowScale = _isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0;
        final glowOpacity = _isListening ? (0.2 + (_pulseController.value * 0.2)) : 0.15;

        return GestureDetector(
          onTap: _toggleListening,
          child: Transform.scale(
            scale: glowScale,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4E6A).withValues(alpha: glowOpacity),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4E6A).withValues(alpha: _isListening ? 0.4 : 0.2),
                    blurRadius: _isListening ? 36 : 24,
                    spreadRadius: _isListening ? 8 : 4,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF4E6A).withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: Container(
                      width: 72,
                      height: 72,
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
                            color: const Color(0xFFFF3B5C).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── RECENT CHECKS CARD ────────────────────────────────────
  Widget _buildRecentChecksCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFE3E8), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFFF4E6A)),
                const SizedBox(width: 8),
                Text(
                  'Recent checks',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2F38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._recentChecks.map((check) => _buildCheckItem(check)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(Map<String, dynamic> check) {
    return GestureDetector(
      onTap: () => _showCryAnalysisResultDialog(check),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (check['iconColor'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                check['icon'] as IconData,
                color: check['iconColor'] as Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    check['reason'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E2229),
                    ),
                  ),
                  Text(
                    check['time'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9EA3B0),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: check['badgeBg'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                check['badge'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: check['badgeColor'] as Color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD0DC), size: 20),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM BANNER ─────────────────────────────────────────
  Widget _buildWhyDoBabiesCryBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFDCE4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFF4E6A), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Why do babies cry?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2F38),
                ),
              ),
            ),
            Text(
              'Learn more >',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF4E6A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
