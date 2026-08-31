import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';

class AlloBotAskAiTab extends StatefulWidget {
  final VoidCallback onOpenChat;
  final VoidCallback? onOpenMenu;
  final bool initialListening;

  const AlloBotAskAiTab({
    super.key,
    required this.onOpenChat,
    this.onOpenMenu,
    this.initialListening = false,
  });

  @override
  State<AlloBotAskAiTab> createState() => AlloBotAskAiTabState();
}

class AlloBotAskAiTabState extends State<AlloBotAskAiTab> {
  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': null},
    {
      'name': 'Baby',
      'icon': Icons.child_care_rounded,
      'color': const Color(0xFF9333EA),
    },
    {
      'name': 'Diet',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF16A34A),
    },
    {
      'name': 'Health',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFF06B6D4),
    },
  ];

  late bool _isListening;

  @override
  void initState() {
    super.initState();
    _isListening = widget.initialListening;
  }

  final List<Map<String, dynamic>> _recommendedCards = [
    {
      'title': 'Eat healthy',
      'subtitle': 'Meals for week 24',
      'bgColor': const Color(0xFFEBF8F2),
      'asset': 'assets/allobaby/FeedingTracker.png',
      'fallbackIcon': Icons.restaurant_rounded,
      'accentColor': const Color(0xFF10B981),
    },
    {
      'title': 'Baby this week',
      'subtitle': 'Week 24 updates',
      'bgColor': const Color(0xFFF3E8FF),
      'asset': 'assets/allobaby/Pregnancy Care.png',
      'fallbackIcon': Icons.pregnant_woman_rounded,
      'accentColor': const Color(0xFF8B5CF6),
    },
    {
      'title': 'Daily routine',
      'subtitle': 'Hydration & rest',
      'bgColor': const Color(0xFFFFF1F2),
      'asset': 'assets/allobaby/daily_activity.png',
      'fallbackIcon': Icons.access_time_rounded,
      'accentColor': const Color(0xFFFF5277),
    },
    {
      'title': 'Kick counter',
      'subtitle': 'Track active hours',
      'bgColor': const Color(0xFFEFF6FF),
      'asset': 'assets/allobaby/KickCounter.png',
      'fallbackIcon': Icons.directions_walk_rounded,
      'accentColor': const Color(0xFF3B82F6),
    },
  ];

  void toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  // Menu / Back Button
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF1E2024),
                        size: 22,
                      ),
                    ),
                  ),

                  // Center Title & Subtitle
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'AlloBot',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF4E6A),
                          ),
                        ),
                        Text(
                          'Your empathetic pregnancy companion',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 40), // Balancer
                ],
              ),
            ),

            // ─── SCROLLABLE MAIN CONTENT ───
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ─── DEFAULT FORMAT BABY HERO BANNER ───
                    const BabyHeroBanner(
                      speechText:
                          "I'm here, Amma! 💕\nHow can I support you and baby today?",
                      bubblePosition: SpeechBubblePosition.left,
                      height: 320,
                      greetingText: "",
                    ),
                    const SizedBox(height: 20),

                    // ─── CATEGORY FILTER CAPSULES ───
                    Row(
                      children: _categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cat = entry.value;
                        final isSelected = _selectedCategoryIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                right: index < _categories.length - 1 ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF4E6A)
                                      : const Color(0xFFE5E7EB),
                                  width: isSelected ? 1.6 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(
                                            0xFFFF4E6A,
                                          ).withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (cat['icon'] != null) ...[
                                    Icon(
                                      cat['icon'] as IconData,
                                      size: 16,
                                      color: cat['color'] as Color,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    cat['name'] as String,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFFF4E6A)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // ─── RECOMMENDED FOR YOU HEADER ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended for you',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2024),
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onOpenChat,
                          child: const Text(
                            'See all >',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF4E6A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ─── RECOMMENDED HORIZONTAL CARDS (FLUSH LEFT) ───
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _recommendedCards.length,
                        itemBuilder: (context, index) {
                          final item = _recommendedCards[index];
                          final assetPath = item['asset'] as String?;
                          final fallbackIcon = item['fallbackIcon'] as IconData;
                          final accentColor = item['accentColor'] as Color;

                          return Container(
                            width: 172,
                            margin: EdgeInsets.only(
                              right: index < _recommendedCards.length - 1
                                  ? 14
                                  : 0,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item['bgColor'] as Color,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: accentColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: assetPath != null
                                            ? Image.asset(
                                                assetPath,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Icon(
                                                        fallbackIcon,
                                                        size: 38,
                                                        color: accentColor,
                                                      );
                                                    },
                                              )
                                            : Icon(
                                                fallbackIcon,
                                                size: 38,
                                                color: accentColor,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E2024),
                                            ),
                                          ),
                                          Text(
                                            item['subtitle'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: widget.onOpenChat,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: Color(0xFF1E2024),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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

      // ─── SMOOTH SPRING TRANSITION FOR LISTENING CARD ───
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation =
              Tween<Offset>(
                begin: const Offset(0.0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              );

          final scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        child: _isListening
            ? KeyedSubtree(
                key: const ValueKey('active_listening_card'),
                child: _buildListeningPill(),
              )
            : const SizedBox.shrink(key: ValueKey('inactive_listening_card')),
      ),
    );
  }

  // Listening Pill
  Widget _buildListeningPill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pink waveform bars |||||
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStaticWaveBar(14),
              const SizedBox(width: 3),
              _buildStaticWaveBar(22),
              const SizedBox(width: 3),
              _buildStaticWaveBar(30),
              const SizedBox(width: 3),
              _buildStaticWaveBar(18),
              const SizedBox(width: 3),
              _buildStaticWaveBar(26),
              const SizedBox(width: 3),
              _buildStaticWaveBar(12),
            ],
          ),
          const SizedBox(width: 14),

          // Bold Text: "Listening..."
          const Expanded(
            child: Text(
              'Listening...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2024),
              ),
            ),
          ),

          // Keyboard Button (Type instead -> Open Chat)
          GestureDetector(
            onTap: () {
              setState(() => _isListening = false);
              widget.onOpenChat();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.keyboard_alt_outlined,
                color: Color(0xFF1E2024),
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Dark/Black Circular Stop Button
          GestureDetector(
            onTap: toggleListening,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.stop_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticWaveBar(double height) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5277),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
