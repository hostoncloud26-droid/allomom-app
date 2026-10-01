import 'dart:async';

import 'package:flutter/material.dart';

import 'package:allomom/api/community_api.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/people/community/community_detail_page.dart';
import 'package:allomom/features/people/community/community_widgets.dart';
import 'package:allomom/models/community.dart';

/// Every community, searchable by name, with a Join button on each.
///
/// Pops `true` if she joined or left anything, so the caller can refresh.
class AllCommunitiesPage extends StatefulWidget {
  const AllCommunitiesPage({super.key});

  @override
  State<AllCommunitiesPage> createState() => _AllCommunitiesPageState();
}

class _AllCommunitiesPageState extends State<AllCommunitiesPage> {
  static const _pageSize = 20;

  AppPalette get _p => context.palette;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<Community> _communities = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final Set<String> _joining = {};
  bool _changed = false;

  /// Bumped on every fresh search so a slow earlier response can't overwrite
  /// a newer one.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) _loadMore();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    final res = await CommunityApi.search(
      query: _searchController.text,
      page: 1,
      size: _pageSize,
    );
    if (!mounted || requestId != _requestId) return;
    final items = res.success ? Community.listFrom(res.items) : <Community>[];
    setState(() {
      _loading = false;
      _page = 1;
      _communities = items;
      _hasMore = items.length == _pageSize;
    });
    if (!res.success) _toast('Failed to load communities');
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() => _loadingMore = true);
    final res = await CommunityApi.search(
      query: _searchController.text,
      page: _page + 1,
      size: _pageSize,
    );
    if (!mounted || requestId != _requestId) return;
    final items = res.success ? Community.listFrom(res.items) : <Community>[];
    setState(() {
      _loadingMore = false;
      if (res.success) {
        _page += 1;
        _communities = [..._communities, ...items];
      }
      _hasMore = res.success && items.length == _pageSize;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _join(Community community) async {
    setState(() => _joining.add(community.id));
    final ok = await joinCommunity(context, community);
    if (!mounted) return;
    setState(() {
      _joining.remove(community.id);
      if (ok) {
        _changed = true;
        _replace(community.id, joined: true);
      }
    });
  }

  void _replace(String id, {required bool joined}) {
    _communities = [
      for (final c in _communities)
        c.id == id ? c.withMembership(joined: joined) : c,
    ];
  }

  Future<void> _open(Community community) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailPage(community: community),
      ),
    );
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: _p.card,
        appBar: AppBar(
          backgroundColor: _p.card,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _p.textPrimary),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Text(
            'All Communities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _p.textPrimary,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _searchField(),
            ),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: _p.textSecondary),
        hintText: 'Search Community By Name...',
        hintStyle: TextStyle(fontSize: 14, color: _p.textMuted),
        filled: true,
        fillColor: _p.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  Widget _list() {
    if (_loading && _communities.isEmpty) {
      return const AllCommunitiesSkeletonList();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _communities.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_empty()],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: _communities.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => i == _communities.length
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _card(_communities[i]),
            ),
    );
  }

  Widget _empty() {
    final searching = _searchController.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 56, color: _p.textMuted),
          const SizedBox(height: 12),
          Text(
            searching
                ? 'No communities match your search'
                : 'No communities yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _p.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _card(Community community) {
    return Material(
      color: _p.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(community),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _p.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _p.border),
                ),
                child: CommunityAvatar(community: community, size: 56),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _p.textPrimary,
                      ),
                    ),
                    if (community.isJoined) ...[
                      const SizedBox(height: 6),
                      const CommunityJoinedBadge(),
                    ] else if (community.memberCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${community.memberCount} '
                        '${community.memberCount == 1 ? 'member' : 'members'}',
                        style: TextStyle(fontSize: 12, color: _p.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (community.isJoined)
                Icon(Icons.chevron_right, color: _p.textSecondary)
              else
                CommunityJoinButton(
                  joined: false,
                  busy: _joining.contains(community.id),
                  onJoin: () => _join(community),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
