import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:allomom/api/community_api.dart';
import 'package:allomom/api/content_api.dart';
import 'package:allomom/api/response.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/feeds/content_list_card.dart';
import 'package:allomom/features/feeds/feeds_page.dart';
import 'package:allomom/features/people/community/community_widgets.dart';
import 'package:allomom/models/community.dart';
import 'package:allomom/models/feed_content.dart';

/// One community — banner, logo, about, Join / Leave, and its posts.
///
/// Opens straight away with the [community] it was given, then refreshes it
/// from `/communities/{id}`. Pops `true` if she joined or left.
class CommunityDetailPage extends StatefulWidget {
  const CommunityDetailPage({super.key, required this.community});

  final Community community;

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  AppPalette get _p => context.palette;

  late Community _community = widget.community;
  bool _busy = false;
  bool _changed = false;

  // The community's posts — only served to members.
  static const _postsPageSize = 10;
  final _scroll = ScrollController();
  List<FeedContent> _posts = [];
  int _postsPage = 0;
  bool _postsLoading = false;
  bool _postsFailed = false;
  bool _postsLoadingMore = false;
  bool _postsHasMore = false;
  int _postsRequestId = 0;

  @override
  void initState() {
    super.initState();
    // Opening a community is the moment for the disclaimer: what she is
    // about to read is other mothers talking, not medical advice.
    speak(NarrationKeys.pgCommunityDisclaimer);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _loadMorePosts();
      }
    });
    _refresh();
    _loadPosts();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _postsHaveNext(APIPaginationResponse? pagination, int count) {
    if (pagination != null && pagination.pages > 0) {
      return pagination.page < pagination.pages;
    }
    return count == _postsPageSize;
  }

  Future<void> _loadPosts() async {
    final requestId = ++_postsRequestId;
    if (!_community.isJoined) {
      setState(() {
        _posts = [];
        _postsHasMore = false;
        _postsLoading = false;
        _postsFailed = false;
      });
      return;
    }
    setState(() {
      _postsLoading = true;
      _postsFailed = false;
    });
    final res = await ContentApi.getMyContent(
      entityId: _community.id,
      size: _postsPageSize,
    );
    if (!mounted || requestId != _postsRequestId) return;
    final items = res.success ? FeedContent.listFrom(res.items) : <FeedContent>[];
    setState(() {
      _postsLoading = false;
      _postsFailed = !res.success;
      _postsPage = 1;
      _posts = items;
      _postsHasMore = res.success && _postsHaveNext(res.pagination, items.length);
    });
  }

  Future<void> _loadMorePosts() async {
    if (_postsLoading || _postsLoadingMore || !_postsHasMore) return;
    final requestId = _postsRequestId;
    setState(() => _postsLoadingMore = true);
    final res = await ContentApi.getMyContent(
      entityId: _community.id,
      page: _postsPage + 1,
      size: _postsPageSize,
    );
    if (!mounted || requestId != _postsRequestId) return;
    final seen = _posts.map((c) => c.id).toSet();
    final items = res.success ? FeedContent.listFrom(res.items) : <FeedContent>[];
    setState(() {
      _postsLoadingMore = false;
      if (res.success) {
        _postsPage += 1;
        _posts = [..._posts, ...items.where((c) => !seen.contains(c.id))];
      }
      _postsHasMore = res.success && _postsHaveNext(res.pagination, items.length);
    });
  }

  /// Opens the tapped post in the feed view — reel or card — and lets her
  /// swipe on through the rest of the community's posts.
  Future<void> _openPost(int index) async {
    await FeedsPage.open(
      context,
      items: _posts,
      index: index,
      entityId: _community.id,
      page: _postsPage,
      hasMore: _postsHasMore,
    );
    // Likes and comment counts were changed on the same objects.
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    final res = await CommunityApi.getCommunity(_community.id);
    if (!mounted || !res.success || res.item is! Map) return;
    final wasJoined = _community.isJoined;
    setState(() {
      _community = Community.fromJson(Map<String, dynamic>.from(res.item));
    });
    if (wasJoined != _community.isJoined) _loadPosts();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refresh(), _loadPosts()]);
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    final ok = await joinCommunity(context, _community);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _changed = true;
        _community = _community.withMembership(joined: true);
      }
    });
    if (ok) _loadPosts();
  }

  Future<void> _leave() async {
    setState(() => _busy = true);
    final ok = await leaveCommunityWithConfirm(context, _community);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _changed = true;
        _community = _community.withMembership(joined: false);
      }
    });
    if (ok) _loadPosts();
  }

  void _shareCommunity() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${_community.name}" with friends!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _community;
    final place = [c.city, c.state].whereType<String>().join(', ');
    final banner = c.bannerUrl;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: _p.scaffoldSoft,
        body: RefreshIndicator(
          onRefresh: _refreshAll,
          edgeOffset: MediaQuery.paddingOf(context).top + 10,
          child: CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Collapsing Hero Banner with Parallax Zoom ───────────────
              SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 230,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                leadingWidth: 58,
                automaticallyImplyLeading: false,
                leading: Center(
                  child: _FrostedIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context, _changed),
                  ),
                ),
                actions: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _FrostedIconButton(
                        icon: Icons.share_outlined,
                        tooltip: 'Share community',
                        onPressed: _shareCommunity,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: _CommunityFlexibleHeader(
                  community: c,
                  banner: banner,
                  actionWidget:
                      c.isJoined ? _buildJoinedActions() : _buildJoinPill(),
                ),
              ),

              // ── Community Details & Feed Content ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Community Name
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                          color: _p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Info Chips Row (Members, Location, Safe Space)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildStatChip(
                            icon: Icons.groups_rounded,
                            label:
                                '${c.memberCount} ${c.memberCount == 1 ? 'member' : 'members'}',
                          ),
                          if (place.isNotEmpty)
                            _buildStatChip(
                              icon: Icons.location_on_rounded,
                              label: place,
                            ),
                          _buildStatChip(
                            icon: Icons.verified_user_rounded,
                            label: 'Safe Space for Moms',
                            color: const Color(0xFF15803D),
                            backgroundColor: _p.tint(
                              const Color(0xFF22C55E),
                              const Color(0xFFDCFCE7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // About Section in modern card container
                      if (c.description != null &&
                          c.description!.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _p.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _p.border.withValues(alpha: 0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                c.description!.trim(),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color: _p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Community Discussions & Posts
                      _buildPosts(),
                      SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 40,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    Color? color,
    Color? backgroundColor,
  }) {
    final ink = color ?? _p.textSecondary;
    final bg = backgroundColor ?? _p.card;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _p.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ink),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinPill() {
    return GestureDetector(
      onTap: _busy ? null : _join,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: _busy
              ? null
              : const LinearGradient(
                  colors: [primaryColor, Color(0xFFFF6B8B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _busy ? primaryColor.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _busy
              ? []
              : [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              _busy ? 'Joining...' : 'Join Community',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinedActions() {
    final greenText = _p.isDark
        ? Color.lerp(const Color(0xFF4ADE80), Colors.white, 0.3)!
        : const Color(0xFF15803D);
    final greenBg = _p.tint(
      const Color(0xFF22C55E),
      const Color(0xFFDCFCE7),
    );

    return Container(
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _p.border.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✓ Joined section
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: greenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Joined',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: greenText,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 28,
            color: _p.border.withValues(alpha: 0.5),
          ),

          // Leave icon
          Tooltip(
            message: 'Leave community',
            child: InkWell(
              onTap: _busy ? null : _leave,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: _busy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: dangerRed.withValues(alpha: 0.7),
                        ),
                      )
                    : Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: dangerRed.withValues(alpha: 0.8),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosts() {
    final heading = Text(
      'Posts',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: _p.textPrimary,
      ),
    );

    Widget message(IconData icon, String text, {VoidCallback? retry}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 34, color: _p.textMuted),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _p.textSecondary),
              ),
              if (retry != null)
                TextButton(onPressed: retry, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final Widget body;
    if (!_community.isJoined) {
      body = message(Icons.lock_outline_rounded, "Join to see this community's posts");
    } else if (_postsLoading) {
      body = const CommunityPostSkeletonList();
    } else if (_posts.isEmpty) {
      body = _postsFailed
          ? message(Icons.cloud_off_rounded, "Couldn't load posts", retry: _loadPosts)
          : message(Icons.dynamic_feed_rounded, 'No posts yet');
    } else {
      body = Column(
        children: [
          for (var i = 0; i < _posts.length; i++) ...[
            ContentListCard(item: _posts[i], onTap: () => _openPost(i)),
            const SizedBox(height: 12),
          ],
          if (_postsLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [heading, const SizedBox(height: 12), body],
    );
  }
}

// ── Frosted Glass & Aurora Header Components ────────────────────────────────

class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 18, color: p.textPrimary),
            onPressed: onPressed,
            tooltip: tooltip,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

class _CommunityFlexibleHeader extends StatelessWidget {
  const _CommunityFlexibleHeader({
    required this.community,
    required this.banner,
    required this.actionWidget,
  });

  final Community community;
  final String? banner;
  final Widget actionWidget;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final topPadding = MediaQuery.paddingOf(context).top;
    final minHeight = kToolbarHeight + topPadding;
    const maxHeight = 230.0;
    const shelfHeight = 44.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final currentHeight = constraints.biggest.height;
        // shrinkFraction goes from 0.0 (fully expanded) to 1.0 (fully collapsed)
        final double shrinkFraction =
            ((maxHeight - currentHeight) / (maxHeight - minHeight))
                .clamp(0.0, 1.0);

        // Opacity of the collapsed title & frosted glass bar
        final double collapsedBarOpacity =
            ((shrinkFraction - 0.55) / 0.45).clamp(0.0, 1.0);

        // Opacity of the large avatar and action buttons
        final double avatarOpacity =
            ((currentHeight - 140) / 70).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image or Aurora Mesh Gradient (banner area)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: shelfHeight - 1,
              child: banner != null && banner!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: banner!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          _AuroraMeshBackground(community: community),
                    )
                  : _AuroraMeshBackground(community: community),
            ),

            // 2. Top ambient vignette for back & share button contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Lower shelf background matching page scaffold
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: shelfHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: p.scaffoldSoft,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
              ),
            ),

            // 4. Overlapping Avatar (half on banner, half on shelf)
            if (avatarOpacity > 0.01)
              Positioned(
                left: 20,
                bottom: 2,
                child: IgnorePointer(
                  ignoring: avatarOpacity < 0.5,
                  child: Opacity(
                    opacity: avatarOpacity,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.card,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CommunityAvatar(community: community, size: 82),
                    ),
                  ),
                ),
              ),

            // 5. Action Buttons (Join / Joined + Leave) on the shelf
            if (avatarOpacity > 0.01)
              Positioned(
                right: 20,
                bottom: 6,
                child: IgnorePointer(
                  ignoring: avatarOpacity < 0.5,
                  child: Opacity(
                    opacity: avatarOpacity,
                    child: actionWidget,
                  ),
                ),
              ),

            // 4. Frosted Glass Navigation Bar (collapses smoothly at the top)
            if (collapsedBarOpacity > 0.01)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: minHeight,
                child: Opacity(
                  opacity: collapsedBarOpacity,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: EdgeInsets.only(
                          top: topPadding,
                          left: 64, // clear back button
                          right: 64, // clear share button
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? p.card : Colors.white)
                              .withValues(alpha: isDark ? 0.8 : 0.85),
                          border: Border(
                            bottom: BorderSide(
                              color: p.border.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CommunityAvatar(community: community, size: 28),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                community.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AuroraMeshBackground extends StatelessWidget {
  const _AuroraMeshBackground({required this.community});

  final Community community;

  static const _palette = <Color>[
    primaryColor,
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;

    final accent =
        _palette[community.name.hashCode.abs() % _palette.length];

    final baseGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF261928),
              Color(0xFF1B1B34),
              Color(0xFF13202E),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF1F4),
              const Color(0xFFF5EEFF),
              const Color(0xFFEFF6FF),
              p.scaffoldSoft,
            ],
            stops: const [0.0, 0.35, 0.7, 1.0],
          );

    return Container(
      decoration: BoxDecoration(gradient: baseGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Aurora Orb 1 (Top-Left: community accent)
          Positioned(
            top: -40,
            left: -30,
            width: 220,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: isDark ? 0.4 : 0.32),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Aurora Orb 2 (Right Center: warm primary rose glow)
          Positioned(
            top: 20,
            right: -50,
            width: 240,
            height: 240,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Aurora Orb 3 (Bottom Center: lilac glow)
          Positioned(
            bottom: -30,
            left: 60,
            width: 180,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF818CF8)
                        .withValues(alpha: isDark ? 0.3 : 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Floating Sparkles & Soft Warmth
          Positioned(
            top: 60,
            right: 80,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : primaryColor.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            bottom: 45,
            left: 40,
            child: Icon(
              Icons.star_rounded,
              size: 16,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFF818CF8).withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 95,
            left: 120,
            child: Icon(
              Icons.favorite_rounded,
              size: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : primaryColor.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

