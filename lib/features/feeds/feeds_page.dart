import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FeedType {
  tipCard,
  videoReel,
}

class FeedItemData {
  final String id;
  final FeedType type;
  final String tag;
  final String title;
  final String body;
  final Color backgroundColor;
  final Color? visualTopColor;
  final Color? visualBottomColor;
  final String customVisualType;
  int likes;
  int comments;
  bool isLiked;
  bool isPlaying;
  bool isMuted;

  FeedItemData({
    required this.id,
    required this.type,
    required this.tag,
    required this.title,
    required this.body,
    required this.backgroundColor,
    this.visualTopColor,
    this.visualBottomColor,
    required this.customVisualType,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.isPlaying = true,
    this.isMuted = false,
  });
}

class FeedsPage extends StatefulWidget {
  const FeedsPage({super.key});

  @override
  State<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends State<FeedsPage> with TickerProviderStateMixin {
  late PageController _pageController;

  // Active audio speech reading state
  String? _currentlyReadingId;
  Timer? _speechTimer;
  double _readingProgress = 0.0;

  late List<FeedItemData> _feedItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _feedItems = [
      // 1. Tip Card (Sleeping position) - Screen 1
      FeedItemData(
        id: 'feed_1',
        type: FeedType.tipCard,
        tag: "THIS WEEK'S TIP",
        title: 'Sleep on your left side from now on',
        body:
            'It helps blood reach me better. A folded cloth under your belly makes it comfortable.',
        backgroundColor: Colors.white,
        visualTopColor: const Color(0xFF1B1D45),
        visualBottomColor: const Color(0xFF2A2B66),
        customVisualType: 'sleeping',
        likes: 128,
        comments: 24,
      ),

      // 2. Video Reel (Ragi and jaggery ball) - Screen 2
      FeedItemData(
        id: 'feed_2',
        type: FeedType.videoReel,
        tag: 'RECIPE - REEL',
        title: 'Ragi and jaggery ball',
        body: '4 things from your kitchen. Iron and calcium in one bite.',
        backgroundColor: const Color(0xFF0F4438),
        visualTopColor: const Color(0xFF134E43),
        visualBottomColor: const Color(0xFF082B23),
        customVisualType: 'ragi_bowl',
        likes: 482,
        comments: 56,
      ),

      // 3. Tip Card (Morning Walk) - Screen 3
      FeedItemData(
        id: 'feed_3',
        type: FeedType.tipCard,
        tag: 'EXERCISE TIP',
        title: '15 minute morning walk for healthy blood flow',
        body:
            'Gentle walking keeps your heart active and reduces leg swelling. Stay hydrated!',
        backgroundColor: Colors.white,
        visualTopColor: const Color(0xFF0D563E),
        visualBottomColor: const Color(0xFF09422F),
        customVisualType: 'exercise_geometric',
        likes: 128,
        comments: 24,
      ),

      // 4. Video Reel (Smoothie) - Screen 4
      FeedItemData(
        id: 'feed_4',
        type: FeedType.videoReel,
        tag: 'NUTRITION - REEL',
        title: 'Beetroot & pomegranate smoothie',
        body:
            'Natural hemoglobin booster. Fresh, energizing and easy to make at home.',
        backgroundColor: const Color(0xFF6B0E37),
        visualTopColor: const Color(0xFF7A1441),
        visualBottomColor: const Color(0xFF470622),
        customVisualType: 'smoothie_bowl',
        likes: 482,
        comments: 56,
      ),
    ];
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleReading(FeedItemData item) {
    if (_currentlyReadingId == item.id) {
      // Stop reading
      _speechTimer?.cancel();
      setState(() {
        _currentlyReadingId = null;
        _readingProgress = 0.0;
      });
    } else {
      // Start reading
      _speechTimer?.cancel();
      setState(() {
        _currentlyReadingId = item.id;
        _readingProgress = 0.0;
      });

      _speechTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted) return;
        setState(() {
          _readingProgress += 0.02;
          if (_readingProgress >= 1.0) {
            _currentlyReadingId = null;
            _readingProgress = 0.0;
            t.cancel();
          }
        });
      });
    }
  }

  void _toggleLike(FeedItemData item) {
    setState(() {
      item.isLiked = !item.isLiked;
      if (item.isLiked) {
        item.likes += 1;
      } else {
        item.likes -= 1;
      }
    });
  }

  void _showCommentsModal(BuildContext context, FeedItemData item) {
    final commentController = TextEditingController();
    final List<Map<String, String>> commentsList = [
      {
        'user': 'Priya S.',
        'text': 'This helped me so much in my second trimester! ❤️',
        'time': '2h ago',
      },
      {
        'user': 'Dr. Ananya',
        'text': 'Excellent advice. Pillows between knees also help hip support.',
        'time': '5h ago',
      },
      {
        'user': 'Meera',
        'text': 'Making this recipe today, looks so delicious! ✨',
        'time': '1d ago',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comments (${item.comments})',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Comments list
              Expanded(
                child: ListView.builder(
                  itemCount: commentsList.length,
                  itemBuilder: (_, index) {
                    final c = commentsList[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFFFE4E9),
                            child: Text(
                              c['user']![0],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF4E6A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c['user']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E2024),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c['time']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  c['text']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Comment input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a helpful comment...',
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFFFF4E6A)),
                    onPressed: () {
                      if (commentController.text.trim().isNotEmpty) {
                        setModalState(() {
                          commentsList.insert(0, {
                            'user': 'Mom',
                            'text': commentController.text.trim(),
                            'time': 'Just now',
                          });
                          item.comments += 1;
                        });
                        setState(() {});
                        commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _feedItems.length,
        onPageChanged: (index) {
          // Stop speech reading when swiped to another page
          if (_currentlyReadingId != null) {
            _speechTimer?.cancel();
            setState(() {
              _currentlyReadingId = null;
              _readingProgress = 0.0;
            });
          }
        },
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          if (item.type == FeedType.tipCard) {
            return _buildTipCardView(item);
          } else {
            return _buildVideoReelView(item);
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. NEWS / TIP CARD VIEW (Screens 1 & 3)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTipCardView(FeedItemData item) {
    final isReadingThis = _currentlyReadingId == item.id;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top Visual Section (Night/Forest illustration)
          Expanded(
            flex: 55,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        item.visualTopColor ?? const Color(0xFF1B1D45),
                        item.visualBottomColor ?? const Color(0xFF2A2B66),
                      ],
                    ),
                  ),
                  child: Center(
                    child: _buildCustomVisualIllustration(item.customVisualType),
                  ),
                ),

                // Stars/dots overlay for night illustration
                if (item.customVisualType == 'sleeping') ...[
                  const Positioned(
                    top: 80,
                    left: 120,
                    child: Icon(Icons.circle, color: Colors.white70, size: 4),
                  ),
                  const Positioned(
                    top: 120,
                    right: 140,
                    child: Icon(Icons.circle, color: Colors.white70, size: 3.5),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Content Section (White Background)
          Expanded(
            flex: 48,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag Pill (THIS WEEK'S TIP / EXERCISE TIP)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.tag,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5277),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Headline
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Body Text
                  Text(
                    item.body,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF5A5D64),
                      height: 1.4,
                    ),
                  ),

                  // Audio reading progress indicator if active
                  if (isReadingThis) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _readingProgress,
                        backgroundColor: const Color(0xFFFFF0F3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4E6A)),
                        minHeight: 4,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Bottom Action Row: Listen + Likes/Comments
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Listen Button (with reading animation state)
                      GestureDetector(
                        onTap: () => _toggleReading(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isReadingThis
                                ? const Color(0xFFFF4E6A)
                                : const Color(0xFFFFF0F3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFD2DC),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isReadingThis
                                    ? Icons.pause_rounded
                                    : Icons.volume_up_rounded,
                                color: isReadingThis ? Colors.white : const Color(0xFFFF4E6A),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isReadingThis ? 'Reading...' : 'Listen',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isReadingThis ? Colors.white : const Color(0xFFFF4E6A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Likes & Comments
                      Row(
                        children: [
                          // Like button
                          GestureDetector(
                            onTap: () => _toggleLike(item),
                            child: Row(
                              children: [
                                Icon(
                                  item.isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: item.isLiked
                                      ? const Color(0xFFFF4E6A)
                                      : const Color(0xFF6B7280),
                                  size: 19,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.likes}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Comment button
                          GestureDetector(
                            onTap: () => _showCommentsModal(context, item),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF6B7280),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.comments}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Bottom safe padding for bottom nav bar and floating mic
                  const SizedBox(height: 105),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. VIDEO REEL VIEW (Screens 2 & 4)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildVideoReelView(FeedItemData item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          item.isPlaying = !item.isPlaying;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient Container
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  item.visualTopColor ?? item.backgroundColor,
                  item.visualBottomColor ?? item.backgroundColor,
                ],
              ),
            ),
          ),

          // Center Animated Visual / Illustration (Bowl & food items)
          Center(
            child: _buildCustomVisualIllustration(item.customVisualType),
          ),

          // Pause Indicator Animation (if tapped pause)
          if (!item.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Top Right Audio / Sound Toggle Button
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  item.isMuted = !item.isMuted;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // Bottom Left: Tag, Title, Subtitle Description
          Positioned(
            bottom: 110,
            left: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tag pill (e.g. RECIPE - REEL / NUTRITION - REEL)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.tag,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFCA5A5),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  item.body,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Right: Floating Like & Comment Actions
          Positioned(
            bottom: 110,
            right: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like Button
                GestureDetector(
                  onTap: () => _toggleLike(item),
                  child: Column(
                    children: [
                      Icon(
                        item.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: item.isLiked ? const Color(0xFFFF4E6A) : Colors.white,
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.likes}',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Comment Button
                GestureDetector(
                  onTap: () => _showCommentsModal(context, item),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.comments}',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. CUSTOM MINIMALIST VISUAL ILLUSTRATIONS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCustomVisualIllustration(String visualType) {
    switch (visualType) {
      case 'sleeping':
        // Sleeping figure on pillow under pink blanket
        return SizedBox(
          width: 260,
          height: 180,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Bottom dark sheet base
              Positioned(
                bottom: 0,
                child: Container(
                  width: 320,
                  height: 60,
                  color: const Color(0xFF262758),
                ),
              ),
              // White Pillow
              Positioned(
                bottom: 25,
                left: 10,
                child: Container(
                  width: 90,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Sleeping Head
              Positioned(
                bottom: 45,
                left: 45,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9A8A8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Pink Curved Blanket
              Positioned(
                bottom: 25,
                left: 48,
                child: Container(
                  width: 170,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5277),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(30),
                      right: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'ragi_bowl':
      case 'smoothie_bowl':
        // Minimalist ceramic bowl with warm golden spheres / laddus
        return SizedBox(
          width: 200,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Three golden-yellow laddus/food spheres
              Positioned(
                top: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE58B24),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFACC15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE58B24),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              // Ceramic White/Grey Serving Bowl
              Positioned(
                top: 60,
                child: Container(
                  width: 140,
                  height: 65,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDE3EA),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'exercise_geometric':
        // Modern minimal walking figure with pink head and mint semicircle
        return SizedBox(
          width: 180,
          height: 180,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer circle mint backdrop
                Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5BA387),
                    shape: BoxShape.circle,
                  ),
                ),
                // Pink Head
                Positioned(
                  top: 22,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9A8A8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Bright Mint Semicircle Base
                Positioned(
                  bottom: 22,
                  child: Container(
                    width: 68,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34D399),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(34),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }
}
