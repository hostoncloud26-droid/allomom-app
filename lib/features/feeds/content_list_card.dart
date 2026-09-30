import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/models/feed_content.dart';

/// A feed item as a row in a list — thumbnail, label, title, and counts.
/// Reels get a play badge; tapping opens it in the full feed view.
class ContentListCard extends StatelessWidget {
  const ContentListCard({super.key, required this.item, required this.onTap});

  final FeedContent item;
  final VoidCallback onTap;

  static const _accent = Color(0xFFFF4E6A);

  /// The first image to show as the thumbnail, if there is one.
  ContentAttachment? get _thumbnail {
    for (final a in item.attachments) {
      if (a.isImage && a.fileUrl.isNotEmpty) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final thumb = _thumbnail;
    final hasVideo = item.attachments.any((a) => a.isVideo);

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: item.isReel ? 120 : 92,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumb != null)
                        CachedNetworkImage(
                          imageUrl: thumb.fileUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const ColoredBox(color: Color(0xFF2A2B66)),
                          errorWidget: (_, _, _) => const _ThumbFallback(icon: Icons.broken_image_rounded),
                        )
                      else
                        _ThumbFallback(
                          icon: hasVideo ? Icons.movie_rounded : Icons.auto_awesome_rounded,
                        ),
                      if (item.isReel || (thumb == null && hasVideo))
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      if (item.attachments.length > 1)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.collections_rounded, color: Colors.white, size: 11),
                                const SizedBox(width: 3),
                                Text(
                                  '${item.attachments.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.label.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.pick(const Color(0xFFFFF0F3), p.accentSoft),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF5277),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.35,
                          color: p.pick(const Color(0xFF5A5D64), p.textSecondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          item.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 15,
                          color: item.isLiked ? _accent : p.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        _count(context, item.likes),
                        const SizedBox(width: 14),
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: p.textSecondary),
                        const SizedBox(width: 4),
                        _count(context, item.comments),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _count(BuildContext context, int n) => Text(
        '$n',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: context.palette.textSecondary,
        ),
      );
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1D45), Color(0xFF2A2B66)],
        ),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 30),
    );
  }
}
