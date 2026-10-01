import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:allomom/api/community_api.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/models/community.dart';

/// Monogram colours (text, light wash), picked by the community's name so a
/// community keeps the same colour everywhere it appears.
const _monogramPalette = <(Color, Color)>[
  (primaryColor, Color(0xFFFCE7F0)),
  (Color(0xFF1D4ED8), Color(0xFFEFF6FF)),
  (Color(0xFF15803D), Color(0xFFDCFCE7)),
  (Color(0xFFB45309), Color(0xFFFEF3C7)),
  (Color(0xFF7E22CE), Color(0xFFF3E8FF)),
];

/// The community's logo, or its initials on a tinted circle.
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({super.key, required this.community, this.size = 48});

  final Community community;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (ink, wash) =
        _monogramPalette[community.name.hashCode.abs() %
            _monogramPalette.length];
    final text = p.isDark ? Color.lerp(ink, Colors.white, 0.35)! : ink;

    final monogram = Center(
      child: Text(
        community.monogram,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );

    final logo = community.logoUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.tint(ink, wash),
      ),
      child: logo == null || logo.isEmpty
          ? monogram
          : CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              placeholder: (_, _) => monogram,
              errorWidget: (_, _, _) => monogram,
            ),
    );
  }
}

/// The green "✓ Joined" pill.
class CommunityJoinedBadge extends StatelessWidget {
  const CommunityJoinedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const green = Color(0xFF15803D);
    final ink = p.isDark ? Color.lerp(green, Colors.white, 0.35)! : green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: p.tint(const Color(0xFF22C55E), const Color(0xFFDCFCE7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: ink),
          const SizedBox(width: 4),
          Text(
            'Joined',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small pill button: "Join" when she isn't a member, a disabled "Joined"
/// once she is.
class CommunityJoinButton extends StatelessWidget {
  const CommunityJoinButton({
    super.key,
    required this.joined,
    required this.busy,
    required this.onJoin,
    this.expand = false,
  });

  final bool joined;
  final bool busy;
  final VoidCallback onJoin;

  /// Fill the available width (featured cards) instead of hugging the label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: joined || busy ? null : onJoin,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primaryColor.withValues(alpha: 0.12),
        disabledForegroundColor: primaryColor,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: expand ? 0 : 18,
        ),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              joined ? 'Joined' : 'Join',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// Joins [community]; true when the server accepted it.
Future<bool> joinCommunity(BuildContext context, Community community) async {
  final res = await CommunityApi.join(community.id);
  if (context.mounted) {
    _toast(context, res.success ? 'Joined ${community.name}' : res.detail);
  }
  return res.success;
}

/// Asks before leaving [community]; true when she confirmed and it went
/// through.
Future<bool> leaveCommunityWithConfirm(
  BuildContext context,
  Community community,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Leave ${community.name}?',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: const Text(
        "You'll stop seeing it under My Communities. You can join again anytime.",
        style: TextStyle(fontSize: 13.5, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: dangerRed),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final res = await CommunityApi.leave(community.id);
  if (context.mounted) {
    _toast(context, res.success ? 'Left ${community.name}' : res.detail);
  }
  return res.success;
}

// ── Skeleton & Shimmer Loaders ──────────────────────────────────────────────

/// Applies a smooth diagonal shimmering gradient over its opaque children.
class CommunityShimmer extends StatefulWidget {
  const CommunityShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<CommunityShimmer> createState() => _CommunityShimmerState();
}

class _CommunityShimmerState extends State<CommunityShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF282C35) : const Color(0xFFE5E9F0));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF3E4554) : const Color(0xFFF7F9FC));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [base, highlight, base],
              stops: const [0.15, 0.5, 0.85],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.4 - 1.2),
      0.0,
      0.0,
    );
  }
}

/// A placeholder shape (rectangle, rounded rect, or circle) intended to sit
/// inside a [CommunityShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? const BorderRadius.all(Radius.circular(8))),
      ),
    );
  }
}

/// Skeleton for a single featured community card in the horizontal carousel.
class FeaturedCommunityCardSkeleton extends StatelessWidget {
  const FeaturedCommunityCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const CommunityShimmer(
        child: Column(
          children: [
            ShimmerBox(width: 54, height: 54, shape: BoxShape.circle),
            SizedBox(height: 12),
            ShimmerBox(width: 86, height: 14),
            SizedBox(height: 6),
            ShimmerBox(width: 54, height: 12),
            Spacer(),
            ShimmerBox(
              width: double.infinity,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal carousel of featured community skeleton cards.
class FeaturedCommunitySkeletonList extends StatelessWidget {
  const FeaturedCommunitySkeletonList({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (_, _) => SizedBox(
              width: cardWidth,
              child: const FeaturedCommunityCardSkeleton(),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for a community in the "My Communities" list.
class CommunityListItemSkeleton extends StatelessWidget {
  const CommunityListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const CommunityShimmer(
        child: Row(
          children: [
            ShimmerBox(width: 48, height: 48, shape: BoxShape.circle),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(width: 120, height: 15),
                  SizedBox(height: 8),
                  ShimmerBox(
                    width: 62,
                    height: 16,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            ShimmerBox(width: 40, height: 40, shape: BoxShape.circle),
          ],
        ),
      ),
    );
  }
}

/// Vertical column of skeleton cards for the My Communities section.
class MyCommunitiesSkeletonList extends StatelessWidget {
  const MyCommunitiesSkeletonList({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          const CommunityListItemSkeleton(),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Skeleton for an item on the All Communities exploration page.
class AllCommunitiesCardSkeleton extends StatelessWidget {
  const AllCommunitiesCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const CommunityShimmer(
        child: Row(
          children: [
            ShimmerBox(width: 56, height: 56, shape: BoxShape.circle),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(width: 130, height: 16),
                  SizedBox(height: 8),
                  ShimmerBox(width: 70, height: 13),
                ],
              ),
            ),
            SizedBox(width: 12),
            ShimmerBox(
              width: 68,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full skeleton list for the All Communities page.
class AllCommunitiesSkeletonList extends StatelessWidget {
  const AllCommunitiesSkeletonList({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => const AllCommunitiesCardSkeleton(),
    );
  }
}

/// Skeleton for a community post card (matching ContentListCard).
class CommunityPostCardSkeleton extends StatelessWidget {
  const CommunityPostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const CommunityShimmer(
        child: Row(
          children: [
            ShimmerBox(
              width: 92,
              height: 92,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(
                    width: 60,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 15),
                  SizedBox(height: 6),
                  ShimmerBox(width: 110, height: 13),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerBox(width: 36, height: 12),
                      SizedBox(width: 16),
                      ShimmerBox(width: 36, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List of skeleton cards for loading community posts.
class CommunityPostSkeletonList extends StatelessWidget {
  const CommunityPostSkeletonList({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          const CommunityPostCardSkeleton(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

