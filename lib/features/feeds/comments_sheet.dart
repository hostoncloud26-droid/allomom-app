import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/api/content_api.dart';
import 'package:allomom/api/response.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/models/feed_content.dart';

/// Opens the comments for [item]. [onCountChanged] hears the new total after
/// she posts or deletes, so the feed's counter stays in step.
Future<void> showCommentsSheet(
  BuildContext context, {
  required FeedContent item,
  required ValueChanged<int> onCountChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommentsSheet(item: item, onCountChanged: onCountChanged),
  );
}

class _CommentsSheet extends StatefulWidget {
  final FeedContent item;
  final ValueChanged<int> onCountChanged;

  const _CommentsSheet({required this.item, required this.onCountChanged});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const _pageSize = 20;
  static const _accent = Color(0xFFFF4E6A);

  AppPalette get _p => context.palette;

  final _input = TextEditingController();
  final _scroll = ScrollController();

  List<ContentComment> _comments = [];
  int _page = 0;
  bool _loading = true;
  bool _loadFailed = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _posting = false;
  final Set<int> _deleting = {};

  int get _contentId => widget.item.id;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final res = await ContentApi.getComments(_contentId, size: _pageSize);
    if (!mounted) return;
    final items = res.success ? ContentComment.listFrom(res.items) : <ContentComment>[];
    setState(() {
      _loading = false;
      _loadFailed = !res.success;
      _page = 1;
      _comments = items;
      _hasMore = res.success && _hasNext(res.pagination, items.length);
    });
    final total = res.pagination?.total;
    if (res.success && total != null) _setCount(total);
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final res = await ContentApi.getComments(
      _contentId,
      page: _page + 1,
      size: _pageSize,
    );
    if (!mounted) return;
    // Comments posted since the first page shift later pages down by one.
    final seen = _comments.map((c) => c.id).toSet();
    final items = res.success ? ContentComment.listFrom(res.items) : <ContentComment>[];
    setState(() {
      _loadingMore = false;
      if (res.success) {
        _page += 1;
        _comments = [..._comments, ...items.where((c) => !seen.contains(c.id))];
      }
      _hasMore = res.success && _hasNext(res.pagination, items.length);
    });
  }

  bool _hasNext(APIPaginationResponse? pagination, int count) {
    if (pagination != null && pagination.pages > 0) {
      return pagination.page < pagination.pages;
    }
    return count == _pageSize;
  }

  void _setCount(int total) {
    widget.item.comments = total;
    widget.onCountChanged(total);
  }

  Future<void> _post() async {
    final text = _input.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    final res = await ContentApi.addComment(_contentId, text);
    if (!mounted) return;
    setState(() => _posting = false);
    if (!res.success || res.item is! Map) {
      _toast("Couldn't post your comment");
      return;
    }
    _input.clear();
    setState(() {
      _comments = [
        ContentComment.fromJson(Map<String, dynamic>.from(res.item)),
        ..._comments,
      ];
    });
    _setCount(res.itemCount);
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _delete(ContentComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This removes your comment for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _accent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting.add(comment.id));
    final res = await ContentApi.deleteComment(_contentId, comment.id);
    if (!mounted) return;
    setState(() {
      _deleting.remove(comment.id);
      if (res.success) _comments.removeWhere((c) => c.id == comment.id);
    });
    if (res.success) {
      _setCount(res.itemCount);
    } else {
      _toast("Couldn't delete your comment");
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static String _ago(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().toUtc().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final bottomSafe = media.padding.bottom;
    final screenHeight = media.size.height;
    final baseHeight = screenHeight * 0.65;
    final height = bottomInset > 0
        ? (baseHeight + bottomInset).clamp(baseHeight, screenHeight * 0.9)
        : baseHeight;

    return Container(
      height: height,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: bottomInset > 0 ? bottomInset + 16 : bottomSafe + 16,
      ),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _p.pick(Colors.grey.shade300, _p.divider),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comments (${widget.item.comments})',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Expanded(child: _buildList()),
          const SizedBox(height: 8),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_comments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _loadFailed ? Icons.cloud_off_rounded : Icons.chat_bubble_outline_rounded,
                size: 36,
                color: _p.pick(const Color(0xFFFFB3C1), _p.textMuted),
              ),
              const SizedBox(height: 10),
              Text(
                _loadFailed ? "Couldn't load comments" : 'Be the first to comment',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _p.pick(const Color(0xFF5A5D64), _p.textSecondary),
                ),
              ),
              if (_loadFailed)
                TextButton(
                  onPressed: _load,
                  style: TextButton.styleFrom(foregroundColor: _accent),
                  child: const Text('Try again'),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      itemCount: _comments.length + (_loadingMore ? 1 : 0),
      itemBuilder: (_, index) {
        if (index >= _comments.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
              ),
            ),
          );
        }
        return _buildComment(_comments[index]);
      },
    );
  }

  Widget _buildComment(ContentComment c) {
    final picture = c.authorPicture;
    final deleting = _deleting.contains(c.id);
    return Opacity(
      opacity: deleting ? 0.4 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _p.tint(_accent, const Color(0xFFFFE4E9)),
              foregroundImage:
                  picture != null && picture.isNotEmpty ? CachedNetworkImageProvider(picture) : null,
              child: Text(
                c.initial,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: _accent,
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
                      Flexible(
                        child: Text(
                          c.isMine ? 'You' : c.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ago(c.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _p.pick(Colors.grey, _p.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.comment,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _p.pick(const Color(0xFF4B5563), _p.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (c.isMine)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: _p.pick(Colors.grey, _p.textMuted),
                ),
                onPressed: deleting ? null : () => _delete(c),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            enabled: !_posting,
            maxLength: 1000,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _post(),
            style: TextStyle(color: _p.textPrimary),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Add a helpful comment...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: _p.pick(Colors.grey, _p.textMuted),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: _p.pick(Colors.grey.shade300, _p.border),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _posting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.send_rounded, color: _accent),
                onPressed: _post,
              ),
      ],
    );
  }
}
