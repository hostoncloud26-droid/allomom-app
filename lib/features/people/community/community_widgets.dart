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
          : Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => monogram,
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
