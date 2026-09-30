import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:allomom/api/content_api.dart';
import 'package:allomom/api/response.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/controllers/theme_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/feeds/comments_sheet.dart';
import 'package:allomom/models/feed_content.dart';

/// The vertical feed of tips and reels.
///
/// On the Feeds tab it loads `/me/content` itself. Pushed as its own route
/// (see [FeedsPage.open]) it starts from a list someone else already loaded
/// — a community's posts — at the one she tapped, and keeps paging through
/// [entityId]'s content from there.
class FeedsPage extends StatefulWidget {
  const FeedsPage({
    super.key,
    this.entityId,
    this.initialItems,
    this.initialIndex = 0,
    this.initialPage = 1,
    this.initialHasMore = false,
  });

  /// Only this entity's content.
  final String? entityId;

  /// Items already loaded by the opener; when set, the page runs full-screen
  /// with a back button instead of inside the tab shell.
  final List<FeedContent>? initialItems;
  final int initialIndex;

  /// The last page [initialItems] came from, and whether there are more.
  final int initialPage;
  final bool initialHasMore;

  /// Opens [items] at [index] as a full-screen feed.
  static Future<void> open(
    BuildContext context, {
    required List<FeedContent> items,
    required int index,
    String? entityId,
    int page = 1,
    bool hasMore = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedsPage(
          entityId: entityId,
          initialItems: items,
          initialIndex: index,
          initialPage: page,
          initialHasMore: hasMore,
        ),
      ),
    );
  }

  @override
  State<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends State<FeedsPage> with WidgetsBindingObserver {
  AppPalette get _p => context.palette;

  static const _pageSize = 10;

  /// The next page is fetched once she is this close to the end, so the
  /// feed keeps going without her ever landing on the loader.
  static const _loadMoreThreshold = 3;

  /// Reels this many pages either side of the current one keep a live
  /// player, so the next swipe starts without a buffering pause.
  static const _preloadRadius = 1;

  late final PageController _pageController;

  bool get _standalone => widget.initialItems != null;

  List<FeedContent> _items = [];
  int _page = 0;
  int _currentIndex = 0;
  bool _loading = true;
  bool _loadFailed = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  bool _hasMore = false;
  int _requestId = 0;

  // Reel playback. Players are keyed by content id and only exist for reels
  // near the current page; the rest are disposed as she scrolls.
  final Map<int, VideoPlayerController> _videos = {};
  final Set<int> _failedVideos = {};
  final Set<int> _pausedByUser = {};

  /// The reel whose caption (tag, title, description) she opened with the
  /// info button. Captions stay hidden otherwise so they don't sit on top of
  /// text burned into the video.
  int? _captionOpenId;

  /// Items with a like or unlike in flight, so a double tap sends one.
  final Set<int> _liking = {};
  bool _muted = false;
  bool _appActive = true;
  bool _routeVisible = true;

  // Active audio speech reading state
  int? _currentlyReadingId;
  Timer? _speechTimer;
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final initial = widget.initialItems;
    if (initial != null) {
      _items = [...initial];
      _page = widget.initialPage;
      _hasMore = widget.initialHasMore;
      _loading = false;
      _currentIndex = widget.initialIndex.clamp(0, _items.isEmpty ? 0 : _items.length - 1);
      _pageController = PageController(initialPage: _currentIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncVideos();
      });
      return;
    }
    _pageController = PageController();

    // What the feed is, and — when she is offline — which part of it still
    // works. The offline line is the more useful one to hear first, so it
    // replaces the tour rather than following it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      speak(
        ConnectionController.instance.isInternetAvailable
            ? NarrationKeys.pgFeedsOpen
            : NarrationKeys.pgFeedsOffline,
      );
    });

    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A page or sheet pushed over the feed silences the reel behind it.
    final visible = ModalRoute.of(context)?.isCurrent ?? true;
    if (visible != _routeVisible) {
      _routeVisible = visible;
      _syncPlayback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncPlayback();
    // Card carousels read [_appActive] when they build.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speechTimer?.cancel();
    _disposeVideos();
    _pageController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // LOADING & PAGINATION
  // ═══════════════════════════════════════════════════════════════════

  bool _hasNextPage(APIResponse res, int count) {
    final p = res.pagination;
    if (p != null && p.pages > 0) return p.page < p.pages;
    return count == _pageSize;
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final res = await ContentApi.getMyContent(
      page: 1,
      size: _pageSize,
      entityId: widget.entityId,
    );
    if (!mounted || requestId != _requestId) return;

    _disposeVideos();
    _failedVideos.clear();
    _pausedByUser.clear();
    final items = res.success ? FeedContent.listFrom(res.items) : <FeedContent>[];
    setState(() {
      _loading = false;
      _loadFailed = !res.success;
      _loadingMore = false;
      _loadMoreFailed = false;
      _page = 1;
      _currentIndex = 0;
      _items = items;
      _hasMore = res.success && _hasNextPage(res, items.length);
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    _syncVideos();
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() {
      _loadingMore = true;
      _loadMoreFailed = false;
    });
    final res = await ContentApi.getMyContent(
      page: _page + 1,
      size: _pageSize,
      entityId: widget.entityId,
    );
    if (!mounted || requestId != _requestId) return;

    // A page can overlap the last one if content was published in between.
    final seen = _items.map((c) => c.id).toSet();
    final items = res.success
        ? FeedContent.listFrom(res.items).where((c) => !seen.contains(c.id))
        : <FeedContent>[];
    setState(() {
      _loadingMore = false;
      _loadMoreFailed = !res.success;
      if (res.success) {
        _page += 1;
        _items = [..._items, ...items];
        _hasMore = _hasNextPage(res, res.items is List ? res.items.length : 0);
      }
    });
    _syncVideos();
  }

  void _onPageChanged(int index) {
    _currentIndex = index;
    _pausedByUser.clear();
    _captionOpenId = null;

    if (index < _items.length) {
      // The first recipe she lands on introduces itself. Once per session,
      // so swiping through a dozen reels stays quiet.
      if (_items[index].tags.any((t) => t.toLowerCase().contains('recipe'))) {
        speak(NarrationKeys.pgFeedsRecipe);
      }
    }

    // Stop speech reading when swiped to another page
    if (_currentlyReadingId != null) {
      _speechTimer?.cancel();
      _currentlyReadingId = null;
      _readingProgress = 0.0;
    }

    if (index >= _items.length - _loadMoreThreshold) _loadMore();
    _syncVideos();
    setState(() {});
  }

  // ═══════════════════════════════════════════════════════════════════
  // REEL PLAYBACK
  // ═══════════════════════════════════════════════════════════════════

  /// Keeps a player for each reel within [_preloadRadius] of the current
  /// page and disposes the rest.
  void _syncVideos() {
    for (final id in _videos.keys.toList()) {
      final index = _items.indexWhere((c) => c.id == id);
      if (index == -1 || (index - _currentIndex).abs() > _preloadRadius) {
        _videos.remove(id)!.dispose();
      }
    }

    for (var i = _currentIndex - _preloadRadius;
        i <= _currentIndex + _preloadRadius;
        i++) {
      if (i < 0 || i >= _items.length) continue;
      final item = _items[i];
      final video = item.isReel ? item.reelVideo : null;
      if (video == null ||
          _videos.containsKey(item.id) ||
          _failedVideos.contains(item.id)) {
        continue;
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(video.fileUrl),
      );
      _videos[item.id] = controller;
      controller
        ..setLooping(true)
        ..setVolume(_muted ? 0 : 1);
      controller.initialize().then((_) {
        // Swiped far enough away that it was disposed while loading.
        if (!mounted || _videos[item.id] != controller) return;
        _syncPlayback();
        setState(() {});
      }).catchError((Object _) {
        if (!mounted || _videos[item.id] != controller) return;
        _videos.remove(item.id);
        controller.dispose();
        setState(() => _failedVideos.add(item.id));
      });
    }

    _syncPlayback();
  }

  /// Only the reel on screen plays, and only while the app and this route
  /// are in front. Reels she has scrolled past rewind for when she returns.
  void _syncPlayback() {
    final currentId =
        _currentIndex < _items.length ? _items[_currentIndex].id : null;
    _videos.forEach((id, controller) {
      final value = controller.value;
      if (!value.isInitialized) return;
      final isCurrent = id == currentId;
      final shouldPlay = isCurrent &&
          _appActive &&
          _routeVisible &&
          !_pausedByUser.contains(id);
      if (shouldPlay && !value.isPlaying) {
        controller.play();
      } else if (!shouldPlay && value.isPlaying) {
        controller.pause();
      }
      if (!isCurrent && value.position > Duration.zero) {
        controller.seekTo(Duration.zero);
      }
    });
  }

  void _disposeVideos() {
    for (final controller in _videos.values) {
      controller.dispose();
    }
    _videos.clear();
  }

  void _toggleReelPlayback(FeedContent item) {
    setState(() {
      if (!_pausedByUser.remove(item.id)) _pausedByUser.add(item.id);
    });
    _syncPlayback();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    for (final controller in _videos.values) {
      controller.setVolume(_muted ? 0 : 1);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════

  void _toggleReading(FeedContent item) {
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

  /// Flips the heart at once and settles on the server's count; a failed
  /// request puts it back.
  Future<void> _toggleLike(FeedContent item) async {
    if (_liking.contains(item.id)) return;
    final wasLiked = item.isLiked;
    final previousLikes = item.likes;
    setState(() {
      _liking.add(item.id);
      item.isLiked = !wasLiked;
      item.likes = (previousLikes + (wasLiked ? -1 : 1)).clamp(0, 1 << 31);
    });

    final res = wasLiked
        ? await ContentApi.unlike(item.id)
        : await ContentApi.like(item.id);
    if (!mounted) return;

    setState(() {
      _liking.remove(item.id);
      final result = res.item;
      if (res.success && result is Map) {
        item.isLiked = result['is_liked'] ?? item.isLiked;
        item.likes = result['like_count'] ?? item.likes;
      } else {
        item.isLiked = wasLiked;
        item.likes = previousLikes;
      }
    });
    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't update your like"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCommentsModal(BuildContext context, FeedContent item) {
    showCommentsSheet(
      context,
      item: item,
      onCountChanged: (_) {
        if (mounted) setState(() {});
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final feed = _items.isEmpty
        ? ColoredBox(
            color: _p.card,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF4E6A)),
                  )
                : _buildEmptyState(),
          )
        : RefreshIndicator(
            color: const Color(0xFFFF4E6A),
            onRefresh: _load,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _items.length + (_hasMore ? 1 : 0),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (index >= _items.length) return _buildLoadMorePage();
                final item = _items[index];
                return item.isReel
                    ? _buildVideoReelView(item)
                    : _buildTipCardView(item);
              },
            ),
          );

    if (!_standalone) {
      return Scaffold(backgroundColor: Colors.black, body: feed);
    }

    // Full-screen: a black band behind the status bar, and a way back.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeController.overlayFor(Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(child: feed),
              Positioned(
                top: 12,
                left: 12,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _loadFailed ? Icons.cloud_off_rounded : Icons.dynamic_feed_rounded,
              size: 48,
              color: _p.pick(const Color(0xFFFFB3C1), _p.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              _loadFailed ? "Couldn't load your feed" : 'Nothing here yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loadFailed
                  ? 'Check your connection and try again.'
                  : 'New tips and reels will show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _p.pick(const Color(0xFF5A5D64), _p.textSecondary),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF4E6A),
                side: const BorderSide(color: Color(0xFFFFD2DC)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The page past the last item while the next page is on its way.
  Widget _buildLoadMorePage() {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: _loadMoreFailed
            ? TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  'Tap to load more',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              )
            : const CircularProgressIndicator(color: Color(0xFFFF4E6A)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. NEWS / TIP CARD VIEW — attachments scroll across the top
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTipCardView(FeedContent item) {
    final isReadingThis = _currentlyReadingId == item.id;

    return Container(
      color: _p.card,
      child: Column(
        children: [
          // Top Visual Section (attachments)
          Expanded(
            flex: 55,
            child: item.attachments.isEmpty
                ? const _AttachmentPlaceholder()
                : _AttachmentCarousel(
                    attachments: item.attachments,
                    active: _currentIndex < _items.length &&
                        _items[_currentIndex].id == item.id &&
                        _appActive &&
                        _routeVisible,
                    muted: _muted,
                  ),
          ),

          // Bottom Content Section (White Background)
          Expanded(
            flex: 48,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              color: _p.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag Pill (e.g. PREGNANCY WEEK 1)
                  if (item.label.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _p.pick(const Color(0xFFFFF0F3), _p.accentSoft),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF5277),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Headline
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Body Text — takes the room left between the title and the
                  // actions, and scrolls within it.
                  Expanded(
                    child: _DescriptionScroller(
                      text: item.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: _p.pick(const Color(0xFF5A5D64), _p.textSecondary),
                        height: 1.4,
                      ),
                      onPastEnd: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      onPastStart: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),

                  // Audio reading progress indicator if active
                  if (isReadingThis) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _readingProgress,
                        backgroundColor: _p.pick(const Color(0xFFFFF0F3), _p.accentSoft),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4E6A)),
                        minHeight: 4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: _p.pick(const Color(0xFFF1F2F4), _p.divider),
                  ),
                  const SizedBox(height: 12),

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
                                : _p.pick(const Color(0xFFFFF0F3), _p.accentSoft),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _p.pick(const Color(0xFFFFD2DC), _p.accentBorder),
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
                                      : _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                                  size: 19,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.likes}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
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
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.comments}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Clears the bottom nav bar, which the shell extends the
                  // body under and reports as bottom padding.
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. VIDEO REEL VIEW — plays the content's first video attachment
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildVideoReelView(FeedContent item) {
    final controller = _videos[item.id];
    final unavailable =
        item.reelVideo == null || _failedVideos.contains(item.id);
    final captionOpen = _captionOpenId == item.id;

    return GestureDetector(
      onTap: controller == null ? null : () => _toggleReelPlayback(item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),

          if (controller != null) _ReelVideo(controller: controller),

          if (unavailable)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_off_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video unavailable',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

          // Buffering spinner, or the play icon while she has paused it
          if (controller != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (_pausedByUser.contains(item.id)) {
                  return Center(
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
                  );
                }
                if (!value.isInitialized || value.isBuffering) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

          // Scrim so the caption stays legible over bright footage
          if (captionOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 320,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top Right Audio / Sound Toggle Button
          Positioned(
            top: 16,
            right: 20,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // Bottom Left: Tag, Title, Subtitle Description
          if (captionOpen)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              left: 20,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tag pill (e.g. PREGNANCY WEEK 1 - REEL)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.label,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
            bottom: MediaQuery.paddingOf(context).bottom + 16,
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
                const SizedBox(height: 18),

                // Info Button — shows or hides the caption
                GestureDetector(
                  onTap: () => setState(
                    () => _captionOpenId = captionOpen ? null : item.id,
                  ),
                  child: Icon(
                    captionOpen ? Icons.info_rounded : Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          // Playback progress, resting on top of the bottom nav bar (the
          // shell extends its body under the bar and reports its height as
          // bottom padding).
          if (controller != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom,
              child: IgnorePointer(
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: false,
                  padding: EdgeInsets.zero,
                  colors: VideoProgressColors(
                    playedColor: const Color(0xFFFF4E6A),
                    bufferedColor: Colors.white.withValues(alpha: 0.3),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A reel's video filling the page: portrait footage is cropped to fill,
/// landscape footage is letterboxed so nothing important is cut off.
class _ReelVideo extends StatelessWidget {
  final VideoPlayerController controller;

  const _ReelVideo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized || value.size.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox.expand(
          child: FittedBox(
            fit: value.aspectRatio < 1 ? BoxFit.cover : BoxFit.contain,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: value.size.width,
              height: value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        );
      },
    );
  }
}

/// The top of a card with nothing attached.
class _AttachmentPlaceholder extends StatelessWidget {
  const _AttachmentPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1D45), Color(0xFF2A2B66)],
        ),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 56,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

/// A card's attachments, swiped through horizontally across its top half.
///
/// While [active] (the card is on screen), a video on the current slide
/// plays by itself; swiping to another slide stops it.
class _AttachmentCarousel extends StatefulWidget {
  final List<ContentAttachment> attachments;
  final bool active;
  final bool muted;

  const _AttachmentCarousel({
    required this.attachments,
    required this.active,
    required this.muted,
  });

  @override
  State<_AttachmentCarousel> createState() => _AttachmentCarouselState();
}

class _AttachmentCarouselState extends State<_AttachmentCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAround(_index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Warms the cache for the slides either side, so a swipe lands on an
  /// image that is already there.
  void _precacheAround(int index) {
    for (final i in [index - 1, index + 1]) {
      if (i < 0 || i >= widget.attachments.length) continue;
      final a = widget.attachments[i];
      if (a.isImage && a.fileUrl.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(a.fileUrl), context)
            .catchError((Object _) {});
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _precacheAround(index);
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.attachments;
    final paged = attachments.length > 1;
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF1B1D45),
            child: PageView.builder(
              controller: _controller,
              itemCount: attachments.length,
              // One slide at a time, even on a hard fling.
              physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => _AttachmentSlide(
                attachment: attachments[i],
                active: widget.active && i == _index,
                muted: widget.muted,
              ),
            ),
          ),
        ),

        // Which slide she is on, so it is clear there is more to swipe.
        if (paged)
          Positioned(
            top: 12,
            right: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_index + 1}/${attachments.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

        if (paged)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < attachments.length; i++)
                  GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? const Color(0xFFFF4E6A)
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AttachmentSlide extends StatelessWidget {
  final ContentAttachment attachment;
  final bool active;
  final bool muted;

  const _AttachmentSlide({
    required this.attachment,
    required this.active,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    if (attachment.isVideo) {
      return _InlineVideo(url: attachment.fileUrl, active: active, muted: muted);
    }

    if (attachment.isImage) {
      return CachedNetworkImage(
        imageUrl: attachment.fileUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, _) => const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
        errorWidget: (context, _, _) => const _SlideMessage(
          icon: Icons.broken_image_rounded,
          text: 'Image unavailable',
        ),
      );
    }

    return _SlideMessage(
      icon: Icons.insert_drive_file_rounded,
      text: attachment.title.isNotEmpty ? attachment.title : attachment.fileName,
    );
  }
}

class _SlideMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SlideMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A video inside a card's carousel. It loads and plays once it is [active]
/// (its card and slide are on screen), and pauses and rewinds when she
/// swipes away. A tap pauses or resumes it.
class _InlineVideo extends StatefulWidget {
  final String url;
  final bool active;
  final bool muted;

  const _InlineVideo({
    required this.url,
    required this.active,
    required this.muted,
  });

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _pausedByUser = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(_InlineVideo old) {
    super.didUpdateWidget(old);
    if (widget.muted != old.muted) {
      _controller?.setVolume(widget.muted ? 0 : 1);
    }
    if (widget.active == old.active) return;
    if (widget.active) {
      _pausedByUser = false;
      _controller == null ? _start() : _controller!.play();
    } else {
      final controller = _controller;
      if (controller != null && controller.value.isInitialized) {
        controller
          ..pause()
          ..seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_controller != null || _failed) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    setState(() => _controller = controller);
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(widget.muted ? 0 : 1);
      // She may have swiped on, or paused it, while it loaded.
      if (widget.active && !_pausedByUser) await controller.play();
    } catch (_) {
      if (!mounted) return;
      controller.dispose();
      setState(() {
        _controller = null;
        _failed = true;
      });
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) {
      _pausedByUser = false;
      _start();
      return;
    }
    if (!controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      _pausedByUser = true;
      controller.pause();
    } else {
      _pausedByUser = false;
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const _SlideMessage(
        icon: Icons.videocam_off_rounded,
        text: 'Video unavailable',
      );
    }

    final controller = _controller;
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          if (controller != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) => value.isInitialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          if (controller == null)
            const _PlayBadge()
          else
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (!value.isInitialized || value.isBuffering) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  );
                }
                return value.isPlaying ? const SizedBox.shrink() : const _PlayBadge();
              },
            ),
        ],
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}


/// A card's description in a fixed box that scrolls inside itself, fading at
/// whichever edge has more to read.
///
/// It sits inside the feed's vertical pager, whose swipes it would otherwise
/// swallow: pulling on past the end (or the top) turns the page instead.
class _DescriptionScroller extends StatefulWidget {
  const _DescriptionScroller({
    required this.text,
    required this.style,
    required this.onPastEnd,
    required this.onPastStart,
  });

  final String text;
  final TextStyle style;
  final VoidCallback onPastEnd;
  final VoidCallback onPastStart;

  @override
  State<_DescriptionScroller> createState() => _DescriptionScrollerState();
}

class _DescriptionScrollerState extends State<_DescriptionScroller> {
  /// How far she has to pull past an edge before the page turns.
  static const _turnThreshold = 36.0;

  final _controller = ScrollController();
  double _overscroll = 0;
  bool _turned = false;
  bool _fadeTop = false;
  bool _fadeBottom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final top = pos.pixels > 1;
    final bottom = pos.pixels < pos.maxScrollExtent - 1;
    if (top != _fadeTop || bottom != _fadeBottom) {
      setState(() {
        _fadeTop = top;
        _fadeBottom = bottom;
      });
    }
  }

  bool _onNotification(ScrollNotification n) {
    if (n is ScrollStartNotification) {
      _overscroll = 0;
      _turned = false;
    } else if (n is OverscrollNotification && n.dragDetails != null && !_turned) {
      _overscroll += n.overscroll;
      if (_overscroll > _turnThreshold) {
        _turned = true;
        widget.onPastEnd();
      } else if (_overscroll < -_turnThreshold) {
        _turned = true;
        widget.onPastStart();
      }
    } else if (n is ScrollUpdateNotification) {
      _updateFades();
    }
    // Keep it from also reaching the pager, which would see it as its own.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _updateFades();
          return true;
        },
        child: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _fadeTop ? Colors.transparent : Colors.black,
              Colors.black,
              Colors.black,
              _fadeBottom ? Colors.transparent : Colors.black,
            ],
            stops: const [0, 0.12, 0.88, 1],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _controller,
            // Clamping on every platform, so an edge reports overscroll
            // rather than bouncing.
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(widget.text, style: widget.style),
            ),
          ),
        ),
      ),
    );
  }
}
