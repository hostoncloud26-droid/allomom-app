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
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 170,
                      width: double.infinity,
                      color: _p.tint(primaryColor, accentLight),
                      child: banner == null || banner.isEmpty
                          ? null
                          : CachedNetworkImage(
                              imageUrl: banner,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const SizedBox.shrink(),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        backgroundColor: _p.card.withValues(alpha: 0.9),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: _p.textPrimary),
                          onPressed: () => Navigator.pop(context, _changed),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 20,
                    bottom: -40,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _p.card,
                      ),
                      child: CommunityAvatar(community: c, size: 80),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 52),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (c.isJoined) const CommunityJoinedBadge(),
                        Text(
                          '${c.memberCount} '
                          '${c.memberCount == 1 ? 'member' : 'members'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _p.textSecondary,
                          ),
                        ),
                        if (place.isNotEmpty)
                          Text(
                            place,
                            style: TextStyle(
                              fontSize: 13,
                              color: _p.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (c.description != null && c.description!.isNotEmpty) ...[
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (c.isJoined)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _leave,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Leave community',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: dangerRed,
                            side: const BorderSide(color: dangerRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      )
                    else
                      CommunityJoinButton(
                        joined: false,
                        busy: _busy,
                        onJoin: _join,
                        expand: true,
                      ),
                    const SizedBox(height: 28),
                    _buildPosts(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
